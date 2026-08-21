import json
import subprocess
import sys

out = subprocess.run(
    [sys.executable, "examples/demo_attacks.py"],
    capture_output=True,
    text=True,
).stdout
data = json.loads(out)
print(
    f"lean={data['lean_available']} total={data['attacks_total']} "
    f"rejected={data['attacks_rejected']} accepted={data['attacks_accepted']}"
)
for r in data["results"]:
    reason = str(r.get("reason"))[:70]
    print(f"{r['name']:24} rejected={r['rejected']} stage={r['stage']:14} {reason}")
