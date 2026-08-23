cat > /tmp/hang3.py << 'PY'
import faulthandler, signal, sys
faulthandler.enable()
faulthandler.register(signal.SIGUSR1)
print("start", flush=True)
from prime_rl.entrypoints.rl import cli, RLConfig
print("imported", flush=True)
cfg = cli(RLConfig)
print("cli done", flush=True)
PY
timeout 30 /workspace/prime-rl/.venv/bin/python /tmp/hang3.py @ /workspace/grpo_smoke.toml --output-dir /tmp/dryrun4 --dry-run > /tmp/hang3.log 2>&1 &
pid=$!
sleep 12
kill -USR1 $pid 2>/dev/null
sleep 2
cat /tmp/hang3.log
wait $pid 2>/dev/null; echo exit:$?
