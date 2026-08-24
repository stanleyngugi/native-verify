import json, glob

rows = [json.loads(l) for l in open(glob.glob('/tmp/runs/nv-smoke/*/metrics.jsonl')[0])]
last = rows[-1]
m = last.get('metrics', last)
interesting = {k: round(v, 4) for k, v in m.items() if isinstance(v, (int, float)) and any(
    s in k for s in ('entropy', 'kl', 'grad_norm', 'episodes', 'num_episodes', 'seq_len')
)}
print('step:', last.get('step'))
for k in sorted(interesting):
    print(f'{k}: {interesting[k]}')

ckpt = glob.glob('/tmp/runs/nv-smoke/*/checkpoints*')
print('checkpoints:', ckpt)
w = glob.glob('/tmp/runs/nv-smoke/*/weights/*')
print('weights:', w)
