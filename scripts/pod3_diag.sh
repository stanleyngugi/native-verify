D=$(ls -d /tmp/runs/nv-smoke/*/logs/attempt_* | head -1)
echo "==ENV=="
tail -12 $D/envs/train/native-verify-seq.log
echo "==INF requests=="
grep -ciE "POST /v1" $D/inference.log 2>/dev/null
tail -4 $D/inference.log
echo "==ORCH rollout detail=="
grep -iE "rollout|completion|empty|error" $D/orchestrator.log | tail -8
