cd /workspace/prime-rl
grep -rn "gpu_memory_utilization\|sleep\|colocate" src/prime_rl/configs/*.py 2>/dev/null | head -10
ls src/prime_rl/configs/
