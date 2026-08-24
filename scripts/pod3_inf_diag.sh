D=$(ls -d /tmp/runs/nv-smoke/*/logs/attempt_1 | head -1)
grep -iE "error|Traceback|raise|Exception" $D/inference.log | head -10
echo "===tail==="
tail -20 $D/inference.log
