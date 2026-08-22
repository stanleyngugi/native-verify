echo "=== processes ==="
pgrep -f "rl @|inference|trainer" | wc -l
echo "=== launch log tail ==="
tail -5 /workspace/train_launch.log
echo "=== logs dir ==="
ls /workspace/runs/nv-grpo-smoke/logs/ 2>/dev/null
for f in orchestrator inference trainer; do
  echo "=== $f ==="
  tail -4 "/workspace/runs/nv-grpo-smoke/logs/$f.log" 2>/dev/null || echo "(no log yet)"
done
echo "=== env logs ==="
tail -6 /workspace/runs/nv-grpo-smoke/logs/envs/train/*.log 2>/dev/null | head -20
