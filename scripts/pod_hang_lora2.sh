cat > /tmp/hang_lora2.py << 'PY'
import faulthandler, signal, sys
faulthandler.enable()
faulthandler.register(signal.SIGUSR1)
print("start", flush=True)
import prime_rl.trainer.lora
print("import_ok", flush=True)
PY
/workspace/prime-rl/.venv/bin/python /tmp/hang_lora2.py > /tmp/hang2.log 2>&1 &
pid=$!
echo "pid $pid"
sleep 20
kill -USR1 $pid 2>/dev/null
sleep 3
cat /tmp/hang2.log
ps aux | grep $pid | grep -v grep | head -1
kill $pid 2>/dev/null; wait $pid 2>/dev/null; echo exit:$?
