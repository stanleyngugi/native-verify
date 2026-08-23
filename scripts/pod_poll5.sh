for i in 1 2 3 4 5; do
  sleep 60
  echo "=== try $i ==="
  cat /workspace/train.log 2>&1 | head -15
  ls /workspace/runs/nv-grpo-smoke/ 2>&1 | head -10
done
