sed -n 200,260p /workspace/prime-rl/src/prime_rl/entrypoints/inference.py
grep -n "router" /workspace/prime-rl/src/prime_rl/configs/inference.py 2>/dev/null | head -5
find /workspace/prime-rl/src -name "inference.py" -path "*configs*" | head -2
