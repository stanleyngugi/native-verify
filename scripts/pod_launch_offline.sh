export PATH="$HOME/.local/bin:$PATH"
export PYTHONUNBUFFERED=1
export PRL_RUN_ID=$(cat /proc/sys/kernel/random/uuid | tr -d '-')
export NATIVE_VERIFY_LEAN=/workspace/lean-4.23.0-linux/bin/lean
export WANDB_MODE=disabled
export UV_OFFLINE=1
cd /workspace/prime-rl
rm -rf /workspace/runs/nv-grpo-smoke
setsid uv run rl @ /workspace/grpo_smoke.toml --output-dir /workspace/runs/nv-grpo-smoke > /workspace/train_launch5.log 2>&1 < /dev/null &
disown
echo "launched $! run $PRL_RUN_ID"
sleep 15
cat /workspace/train_launch5.log 2>&1 | head -10
ls /workspace/runs/nv-grpo-smoke/ 2>&1 | head -5
