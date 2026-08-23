cat > /tmp/hang.py << 'PY'
import time, threading, faulthandler, signal, os, sys
faulthandler.enable()
faulthandler.register(signal.SIGUSR1)
print("start", flush=True)
import prime_rl.entrypoints.rl
print("import_ok", flush=True)
PY
timeout 40 /workspace/prime-rl/.venv/bin/python /tmp/hang.py 2>&1 &
pid=$!
sleep 12
kill -USR1 $pid 2>/dev/null; sleep 2; cat /proc/$pid/stack 2>/dev/null | head -20
wait $pid 2>/dev/null; echo exit:$?
