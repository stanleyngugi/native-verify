grep -rn "vllm-router" /workspace/prime-rl/src/prime_rl/ --include="*.py" | head -3
find /workspace/prime-rl/.venv /root/.cargo /usr/local/bin -name "*router*" -type f 2>/dev/null | head -5
tail -8 /workspace/manual_run/inference.log
