import json, glob

rows = [json.loads(l) for l in open(glob.glob('/tmp/runs/nv-smoke/*/metrics.jsonl')[0])]
last = rows[-1]
print('row keys:', list(last.keys()))
m = last.get('metrics', {})
print('metrics sample:')
for k in sorted(m.keys())[:20]:
    print(' ', k, '=', m[k])
