grep -rn "num_infer_gpus" /workspace/prime-rl/src/prime_rl/utils/configs.py /workspace/prime-rl/src/prime_rl/*.py 2>/dev/null | head
grep -rln "class Deployment" /workspace/prime-rl/src/ 2>/dev/null | grep -v pycache
