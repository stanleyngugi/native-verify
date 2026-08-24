export PATH="$HOME/.local/bin:$PATH"
export PYTHONUNBUFFERED=1
export PRL_RUN_ID=$(cat /proc/sys/kernel/random/uuid | tr -d '-')
export NATIVE_VERIFY_LEAN=/workspace/lean-4.23.0-linux/bin/lean
export WANDB_MODE=disabled
export HF_HUB_OFFLINE=1
pkill -f vllm.entrypoints 2>/dev/null || true
sleep 2
cd /workspace/prime-rl
rm -rf /tmp/runs/nv-smoke
mkdir -p /tmp/runs
setsid uv run --offline rl @ /workspace/grpo_smoke.toml --output-dir /tmp/runs/nv-smoke > /tmp/train.log 2>&1 < /dev/null &
disown
echo "TRAINING LAUNCHED pid $!"
sleep 20
cat /tmp/train.log | head -10
