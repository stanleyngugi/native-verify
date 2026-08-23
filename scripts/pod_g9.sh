grep -n "Deployment\|deployment" /workspace/prime-rl/src/prime_rl/configs/*.py 2>/dev/null | grep -E "class|= " | head -8
ls /workspace/prime-rl/src/prime_rl/configs/ 2>/dev/null
