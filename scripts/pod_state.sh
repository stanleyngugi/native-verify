pgrep -f "rl @" | wc -l
tail -15 /workspace/train_launch.log
ls /workspace/runs/nv-grpo-smoke/logs 2>/dev/null || echo no-logs
nvidia-smi --query-gpu=memory.used --format=csv,noheader
