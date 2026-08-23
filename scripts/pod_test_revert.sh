sed -i '/^router = "None"/d' /workspace/grpo_smoke.toml
cat /workspace/grpo_smoke.toml | grep -A2 "^\[inference"
timeout 30 /workspace/prime-rl/.venv/bin/python -m prime_rl.entrypoints.rl @ /workspace/grpo_smoke.toml --output-dir /tmp/dryrun4 --dry-run > /tmp/dry4.log 2>&1 &
pid=$!
sleep 12
cat /tmp/dry4.log 2>&1 | head -15
ps aux | grep $pid | grep -v grep | head -1
wait $pid 2>/dev/null
echo rc:$?
cat /tmp/dry4.log 2>&1 | head -20
ls /tmp/dryrun4/ 2>&1 | head -5
