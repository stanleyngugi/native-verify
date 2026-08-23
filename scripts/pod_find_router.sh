ls /workspace/prime-rl/.venv/bin/ | grep -iE "router|vllm" | head -5
pgrep -f "env-server|trainer|orchestrator" | wc -l
