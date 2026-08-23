set -e
export PATH="$HOME/.local/bin:$PATH"
export NATIVE_VERIFY_LEAN=/workspace/lean-4.23.0-linux/bin/lean
C=/workspace/runs/nv-grpo-smoke/native-verify-seq--qwen2.5-1.5b-instruct--1346e277/configs
mkdir -p /workspace/manual_run
cp -r $C/* /workspace/manual_run/
python3 - <<'EOF'
import json
p = "/workspace/manual_run/inference.json"
cfg = json.load(open(p))
cfg["vllm"]["gpu_memory_utilization"] = 0.25
json.dump(cfg, open(p, "w"), indent=1)
print("gpu_mem_util ->", cfg["vllm"]["gpu_memory_utilization"])
EOF
grep -o '"address[^,]*' /workspace/manual_run/envs/train/*.json | head -2
cd /workspace/prime-rl
pkill -f "uv run" || true
sleep 3
setsid uv run inference @ /workspace/manual_run/inference.json > /workspace/manual_run/inference.log 2>&1 < /dev/null &
disown
for i in $(seq 1 40); do
  sleep 10
  if curl -s -m 5 http://localhost:8000/v1/models 2>/dev/null | grep -q Qwen; then echo "INFER READY"; break; fi
done
setsid uv run env-server @ /workspace/manual_run/envs/train/native-verify-seq.json > /workspace/manual_run/envserver.log 2>&1 < /dev/null &
disown
echo "env-server started"
sleep 8
CUDA_VISIBLE_DEVICES=0 setsid uv run trainer @ /workspace/manual_run/trainer.json > /workspace/manual_run/trainer.log 2>&1 < /dev/null &
disown
echo "trainer started"
sleep 10
setsid uv run orchestrator @ /workspace/manual_run/orchestrator.json > /workspace/manual_run/orchestrator.log 2>&1 < /dev/null &
disown
echo "orchestrator started"
