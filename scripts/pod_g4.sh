grep -rn "class SingleNodeDeployment" /workspace/prime-rl/src/ 2>/dev/null | grep -v pycache
grep -rln "num_train_gpus" /workspace/prime-rl/src/ 2>/dev/null | grep -v pycache | head -4
