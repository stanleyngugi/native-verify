timeout 30 /workspace/prime-rl/.venv/bin/python -c 'import prime_rl.configs.rl; print(1)' 2>&1; echo A
HF_HUB_OFFLINE=1 timeout 30 /workspace/prime-rl/.venv/bin/python -c 'import prime_rl.configs.rl; print(1)' 2>&1; echo B
HF_HUB_OFFLINE=1 TRANSFORMERS_OFFLINE=1 timeout 30 /workspace/prime-rl/.venv/bin/python -c 'import prime_rl.configs.rl; print(1)' 2>&1; echo C
