D=$(ls -d /tmp/runs/nv-smoke/*/logs/attempt_1 | head -1)
grep -E "ValueError|Available KV|ERROR.*core" $D/inference.log | tail -6
