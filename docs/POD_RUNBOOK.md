# GPU Pod Runbook (RunPod A40, validated 2026-08-21)

Every command here was executed and debugged on a real RunPod A40 pod
(194.68.245.106:22196, Python 3.11 system, 96 CPUs). A fresh pod repeats this
sequence top to bottom. All remote scripts assume CRLF-stripped stdin:
`Get-Content <script> -Raw | ssh ... "tr -d '\r' | bash -s"`.

## 1. Lean toolchain (~5 min)

```bash
apt-get update -qq && apt-get install -y -qq zstd
cd /workspace
curl -sL -o lean.tar.zst https://github.com/leanprover/lean4/releases/download/v4.23.0/lean-4.23.0-linux.tar.zst
tar --zstd -xf lean.tar.zst && rm lean.tar.zst
/workspace/lean-4.23.0-linux/bin/lean --version
```

Note: asset extension is `.zst`, not `.zstd`. chown warnings during extraction
are harmless (network FS as root).

## 2. Repo + harness + verifiers (~10 min)

```bash
git clone https://github.com/stanleyngugi/native-verify.git /workspace/native-verify
pip install . verifiers pytest   # inside /workspace/native-verify
export NATIVE_VERIFY_LEAN=/workspace/lean-4.23.0-linux/bin/lean
python scripts/smoke_env.py      # must print "env smoke passed"
```

## 3. API key transfer (use scp with exact bytes)

Shell pipes corrupt key bytes (observed twice: CR bytes, dropped chars).
Write the key locally with `[IO.File]::WriteAllBytes` and `scp` it:

```powershell
[IO.File]::WriteAllBytes("$env:TEMP\gq.key", [Text.Encoding]::UTF8.GetBytes($key))
scp -P <port> "$env:TEMP\gq.key" root@<host>:/root/.groq_key
```

Verify with md5 on both ends before trusting it.

## 4. vf-eval gate (optional but recommended)

```bash
pip install ./environments/native_verify_seq
vf-eval native-verify-seq -m openai/gpt-oss-20b -b https://api.groq.com/openai/v1 \
  -k GROQ_API_KEY -n 5 -r 2
```

Known issue: Groq returns `service_tier: "on_demand"`, which crashes openai
client >= 3.x pydantic validation. Local vLLM avoids this entirely; prefer it.

## 5. vLLM inference server (~15 min incl. model download)

```bash
pip install vllm
# IMPORTANT: if flashinfer-python==0.6.16.post3 is pulled in on Python 3.11,
# engine startup dies with "TypeError: type 'array.array' is not subscriptable".
# Fix: pip install -U flashinfer-python (0.6.17+ imports cleanly).
nohup python3 -m vllm.entrypoints.openai.api_server \
  --model Qwen/Qwen2.5-1.5B-Instruct --port 8000 > /workspace/vllm.log 2>&1 &
# poll http://localhost:8000/v1/models until ready (~2 min)
```

Baseline measured: Qwen2.5-1.5B-Instruct scores **2.5%** (1/40) on
native-verify-seq at temperature 0.9 — ideal GRPO starting point.

## 6. prime-rl (~30 min)

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh   # PATH: ~/.local/bin
git clone https://github.com/PrimeIntellect-ai/prime-rl.git /workspace/prime-rl
cd /workspace/prime-rl
sed -i "s|git@github.com:|https://github.com/|" .gitmodules
git submodule update --init --recursive --force
# verify all five deps/ subdirs are non-empty (pydantic-config showed up empty once)
ls deps/pydantic-config/pyproject.toml deps/prime-kernels/setup.py
uv sync
uv pip install -e /workspace/native-verify -e /workspace/native-verify/environments/native_verify_seq
uv run rl --help   # smoke
```

## 7. flash-attn (the long pole, ~30-60 min source build)

The trainer imports `flash_attn` unconditionally (via ring_flash_attn).
torch in the uv venv is 2.11.0+cu128 — no prebuilt wheel yet, so build:

```bash
export PATH="$HOME/.local/bin:$PATH"
MAX_JOBS=64 nohup uv pip install --python .venv/bin/python \
  --no-build-isolation flash-attn > /tmp/flashattn_build.log 2>&1 &
# poll until "Installed" appears; then:
.venv/bin/python -c "import flash_attn"
```

## 8. GRPO smoke launch

Config: `configs/grpo_smoke_a40.toml` in repo root (scp to /workspace/grpo_smoke.toml).
Key points baked in: `[orchestrator.renderer] name = "default"` (Qwen2.5 not in
MODEL_RENDERER_MAP), NATIVE_VERIFY_LEAN via `[env_vars]`, batch 32 x group 8,
24 steps.

Kill any standalone vLLM first (`pkill -f vllm.entrypoints`) — prime-rl starts
its own inference server.

```bash
pkill -f vllm.entrypoints || true
nohup uv run rl @ /workspace/grpo_smoke.toml \
  --output-dir /workspace/runs/nv-grpo-smoke > /workspace/train_launch.log 2>&1 &
tail -F /workspace/runs/nv-grpo-smoke/logs/{orchestrator,inference,trainer}.log
# watch reward/all/env mean trend upward; env-side errors in logs/envs/train/
```

## Debug trail from the validated session

1. `taskset module defines no __all__` -> env module now exports the v1
   NativeVerifyTaskset (+ Config) alongside legacy load_environment.
2. renderer 'auto' validation failure -> explicit `name = "default"`.
3. Empty submodule dirs despite clean `submodule status` ->
   `git submodule update --force --recursive`.
4. Reward funcs crashing on aborted rollouts -> defensive completion access.
