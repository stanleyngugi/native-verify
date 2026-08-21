import json
import sys

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

rows = [json.loads(l) for l in open("artifacts/baseline_gptoss20b_s1.jsonl", encoding="utf-8")]
for row in rows:
    art = row.get("artifact")
    if art and row["stage"] == "sanitize" and "signature" in str(row.get("reason")):
        print("===", row["task_id"])
        print(art[:300])
        print()
