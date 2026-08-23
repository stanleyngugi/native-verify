grep -rn "num_infer_gpus" /workspace/prime-rl/src/prime_rl/ --include="*.py" 2>/dev/null | grep -v pycache | head -6
