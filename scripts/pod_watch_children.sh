sleep 240
ps --ppid $(pgrep -f 'uv run rl' | head -1) -o pid,cmd 2>/dev/null | head -6
ls /workspace/runs/nv-grpo-smoke/logs/ 2>/dev/null || echo no-logs-yet
tail -3 /workspace/train_launch.log
