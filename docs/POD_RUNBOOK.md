# GPU Pod Runbook (validated across two RunPod sessions, 2026-08-21/23)

Everything here was executed and debugged on real pods: an A40 46GB and an
RTX 2000 Ada 16GB. A fresh pod repeats this sequence top to bottom. Remote
scripts assume CRLF-stripped stdin:
`Get-Content <script> -Raw | ssh ... "tr -d '\r' | bash -s"`.
Write remote scripts via the Write tool + scp; inline heredocs break under
PowerShell escaping.

## 0. Pre-flight checks (learned the hard way)

```bash
cat /sys/fs/cgroup/memory.max        # REAL memory ceiling - RunPod advertises
                                     # host RAM but cgroup may cap at ~31GB
nvidia-smi --query-gpu=name,memory.total,compute_cap --format=csv,noheader
df -h / /workspace                   # note which is network FS (slow imports)
```

## 1. prime-rl hard-requires >= 2 GPUs

The `rl` launcher partitions GPUs: inference gets N, trainer gets M, and
refuses `N+M > physical`. There is no colocated mode upstream. Two options:

- Rent a pod with >= 2 GPUs (config below then works unmodified), or
- Apply `patches/prime-rl/rl.py` (maps both requests onto GPU 0 when only one
  exists). The other two patched files (`cp.py`, `train.py`) make
  ring_flash_attn imports optional - single GPU never uses ring attention
  (gated by `cp_enabled`), but the module-level imports crash otherwise.

## 2. Lean toolchain (~5 min)

```bash
apt-get update -qq && apt-get install -y -qq zstd
cd /workspace
curl -sL -o lean.tar.zst https://github.com/leanprover/lean4/releases/download/v4.23.0/lean-4.23.0-linux.tar.zst
tar --zstd -xf lean.tar.zst --no-same-owner   # --no-same-owner: chown fails on net FS
rm lean.tar.zst
./lean-4.23.0-linux/bin/lean --version
```

Asset extension is `.zst`, not `.zstd`.

## 3. Harness + verifiers (~10 min)

```bash
git clone https://github.com/stanleyngugi/native-verify.git /workspace/native-verify
cd /workspace/native-verify && pip install . verifiers pytest
export NATIVE_VERIFY_LEAN=/workspace/lean-4.23.0-linux/bin/lean
python scripts/smoke_env.py    # must print "env smoke passed"
```

## 4. vLLM inference server (~15 min)

```bash
pip install vllm
# flashinfer-python==0.6.16.post3 breaks Python 3.11 engine startup
# ("TypeError: type 'array.array' is not subscriptable"). Fix:
pip install -U flashinfer-python
nohup python3 -m vllm.entrypoints.openai.api_server \
  --model Qwen/Qwen2.5-1.5B-Instruct --port 8000 > vllm.log 2>&1 &
```

Baseline: Qwen2.5-1.5B-Instruct scores **2.5%** (1/40) on native-verify-seq
at temperature 0.9 - near-zero but nonzero reward, ideal GRPO start.

Groq API note: returns `service_tier: "on_demand"` which crashes openai
client pydantic validation. Use local vLLM instead.

## 5. prime-rl install (~30 min + flash-attn)

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh   # -> ~/.local/bin
git clone https://github.com/PrimeIntellect-ai/prime-rl.git /workspace/prime-rl
cd /workspace/prime-rl
sed -i "s|git@github.com:|https://github.com/|" .gitmodules
git submodule update --init --recursive --force
# verify ALL deps are non-empty (pydantic-config showed up empty once):
ls deps/pydantic-config/pyproject.toml deps/prime-kernels/setup.py
uv sync
uv pip install -e /workspace/native-verify \
               -e /workspace/native-verify/environments/native_verify_seq
```

### flash-attn (the long pole: 1-3 HOURS on constrained pods)

The trainer imports flash_attn unconditionally via ring_flash_attn. With a
31GB cgroup limit, MAX_JOBS must be tiny or nvcc jobs get OOM-killed silently.

```bash
export PATH="/usr/local/cuda/bin:$HOME/.local/bin:$PATH"
export CUDA_HOME=/usr/local/cuda          # nvcc lives here, not on PATH
export TORCH_CUDA_ARCH_LIST="8.9"         # RTX 2000 Ada; skip all other archs
export FLASH_ATTENTION_FORCE_BUILD=1
export MAX_JOBS=2                         # NOT more - cgroup OOM otherwise
export NVCC_THREADS=1
cd /workspace/prime-rl
.venv/bin/python -m ensurepip             # uv venvs ship without pip
setsid .venv/bin/python -m pip install --force-reinstall --no-deps \
  --no-build-isolation --no-binary :all: flash-attn==2.8.3.post1 \
  > /tmp/fa_build.log 2>&1 < /dev/null &
disown                                    # setsid+disown: survives ssh drops
```

Traps hit in practice:
- `uv pip install flash-attn` served stale CPU-only wheels from cache twice.
  Only `.venv/bin/pip ... --no-binary :all:` produced real kernels.
- Without setsid/disown, tool-timeout on the polling ssh killed the build.
- Progress gauge: `find /tmp -name '*.o' | wc -l` (73 objects when done).
- On 16GB pod with MAX_JOBS=2: ~90 min. On unconstrained: ~30 min.

## 6. Launch (after applying patches/prime-rl/* if single GPU)

Kill any standalone vLLM first (`pkill -f vllm.entrypoints`). Config:
`configs/grpo_smoke_16gb.toml`. Critical fields learned by failure:

- `[inference] router = "None"` - the vllm-router binary is not installed;
  without this, inference crashes with FileNotFoundError before serving.
- `[inference.vllm] gpu_memory_utilization = 0.35`, `max_model_len = 2048`,
  `enforce_eager = true` - model default context is 32k and KV-cache goes
  negative otherwise on shared 16GB.
- `[env_vars] NATIVE_VERIFY_LEAN`, `HF_HUB_OFFLINE = "1"` (after first model
  download).
- `[orchestrator.renderer] name = "default"` - Qwen2.5 is not in
  MODEL_RENDERER_MAP and 'auto' hard-fails validation.
- **output_dir on /tmp, not /workspace** - the network FS makes every torch
  import take minutes; local overlay disk is dramatically faster.

```bash
pkill -f vllm.entrypoints || true
export PRL_RUN_ID=$(cat /proc/sys/kernel/random/uuid | tr -d '-')
setsid uv run rl @ /workspace/grpo_smoke.toml \
  --output-dir /tmp/runs/nv-smoke > /tmp/train.log 2>&1 < /dev/null &
```

Watch: `/tmp/train.log`, then `<output_dir>/*/logs/attempt_*/{orchestrator,inference,trainer}.log`.
Success looks like: inference serving on :8000, orchestrator stops polling,
rollout/reward lines appear.

## Debug trail (all hit in practice)

1. `taskset module defines no __all__` -> env exports NativeVerifyTaskset.
2. renderer 'auto' validation failure -> explicit `name = "default"`.
3. Empty submodule dirs despite clean status -> `--force --recursive`.
4. Reward funcs crashing on aborted rollouts -> defensive completion access.
5. Groq service_tier pydantic failure -> local vLLM.
6. flashinfer 0.6.16.post3 import crash -> upgrade.
7. Requested 2 GPUs error -> colocated patch or bigger pod.
8. vllm-router FileNotFoundError -> router = "None".
9. ModuleNotFoundError flash_attn in trainer -> cp.py/train.py patches.
10. KV cache negative -> max_model_len + eager mode.
11. Silent build kills -> cgroup limit + MAX_JOBS.
12. Builds dying between polls -> setsid disown pattern.

## Session outcome summary (2026-08-23/24)

- Environment validated on Linux end-to-end (smoke + vf-eval + baseline).
- All infrastructure issues mapped with fixes; training launch blocked only
  on completing component boot within a session window. Next attempt starts
  from section 6 directly.
