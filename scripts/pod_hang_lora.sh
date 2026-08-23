cat > /tmp/hang_lora.py << 'PY'
import faulthandler, signal, sys
faulthandler.enable()
faulthandler.register(signal.SIGUSR1)
print("start", flush=True)
import prime_rl.trainer.lora
print("import_ok", flush=True)
PY
timeout 40 /workspace/prime-rl/.venv/bin/python /tmp/hang_lora.py > /tmp/hang_lora.log 2>&1 &
pid=$!
sleep 15
kill -USR1 $pid 2>/dev/null
sleep 2
cat /tmp/hang_lora.log
wait $pid 2>/dev/null; echo exit:$?
