grep -rn "deployment" /workspace/prime-rl/src/prime_rl/entrypoints/rl.py | grep -E "import|Deployment|Field|= " | head -8
grep -rn "num_train_gpus\|gpus_per_node\|class.*Config" $(grep -rln "deployment" /workspace/prime-rl/deps/pydantic-config/src 2>/dev/null | head -2) 2>/dev/null | grep -i deploy | head -6
find /workspace/prime-rl/src -name "*.py" | xargs grep -ln "SingleNode\|num_infer_gpus: int" 2>/dev/null | grep -v pycache | head -3
