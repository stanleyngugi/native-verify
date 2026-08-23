grep -rln "num_infer_gpus" /workspace/prime-rl/.venv/lib/python3.12/site-packages/ 2>/dev/null | grep -v ".dist-info" | head -3
