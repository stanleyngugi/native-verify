export PATH="$HOME/.local/bin:$PATH"
export PYTHONUNBUFFERED=1
PRL_RUN_ID=$(cat /proc/sys/kernel/random/uuid | tr -d '-')
export PRL_RUN_ID
export NATIVE_VERIFY_LEAN=/workspace/lean-4.23.0-linux/bin/lean
export WANDB_MODE=disabled
sed -i '/^\[inference\]/a router = "None"' /workspace/grpo_smoke.toml
cat /workspace/grpo_smoke.toml | grep -A3 "^\[inference"
cd /workspace/prime-rl
rm -rf /workspace/runs/nv-grpo-smoke
setsid uv run rl @ /workspace/grpo_smoke.toml --output-dir /workspace/runs/nv-grpo-smoke > /workspace/train_launch4.log 2>&1 < /dev/null &
disown
sleep 10
cat /workspace/train_launch4.log 2>&1 | head -15
ls /workspace/runs/nv-grpo-smoke/ 2>&1 | head -5
