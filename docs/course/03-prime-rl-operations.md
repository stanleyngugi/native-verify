# Course 03 — prime-rl Operations (the field manual)

> Part 3 of the curriculum. This is operational knowledge: how the trainer is
> actually wired, and every way we watched it break. Read once for the mental
> model; afterwards use `docs/POD_RUNBOOK.md` as the launch checklist.

---

## Chapter 1 — The four processes

`uv run rl @ config.toml` spawns and supervises four components:

```text
┌──────────────┐   rollouts    ┌──────────────────┐
│ ORCHESTRATOR │ ────────────> │ INFERENCE (vLLM) │  GPU A
│ samples tasks│ <──────────── │ serves policy    │
│ drives envs  │               └──────────────────┘
│ computes r   │
└──────┬───────┘
       │ task dispatch          ┌──────────────┐
       └──────────────────────> │ ENV SERVER(S)│  CPU
            episodes scored     │ (your code!) │
                                └──────────────┘
┌──────────────┐   weights     ┌──────────────────┐
│ TRAINER      │ ────────────> │ INFERENCE        │  GPU B
│ FSDP + GRPO  │  broadcast    │ (/update_weights)│
└──────────────┘               └──────────────────┘
```

Key insight that took us a day to learn: **the launcher strictly partitions
GPUs — inference gets some, trainer gets the rest, no sharing.** Default
deployment requests `num_infer_gpus=1` + `num_train_gpus=1`. On a 1-GPU pod
it dies with:

```text
ValueError: Requested 2 GPUs via deployment settings, but only 1 physical GPU(s)
```

Our fix (`patches/prime-rl/rl.py`): when exactly 2 are requested and only 1
exists, map both onto GPU 0, lower vLLM's memory fraction, cap
`max_num_seqs`, run eager mode, and delay trainer spawn until inference has
stabilized. Colocation works fine for 0.5B–3B models; it just isn't upstream.

---

## Chapter 2 — The config system

pydantic-config layers three sources, later wins:

```text
defaults < TOML files (@file.toml, left-to-right deep merge) < CLI dotted flags
```

Examples:

```bash
uv run rl @ base.toml @ overlay.toml      # compose
uv run rl @ rl.toml --trainer.optim.lr 5e-6 --max-steps 24
uv run rl @ rl.toml --output-dir /tmp/x --dry-run   # validate & write resolved
```

TOML uses snake_case; CLI kebab-case. Lists in overlays replace wholesale.
The literal `"None"` coerces to null. Unknown extra fields under
`[inference.vllm]` flow into vLLM's own arg namespace via `model_extra` —
that's how `max_num_seqs = 64` reached the engine without patching.

**Debugging discipline:** `--dry-run` resolves and validates the entire config
and writes per-process TOMLs to `<output_dir>/configs/`. It catches schema,
renderer, and import errors in seconds. It does NOT catch runtime failures
(imports at subprocess start, memory races, custody bugs) — those need logs.

Renderer gotcha: `[orchestrator.renderer] name = "auto"` hard-fails unless the
model is in `MODEL_RENDERER_MAP`. Fine-tunes and unmapped models want
`name = "default"` (uses the tokenizer's chat template).

---

## Chapter 3 — The environment server

Your environment runs in its own process (`uv run env-server @ ...json`),
spawned by the launcher per train/eval source. Consequences:

- Env-side errors appear in `<run>/logs/envs/<split>/<env>.log`, NOT in the
  orchestrator log. This is the first log to read.
- Env vars reach your code through `[env_vars]` / `[orchestrator.env_vars]`
  in TOML — this is how NATIVE_VERIFY_LEAN reaches our sanitizer runner.
- Orchestrator polls the env server's deterministic address at startup, so
  component start order is forgiving.

Failure signature we hit: orchestrator aborts after
`10 consecutive zero-output batch equivalents`. Causes in practice: all
rollouts erroring (verifier bug — ours), or inference never becoming ready.

---

## Chapter 4 — Inference server specifics

prime-rl wraps vLLM with additions: `/update_weights` (policy sync), LoRA
reload, a router for multi-engine. Failure modes we met:

| Symptom | Cause | Fix |
|---|---|---|
| `FileNotFoundError: 'vllm-router'` | router binary not installed | TOML: `[inference] router = "None"` (engine then serves directly on server.port) |
| Engine dies at boot on Python 3.11: `'array.array' not subscriptable` | flashinfer 0.6.16.post3 import crash guarded too narrowly | upgrade flashinfer |
| Groq/openai: `service_tier 'on_demand'` pydantic failure | provider returns nonstandard enum | use local vLLM |
| `No available memory for cache blocks` | profiling peak over budget | raise util, cut max_model_len/max_num_seqs, enforce_eager |

Memory math for colocated 16GB (our working values):

```text
inference: gpu_memory_utilization=0.35..0.45, max_model_len=2048,
           max_num_seqs=64, enforce_eager=true   -> ~6-7GB
trainer:   LoRA on 1.5B bf16                     -> ~5GB
headroom:  ~4GB                                   -> stable
```

The profiling peak scales with `max_num_seqs x max_model_len`; default
1024 seqs can alone consume several GB *before* KV cache is even allocated.

---

## Chapter 5 — flash-attn builds on constrained pods

The trainer imports flash_attn unconditionally (through ring_flash_attn).
Prebuilt wheels rarely match bleeding-edge torch; you will compile.

Requirements discovered by failure:

```bash
export CUDA_HOME=/usr/local/cuda          # nvcc location
export TORCH_CUDA_ARCH_LIST="8.9"         # ONLY your GPU's arch (sm_89 here)
export FLASH_ATTENTION_FORCE_BUILD=1
export MAX_JOBS=2                         # sized to CGROUP limit, not host RAM!
export NVCC_THREADS=1
```

The traps, each costing real time:

1. **Container memory != host memory.** RunPod advertised 251GB;
   `/sys/fs/cgroup/memory.max` said 31GB. MAX_JOBS=40 meant 40 parallel nvcc
   jobs each spiking GBs => silent SIGKILL ("Killed" lines, exit 255).
2. **uv cache served stale CPU-only wheels** twice. Only
   `.venv/bin/pip install --no-binary :all:` produced real kernels.
3. **uv venvs ship without pip** — `.venv/bin/python -m ensurepip` first.
4. **nvcc not on PATH** even though /usr/local/cuda exists.
5. Progress gauge without noisy logs:
   `find /tmp -name '*.o' | wc -l` (73 objects = done).

---

## Chapter 6 — Operational discipline (how not to lose work)

1. **Detach long jobs**: `setsid CMD > log 2>&1 < /dev/null & disown`.
   A polling ssh session hitting a tool timeout kills the whole process
   group otherwise. We lost a 25-minute build this way once.
2. **Never poll with long sleeps inside one ssh**; short checks, frequent.
3. **Write remote scripts locally, scp them, run with
   `tr -d '\r' | bash -s`** — inline heredocs die under PowerShell quoting,
   which mangles `$()`, quotes, and backslashes unpredictably.
4. **Verify byte-exact transfers** (md5 both ends) before trusting any
   credential or binary moved through shell pipes.
5. **Pre-flight block, always**:

```bash
nvidia-smi --list-gpus | wc -l        # >=2? skip colocate patches
cat /sys/fs/cgroup/memory.max         # real RAM ceiling
df -h / /workspace                    # which FS is network (slow)?
ls /usr/local/cuda/bin/nvcc           # compiler present?
```

6. **Network filesystems poison Python**: torch imports take minutes, uv
   cannot rm .venv, file writes stall. Venvs (`UV_PROJECT_ENVIRONMENT=/tmp/
   prl_venv`) and run outputs belong on local overlay disk; keep only sources
   on the mounted volume.

---

## Chapter 7 — Reading a training run

Console line anatomy:

```text
Step 12 | 1m 5s | Reward 0.7500 | Trainable 8/8 (100%) | Error 0.0%
```

- **Reward**: mean verified-reward across the step's rollouts. Judge trends
  only across many steps AND constant batch composition (ours swung wildly
  because task families differ in difficulty and batches weren't balanced).
- **Trainable n/n**: groups containing reward variance. 100% = every batch
  gave gradient signal; chronically low = tasks too hard/easy for the group.
- **Error %**: infra/env exceptions (should be ~0).
- Health metrics worth watching: `mismatch_kl` (off-policy drift),
  `entropy` (collapse warning), `errored_rollouts`.

Artifacts written per run:

```text
<output_dir>/<env>--<model>--<hash>/
├── configs/           # resolved per-process configs (reusable!)
├── logs/attempt_N/    # per-component logs; envs/ first on failure
├── metrics.jsonl      # system + training metrics per step
├── checkpoints/step_N # FSDP-sharded model + optimizer
└── weights/step_N     # HF-servable snapshot (with --ckpt.weights-only)
```

---

## Chapter 8 — Incident index

Every failure from our sessions, mapped to cause and fix:

| # | Symptom | Root cause | Fix |
|---|---|---|---|
| 1 | engine boot crash `'array.array' not subscriptable` | flashinfer 0.6.16.post3 on py3.11 | upgrade flashinfer |
| 2 | openai pydantic `service_tier` failure vs Groq | nonstandard provider enum | local vLLM |
| 3 | `Requested 2 GPUs... only 1` | strict partitioning | colocated rl.py patch |
| 4 | `FileNotFoundError: 'vllm-router'` | optional binary absent | `router = "None"` |
| 5 | `ModuleNotFoundError: flash_attn` in trainer | unconditional ring_flash_attn import | try/except patches (cp.py, train.py) |
| 6 | nvcc jobs silently Killed | 31GB cgroup OOM | MAX_JOBS=2, NVCC_THREADS=1 |
| 7 | reinstall produced CPU-only wheel | uv stale cache | pip --no-binary :all: |
| 8 | `No virtual environment found` | UV_PROJECT_ENVIRONMENT lost between calls | explicit `--python` / PATH |
| 9 | `Failed to remove directory .venv` os err 39 | network FS | venv on /tmp |
| 10 | KV cache negative GiB | colocated profiling peak | max_num_seqs, eager, staggered start |
| 11 | every rollout scored zero | `trace.last_reply()` called as method | property, drop parens |
| 12 | renderer validation failure at dry-run | Qwen2.5 unmapped | `name = "default"` |
| 13 | build died between polls | ssh session teardown killed group | setsid disown detach |
| 14 | key file corrupt after transfer | shell pipe mangling | scp + md5 verify |

---

## Exercises

1. Compute the memory budget table for YOUR pod before launching anything.
2. Reproduce incident 10 deliberately: set `max_num_seqs` to 1024 on a
   shared-GPU setup and watch the KV number go negative. Reading the profile
   lines teaches more than the fix.
3. Trace one full episode through the four logs (orchestrator → inference →
   env-server → trainer) and annotate where wall-clock time went.
