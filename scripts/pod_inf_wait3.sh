for i in $(seq 1 30); do
  sleep 15
  if curl -s -m 5 http://localhost:8000/v1/models 2>/dev/null | grep -q Qwen; then echo "INFER_READY"; break; fi
done
grep -iE "Available KV|error" /workspace/manual_run/inference.log | tail -3
nvidia-smi --query-gpu=memory.used --format=csv,noheader
