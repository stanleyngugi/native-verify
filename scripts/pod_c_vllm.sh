export PATH="$HOME/.local/bin:$PATH"
cd /workspace
nohup bash -c 'tr -d "\r" < /dev/null; true' > /dev/null 2>&1 || true
setsid nohup /bin/bash /workspace/primerl_setup_inner.sh > /tmp/primerl_stage.log 2>&1 &
echo "prime-rl setup launched in background"
pip install -q -U flashinfer-python 2>&1 | tail -1
python3 -c "import flashinfer.comm; print('flashinfer import OK')" 2>&1 | tail -1
nohup python3 -m vllm.entrypoints.openai.api_server --model Qwen/Qwen2.5-1.5B-Instruct --port 8000 > /workspace/vllm.log 2>&1 &
echo "vllm starting"
for i in $(seq 1 40); do
  sleep 10
  if curl -s -m 5 http://localhost:8000/v1/models 2>/dev/null | grep -q Qwen; then echo "VLLM READY after $((i*10))s"; exit 0; fi
done
echo "VLLM NOT READY"
tail -10 /workspace/vllm.log
