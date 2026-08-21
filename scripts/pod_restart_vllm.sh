python3 -c "import flashinfer.comm; print('flashinfer import OK')" 2>&1 | tail -3
cd /workspace
nohup python3 -m vllm.entrypoints.openai.api_server --model Qwen/Qwen2.5-1.5B-Instruct --port 8000 > /workspace/vllm.log 2>&1 &
echo vllm restarted
for i in $(seq 1 40); do
  sleep 10
  if curl -s -m 5 http://localhost:8000/v1/models | grep -q Qwen; then
    echo "READY after $((i*10))s"
    exit 0
  fi
done
echo "NOT READY"
tail -8 /workspace/vllm.log
