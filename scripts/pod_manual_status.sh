pgrep -f "uv run" | wc -l
curl -s -m 5 http://localhost:8000/v1/models | head -c 120; echo ""
tail -5 /workspace/manual_run/inference.log 2>/dev/null
echo "=== env ==="
tail -3 /workspace/manual_run/envserver.log 2>/dev/null
echo "=== trainer ==="
tail -3 /workspace/manual_run/trainer.log 2>/dev/null
echo "=== orch ==="
tail -3 /workspace/manual_run/orchestrator.log 2>/dev/null
nvidia-smi --query-gpu=memory.used --format=csv,noheader
