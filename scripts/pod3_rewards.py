import json

path = None
import glob
candidates = glob.glob('/tmp/runs/nv-smoke/*/metrics.jsonl')
path = candidates[0]
rows = [json.loads(l) for l in open(path)]
print('metric rows:', len(rows))

rewards = []
for r in rows:
    step = r.get('step')
    m = r.get('metrics', r)
    for k, v in m.items():
        if 'reward' in k.lower() and isinstance(v, (int, float)) and '/mean' in k:
            rewards.append((step, k, round(v, 4)))
            break

for item in rewards[-40:]:
    print(item)

vals = [v for _, k, v in rewards if 'all' in k or len(rewards) < 5]
if vals:
    n = len(vals)
    first_q = sum(vals[: max(1, n // 4)]) / max(1, n // 4)
    last_q = sum(vals[-(n // 4) :]) / max(1, n // 4)
    print(f'first-quarter mean: {first_q:.4f}  last-quarter mean: {last_q:.4f}')
