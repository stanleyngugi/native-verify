tail -15 /workspace/train_launch3.log
ls /workspace/runs/nv-grpo-smoke/ 2>/dev/null | head -5
ps aux | grep -E "rl @|PRIME-RL" | grep -v grep | head -2
