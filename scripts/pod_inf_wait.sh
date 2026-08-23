for i in $(seq 1 30); do
  sleep 15
  if curl -s -m 5 http://localhost:8000/v1/models 2>/dev/null | grep -q Qwen; then echo "INFER READY"; break; fi
done
tail -4 /workspace/manual_run/inference.log
pgrep -f "env-server|Trainer|Orchestrator|trainer @|orchestrator @" | wc -l
