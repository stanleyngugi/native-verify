grep -rn "num_infer_gpus\|num_train_gpus" /workspace/prime-rl/deps/pydantic-config 2>/dev/null | head -3
.venv/bin/python -c "
from prime_rl.entrypoints.rl import RLConfig
c = RLConfig()
print('deployment type:', c.deployment.type)
print('num_infer_gpus:', c.deployment.num_infer_gpus)
print('num_train_gpus:', c.deployment.num_train_gpus)
print('fields:', list(c.deployment.model_fields.keys()))
" 2>&1 | tail -6
