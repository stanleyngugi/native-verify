export PATH="$HOME/.local/bin:$PATH"
cd /workspace/prime-rl
mkdir -p /workspace/runs
nohup uv run rl @ /workspace/grpo_smoke.toml --output-dir /workspace/runs/nv-grpo-smoke > /workspace/train_launch.log 2>&1 &
echo "launched pid $!"
sleep 90
ls /workspace/runs/nv-grpo-smoke/logs/ 2>/dev/null
tail -5 /workspace/runs/nv-grpo-smoke/logs/inference.log 2>/dev/null || tail -20 /workspace/train_launch.log
