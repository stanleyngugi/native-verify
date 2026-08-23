export PATH="$HOME/.local/bin:$PATH"
python3 - <<'EOF'
import json
p = "/workspace/manual_run/inference.json"
cfg = json.load(open(p))
cfg["vllm"]["gpu_memory_utilization"] = 0.35
cfg["vllm"]["max_model_len"] = 2048
cfg["vllm"]["enforce_eager"] = True
json.dump(cfg, open(p, "w"), indent=1)
print("util:", cfg["vllm"]["gpu_memory_utilization"], "len:", cfg["vllm"]["max_model_len"], "eager:", cfg["vllm"]["enforce_eager"])
EOF
cd /workspace/prime-rl
setsid uv run inference @ /workspace/manual_run/inference.json > /workspace/manual_run/inference.log 2>&1 < /dev/null &
disown
for i in $(seq 1 50); do
  sleep 15
  if curl -s -m 5 http://localhost:8000/v1/models 2>/dev/null | grep -q Qwen; then echo "INFER_READY"; break; fi
done
grep -iE "error|Available KV" /workspace/manual_run/inference.log | tail -2
