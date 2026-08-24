cd /workspace/prime-rl
grep -rn gpu_memory_utilization src/ 2>/dev/null | head -5
echo ---
grep -rn "EngineArgs" src/ 2>/dev/null | grep -v pycache | head -4
