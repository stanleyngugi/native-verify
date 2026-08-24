# AGENT HANDOFF — Infrastructure Knowledge Base

> **Audience:** AI agents (or humans) continuing work on native-verify,
> especially training runs on rented GPU pods. Read this before doing
> anything. It encodes ~20 hours of paid-for mistakes so you don't repeat
> them.
>
> Last updated: 2026-08-24, after the first successful GRPO run.
> Repo: https://github.com/stanleyngugi/native-verify (all of this is pushed)

---

## 0. Project state snapshot

| Component | Status | Location |
|---|---|---|
| Hardened verifier harness (sanitizer/template/runner) | DONE, tested | `src/native_verify/` |
| Procedural task families (5) + reference artifacts | DONE | `src/native_verify/tasks.py` |
| verifiers env (v0 rubric AND v1 Taskset) | DONE | `environments/native_verify_seq/native_verify_seq.py` |
| Batch eval CLI (OpenAI-compatible endpoints) | DONE | `scripts/batch_eval.py` |
| Baseline: Qwen2.5-1.5B-Instruct | **2.5%** accept rate (1/40), temp 0.9 | measured, reproducible |
| prime-rl patches (single-GPU colocate, optional ring_attn) | DONE | `patches/prime-rl/*.py` |
| GRPO smoke run | **COMPLETE**: 24 steps, 3072 episodes, checkpoint step_24 | results in `docs/RUN_RESULTS.md` |
| Phase 4 (self-written checkers) | NOT STARTED | design sketch in ROADMAP |

**The one-line state:** the full loop works end to end — model generates Lean
artifacts, our env verifies via `native_decide`, GRPO trains on it. What has
never been done: a LONG run showing a learning curve. Everything needed to do
one is documented below and takes ~3h pod time per attempt.

---

## 1. Topology & hardware reality

Three pods used so far; specs and quirks:

```text
Pod 1 (DEAD): A40 46GB, 96 CPU, host RAM advertised 503G
  - died at first training launch (credits)
Pod 2 (DEAD): RTX 2000 Ada 16GB, 48 CPU
  - CGROUP MEMORY LIMIT: 31GB despite 251GB advertised -> OOM-killed builds
  - network FS /workspace made torch imports take MINUTES
Pod 3 (TERMINATED): RTX 2000 Ada 16GB, 48 CPU, same 31GB cgroup
  - FIRST SUCCESSFUL TRAINING RUN here
```

**Always check before anything else:**

```bash
nvidia-smi --list-gpus | wc -l          # >=2 means NO colocate patches needed
cat /sys/fs/cgroup/memory.max           # real RAM ceiling (v2); v1: memory/
                                        #   memory.limit_in_bytes
df -h / /workspace                      # overlay=local(fast); mfs=network(slow)
ls /usr/local/cuda/bin/nvcc             # compiler present?
```

Hardware class conclusions:
- >=2 GPUs: use stock prime-rl path, skip section 4 patches entirely.
- 1 GPU 16GB: colocate works (proven end-to-end). Budget: inference util
  0.45 + max_model_len 2048 + max_num_seqs 64 + eager; trainer LoRA.
- flash-attn build on 31GB cgroup: MAX_JOBS=2 mandatory, ~2-3h wall.

## 2. Version & dependency pins

```text
Lean:            4.23.0 pinned tarball (GitHub release asset is .zst not .zstd)
verifiers:       0.3.0 works; prime-rl uses its OWN submodule (harnesses branch)
prime-rl:        main @ 2026-08-24 (v1 taskset/harness API REQUIRED by launcher;
                 legacy load_environment() envs DO NOT WORK with `rl` entrypoint)
flashinfer:      >= 0.6.17 (0.6.16.post3 crashes py3.11 engine boot)
flash-attn:      2.8.3.post1 source build (torch 2.11.0+cu128, python 3.12 venv)
model:           Qwen/Qwen2.5-1.5B-Instruct (cached in /root/.cache/huggingface)
openai client:   3.x rejects Groq's service_tier enum -> use local vLLM
```

## 3. Component wiring (what talks to what)

```text
uv run rl @ config.toml spawns:
  1. INFERENCE   vLLM server, port 8000, /update_weights for policy sync
                 optional vllm-router frontend (we DISABLE: binary missing)
  2. ENV SERVER  our Taskset served over ZMQ/tcp; NATIVE_VERIFY_LEAN must be
                 in its env (TOML [env_vars]) or every verify fails
  3. ORCHESTRATOR samples tasks, drives episodes, computes rewards,
                 publishes batches to trainer via zmq :5555
  4. TRAINER     torchrun -> FSDP -> GRPO update -> weight broadcast
```

Critical ordering constraint discovered: trainer grabs CUDA memory during
boot while vLLM profiles => KV cache goes negative. Fix: rl.py patch delays
trainer spawn 300s after inference (`grep -n 'waiting 300s'` in patched file).

## 4. Patch registry (apply after every fresh clone)

Backed up as FULL FILES under `patches/prime-rl/`. Copy over src after clone:

```bash
cp patches/prime-rl/rl.py    <prime-rl>/src/prime_rl/entrypoints/rl.py
cp patches/prime-rl/cp.py    <prime-rl>/src/prime_rl/utils/cp.py
cp patches/prime-rl/train.py <prime-rl>/src/prime_rl/trainer/rl/train.py
```

What each does:
1. **rl.py**: single-GPU colocate mapping {0:gpu0, 1:gpu0} + 300s trainer
   delay. Search "colocated mode".
2. **cp.py**: `from ring_flash_attn import ...` wrapped try/except ImportError
   -> no-op lambda (single GPU never reaches ring attention code).
3. **train.py**: same treatment for `substitute_hf_flash_attn`.

Verify after copying:
```bash
grep -c colocated <...>/rl.py                       # expect >=1
grep -c "except ImportError" <...>/utils/cp.py      # expect 1
grep -c "substitute_hf_flash_attn = None" <...>/train.py  # expect 1
```

If upstream rebase conflicts: re-apply manually, keep semantics (see section
8 for why each exists).

## 5. Config: configs/grpo_smoke_16gb.toml

The committed file is battle-tested. Non-obvious fields:

```toml
[inference]
router = "None"                    # vllm-router binary absent -> crash without
[inference.vllm]
gpu_memory_utilization = 0.45      # 0.35 worked standalone-only; colocated
                                   # needs headroom vs trainer CUDA context
max_model_len = 2048               # default 32k explodes profiling peak
enforce_eager = true               # CUDA graphs cost ~1GB profiled
max_num_seqs = 64                  # DEFAULT 1024 -> multi-GB profiling peak;
                                   # passes through model_extra into vLLM args
[env_vars]
NATIVE_VERIFY_LEAN = "/workspace/lean-4.23.0-linux/bin/lean"
HF_HUB_OFFLINE = "1"               # ONLY after first successful download
[orchestrator.renderer]
name = "default"                   # 'auto' hard-fails: Qwen2.5 unmapped
```

KV-cache failure signature (means memory budget too small):
```text
ValueError: No available memory for the cache blocks
Available KV cache memory: -X GiB        <- negative number = how much over
```
Levers in order: max_num_seqs down -> max_model_len down -> util up.

## 6. Validated procedures (copy-paste safe)

All remote scripts: write LOCALLY with Write tool, scp to pod, run
`ssh ... "tr -d '\r' | bash -s"`. Inline heredocs through PowerShell break
on `$()`, quotes, backslashes. CRLF kills bash scripts (symptom: `$'\r':
command not found`, or silently corrupted env-var values).

### Detached long job (builds/training)

```bash
setsid CMD > log 2>&1 < /dev/null &
disown
```
A timed-out polling ssh session kills process groups otherwise. Lost a
25-min build once; lost another to three consecutive polls. Progress gauge
for builds: `find /tmp -name '*.o' | wc -l` (73 objects for flash-attn).

### Key/secret transfer

Shell pipes corrupt bytes (observed twice: CR injection, dropped chars).
Write locally with `[IO.File]::WriteAllBytes`, scp, md5 both ends.

### Polling cadence

Short commands, frequent. Never sleep >120s inside one ssh call (tool
timeout kills it mid-read).

## 7. Debugging playbook (fast paths)

Order of investigation when a launch fails:

1. `tail -30 /tmp/train.log` (launcher console: which component, which exit)
2. Component logs: `<run>/logs/attempt_N/{inference,orchestrator,trainer}.log`
   and `envs/train/<env>.log` — ENV LOG FIRST if rollouts misbehave
3. Trainer subprocess tracebacks: `logs/attempt_N/trainer/torchrun/**/stderr.log`
4. py-spy dump (needs SYS_PTRACE; often unavailable on RunPod) else
   faulthandler+SIGUSR1 trick (see scripts/pod_hang_lora2.sh)
5. Import hangs: `-X importtime`; usually network-FS stat storms. Move venv
   (`UV_PROJECT_ENVIRONMENT=/tmp/prl_venv`) and output dirs to local disk.

Known failure signatures -> causes (full table in docs/course/03 chapter 8):

| Signature | Cause | Fix |
|---|---|---|
| Requested 2 GPUs... only 1 | strict partitioning | rl.py patch |
| FileNotFoundError 'vllm-router' | router binary | TOML router="None" |
| ModuleNotFoundError flash_attn | unconditional imports | cp/train patches |
| Available KV cache: -X GiB | colocated profiling peak | max_num_seqs/util/eager |
| 10 consecutive zero-output batches | all scoring crashed | read env-server log |
| 'str' object is not callable in scoring | Trace.last_reply property | fixed in repo |
| taskset defines no __all__ | legacy v0 env given to launcher | export v1 classes |
| dry-run OK, runtime hang | import-time net access / FS slowness | UV_OFFLINE=1, /tmp |

## 8. Decision log (do not relitigate)

1. **Execution-as-proof, not proof search**: action space is programs checked
   by computation; soundness priced via holdouts. Foundation of the project.
2. **Binary lean_pass reward; stage info as zero-weight metrics**: shaping
   terms are hacking surfaces; metrics give diagnostics free.
3. **Sanitizer fail-closed, outside policy control forever**: anti-reward-
   hacking boundary; never migrate into prompt/model.
4. **Procedural tasks with reference artifacts**: contamination-free +
   self-testing env. Reference tests caught the holdout index bug.
5. **Canonicalize in adapter, sanitizer stays strict**: convenience without
   weakening security.
6. **LoRA for 16GB pods**: full FT needs ~20GB+ optimizer states; LoRA GRPO
   is still fully on-policy RL (not SFT).
7. **Local vLLM over provider APIs for training**: Groq breaks openai-client
   validation; local serves the exact training stack anyway.
8. **v1 Taskset over v0**: prime-rl launcher requires it; we maintain BOTH
   surfaces in one module (rubric funcs shared logic).
9. **output_dir on /tmp**: network FS makes imports/writes crawl; local
   overlay dramatically faster. Sources stay on /workspace.
10. **HF_HUB_OFFLINE only after first successful model download**: offline+
    empty cache = instant pre-download failure.

## 9. Time-cost ledger (budget pod credits accordingly)

| Operation | Wall time | Notes |
|---|---|---|
| apt zstd + Lean tarball extract | 5 min | .zst extension! |
| pip install harness+verifiers+pytest | 8 min | |
| env smoke test | 1 min | MUST pass before proceeding |
| pip install vllm + flashinfer fix | 12 min | |
| uv install + prime-rl clone + submodules | 10 min | sed git@->https first |
| uv sync (venv on LOCAL disk) | 15 min | network FS breaks rm .venv |
| ensurepip + flash-attn build (MAX_JOBS=2) | 2-3 h | THE long pole |
| Model download (Qwen 1.5B) | 2 min | |
| vLLM boot (eager, colocated) | 4-6 min | incl slow imports |
| Training smoke (24 steps x128 rollouts) | 25 min | proven |
| **Total fresh-pod to trained** | **~4-5 h** | mostly unattended |

## 10. Open issues / next steps

1. Long learning-curve run: family-balanced sampling (dataset ordered
   linear-first today; batch mix confounds trend), 300+ steps.
2. Quantify nv_stage distribution from traces (where do failures sit?).
3. Export servable weights: resume with --ckpt.weights-only, then upload.
4. Hub publishing (needs `prime login`).
5. Phase 4: self-written checkers (model emits its own property checks;
   reward gated by mutation testing of the checker).
6. Consider Docker image of the full stack to make pods 30-min-start instead
   of 4-hour installs. Highest-leverage infra investment available.

## 11. Agent etiquette notes (from an agent, to agents)

- The user pays credits per hour. Announce long operations BEFORE starting,
  batch independent work into parallel detached jobs, and never leave a pod
  idle while undecided.
- Prefer reading source on the pod (`sed -n X,Yp`) over guessing APIs. The
  harnesses branch differs from released verifiers docs in places; the
  submodule under deps/ is ground truth.
- When a check would take >2 tool calls, write it as a script file, scp, run.
- Commit and push AFTER every milestone; pods are ephemeral. Patches and
  logs live in git, not on pods.
- If blocked >1h on the same error, stop and write down: exact symptom,
  layer (build/config/runtime/env-code), evidence gathered, hypotheses
  ranked. Escalate to the human with that summary instead of churning.
