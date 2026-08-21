import json
import sys

import urllib.request

sys.path.insert(0, "/workspace/native-verify/src")
from native_verify.tasks import generate_tasks

task = generate_tasks(families=["linear"], per_family=1, seed=0)[0]
payload = {
    "model": "Qwen/Qwen2.5-1.5B-Instruct",
    "messages": [
        {"role": "system", "content": "You are an expert Lean 4 programmer. Respond with exactly one ```lean code block containing `def f (n : Nat) : Nat` plus optional helper defs. No imports, no attributes, no theorems. ASCII only."},
        {"role": "user", "content": task.prompt},
    ],
    "temperature": 0.9,
    "max_tokens": 700,
}
req = urllib.request.Request(
    "http://localhost:8000/v1/chat/completions",
    data=json.dumps(payload).encode(),
    headers={"Content-Type": "application/json"},
)
body = json.loads(urllib.request.urlopen(req, timeout=120).read())
content = body["choices"][0]["message"]["content"]
print("COMPLETION:")
print(content[:800])
print("----")
from native_verify import verify
from native_verify.canonical import canonicalize_unicode
from native_verify.extract import extract_artifact

artifact = extract_artifact(content)
print("artifact:", repr(artifact[:200]) if artifact else None)
if artifact:
    v = verify(canonicalize_unicode(artifact), task.train_values, task.holdout_values)
    print("verdict:", v.accepted, v.stage, v.reason, v.diagnostics[:2])
