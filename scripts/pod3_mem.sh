D=$(ls -d /tmp/runs/nv-smoke/*/logs/attempt_1 | head -1)
grep -E "memory|Memory|GiB|GiB" $D/inference.log | tail -12
echo "===vllm cfg keys==="
python3 -c "
import json
cfg = json.load(open('$D'.replace('/logs/attempt_1','') + '/configs/inference.json'))
print(sorted(cfg['vllm'].keys()))
"
