sleep 300
echo "=== orch ==="
tail -8 /workspace/manual_run/orchestrator.log
echo "=== trainer ==="
tail -8 /workspace/manual_run/trainer.log
pgrep -f "orchestrator|rl.train|env-server" | wc -l
nvidia-smi --query-gpu=memory.used --format=csv,noheader
