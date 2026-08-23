export PATH="$HOME/.local/bin:$PATH"
export NATIVE_VERIFY_LEAN=/workspace/lean-4.23.0-linux/bin/lean
cd /workspace/prime-rl
pgrep -f "env-server" | wc -l
C=/workspace/manual_run
setsid uv run orchestrator @ $C/orchestrator.json > /workspace/manual_run/orchestrator.log 2>&1 < /dev/null &
disown
RDZV_PORT=$(python3 -c "import socket; s=socket.socket(); s.bind(('localhost',0)); print(s.getsockname()[1]); s.close()")
setsid .venv/bin/torchrun --role=trainer --rdzv-endpoint=localhost:$RDZV_PORT --rdzv-id=nvsmoke$RANDOM --nproc-per-node=1 -m prime_rl.trainer.rl.train @ $C/trainer.json > /workspace/manual_run/trainer.log 2>&1 < /dev/null &
disown
echo "orchestrator + trainer relaunched"
sleep 60
tail -3 /workspace/manual_run/orchestrator.log
echo ===
tail -3 /workspace/manual_run/trainer.log
