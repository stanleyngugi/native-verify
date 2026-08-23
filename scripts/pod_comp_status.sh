pgrep -f "env-server|trainer @|orchestrator @" | wc -l
echo "=== orch ==="
tail -5 /workspace/manual_run/orchestrator.log
echo "=== trainer ==="
tail -3 /workspace/manual_run/trainer.log
