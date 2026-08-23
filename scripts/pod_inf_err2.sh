D=/tmp/runs/nv-smoke/native-verify-seq--qwen2.5-1.5b-instruct--b9dd453b/logs/attempt_1
grep -iE 'error|failed|killed|oom' $D/inference.log | tail -5
tail -10 $D/inference.log
echo '===TRAINER==='
tail -6 $D/trainer.log
