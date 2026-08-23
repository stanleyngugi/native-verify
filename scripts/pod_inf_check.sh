tail -15 /workspace/manual_run/inference.log
curl -s -m 5 http://localhost:8000/v1/models | head -c 150; echo ""
pgrep -f "env-server|trainer|orchestrator|inference" | wc -l
