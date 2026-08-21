f=$(ls -t /workspace/outputs/evals/native-verify-seq--Qwen--Qwen2.5-1.5B-Instruct/*/results*.jsonl 2>/dev/null | head -1)
echo "FILE: $f"
python3 - "$f" <<'EOF'
import json, sys
rows = [json.loads(l) for l in open(sys.argv[1])]
print("rows:", len(rows))
row = rows[0]
state = row.get("state") or {}
comp = row.get("completion") or state.get("completion")
if comp:
    msg = comp[-1] if isinstance(comp, list) else comp
    content = msg.get("content", "") if isinstance(msg, dict) else str(msg)
    print("COMPLETION:", repr(content[:600]))
print("reward:", row.get("reward"))
EOF
