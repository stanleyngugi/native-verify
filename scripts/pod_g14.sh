C=/workspace/runs/nv-grpo-smoke/native-verify-seq--qwen2.5-1.5b-instruct--1346e277/configs
python3 -c "
import json
inf = json.load(open('$C/inference.json'))
print('vllm cfg:', json.dumps(inf['vllm'], indent=1)[:500])
orch = json.load(open('$C/orchestrator.json'))
print('orch top keys:', list(orch.keys()))
print('train source:', json.dumps(orch.get('train', {}))[:200])
"
