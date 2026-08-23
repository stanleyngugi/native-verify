grep -n "num_infer_gpus\|num_train_gpus\|deployment" /workspace/prime-rl/src/prime_rl/entrypoints/rl.py | head -15
echo ====
grep -rn "num_infer_gpus" /workspace/prime-rl/src/prime_rl/ --include="*.py" | grep -v entrypoints | head -5
