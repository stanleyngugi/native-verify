export PATH="$HOME/.local/bin:$PATH"
python3 - <<'EOF'
import json
p = "/workspace/manual_run/inference.json"
cfg = json.load(open(p))
cfg["router"] = None
json.dump(cfg, open(p, "w"), indent=1)
print("router ->", cfg["router"])
EOF
cd /workspace/prime-rl
setsid uv run inference @ /workspace/manual_run/inference.json > /workspace/manual_run/inference.log 2>&1 < /dev/null &
disown
for i in $(seq 1 40); do
  sleep 10
  if curl -s -m 5 http://localhost:8000/v1/models 2>/dev/null | grep -q Qwen; then echo "INFER READY"; break; fi
done
pgrep -f "env-server|trainer|orchestrator|Inference" | wc -l
