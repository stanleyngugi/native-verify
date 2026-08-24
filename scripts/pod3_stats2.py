import json, glob

rows = [json.loads(l) for l in open(glob.glob('/tmp/runs/nv-smoke/*/metrics.jsonl')[0])]
last = rows[-1]
m = last.get('metrics', last)
keys = [k for k in m.keys() if isinstance(m[k], (int, float))]
print('total metric keys:', len(keys))
for k in sorted(keys):
    lk = k.lower()
    if any(s in lk for s in ('entropy', 'kl', 'grad', 'reward', 'episode', 'seq_len', 'error')):
        print(f'{k}: {round(m[k], 4)}')
