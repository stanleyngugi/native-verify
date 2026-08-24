export PYTHONUNBUFFERED=1
export PRL_RUN_ID=$(cat /proc/sys/kernel/random/uuid | tr -d '-')
export NATIVE_VERIFY_LEAN=/workspace/lean-4.23.0-linux/bin/lean
export WANDB_MODE=disabled
export HF_HUB_OFFLINE=1
pkill -9 -f "uv run" 2>/dev/null || true
sleep 2
rm -rf /workspace/prime-rl/.venv /tmp/runs/nv-smoke
mkdir -p /tmp/runs
cd /workspace/prime-rl
setsid /tmp/prl_venv/bin/rl @ /workspace/grpo_smoke.toml --output-dir /tmp/runs/nv-smoke > /tmp/train.log 2>&1 < /dev/null &
disown
echo "TRAINING LAUNCHED pid $!"
sleep 30
cat /tmp/train.log | head -12
