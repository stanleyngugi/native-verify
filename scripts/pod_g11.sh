find /workspace/prime-rl/src/prime_rl -name "rl.py" -path "*configs*" | head -2
grep -rn "gpu_memory_utilization\|colocate\|sleep" /workspace/prime-rl/src/prime_rl/ --include="*.py" 2>/dev/null | grep -v pycache | grep -viE "test|#.*sleep" | head -10
