grep -rn "class SingleNodeDeployment\|num_infer_gpus\|num_train_gpus" /workspace/prime-rl/src/prime_rl/utils/*.py 2>/dev/null | head -8
grep -rln "SingleNodeDeployment\|class.*Deployment" /workspace/prime-rl/src/prime_rl/ --include="*.py" | grep -v pycache | head -4
