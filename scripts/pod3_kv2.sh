D=$(ls -d /tmp/runs/nv-smoke/*/logs/attempt_1 | head -1)
grep -E "Error|error|KV|GiB" $D/inference.log | tail -8
