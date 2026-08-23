C=/workspace/runs/nv-grpo-smoke/native-verify-seq--qwen2.5-1.5b-instruct--1346e277/configs
grep -oE '"(server|host|port|address)[^,}]*' $C/inference.json | head -4
grep -oE '"(server|host|port|address)[^,}]*' $C/orchestrator.json | head -6
python3 -c "
import json
inf = json.load(open('$C/inference.json'))
print('infer keys:', list(inf.keys()))
dep = inf.get('deployment') or {}
print('infer deployment:', dep)
"
