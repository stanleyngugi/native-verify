D=/tmp/runs/nv-smoke/native-verify-seq--qwen2.5-1.5b-instruct--b9dd453b/logs/attempt_1
STDERR=$(find $D/trainer -name 'stderr.log' | head -1)
tail -25 "$STDERR"
