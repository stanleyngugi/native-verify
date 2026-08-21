for i in $(seq 1 40); do
  sleep 10
  if curl -s -m 5 http://localhost:8000/v1/models | grep -q Qwen; then
    echo "READY after $((i*10))s"
    exit 0
  fi
done
echo "NOT READY"
tail -15 /workspace/vllm.log
