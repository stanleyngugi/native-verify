cd /workspace/prime-rl
grep -rn "gpu_memory_utilization" . --include="*.py" 2>/dev/null | grep -v ".venv" | grep -v pycache | head -6
echo ---
ls src/prime_rl/inference/vllm/ 2>/dev/null
