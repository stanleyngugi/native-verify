import json
import urllib.request

key = open("/root/.groq_key").read().strip()
print("keylen", len(key))
req = urllib.request.Request(
    "https://api.groq.com/openai/v1/chat/completions",
    data=json.dumps(
        {"model": "openai/gpt-oss-20b", "messages": [{"role": "user", "content": "say ok"}], "max_tokens": 5}
    ).encode(),
    headers={
        "Content-Type": "application/json",
        "Authorization": "Bearer " + key,
        "User-Agent": "native-verify/0.1",
    },
)
try:
    print(urllib.request.urlopen(req, timeout=30).read()[:120])
except Exception as exc:
    print("ERR", exc)
