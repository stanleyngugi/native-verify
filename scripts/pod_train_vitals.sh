echo "=== procs ==="
pgrep -f "prime_rl|vllm|rl @" | wc -l
echo "=== logs ==="
ls /workspace/runs/nv-grpo-smoke/logs/ 2>/dev/null
echo "=== launch tail ==="
tail -6 /workspace/train_launch.log 2>/dev/null
echo "=== gpu ==="
nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader
