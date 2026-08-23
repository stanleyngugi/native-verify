P=$(pgrep -f 'PRIME-RL::Launcher' | head -1)
ps --ppid $P -o pid,cmd 2>/dev/null | head -8
ls /workspace/runs/nv-grpo-smoke/logs/ 2>/dev/null || echo no-logs-yet
nvidia-smi --query-gpu=memory.used --format=csv,noheader
