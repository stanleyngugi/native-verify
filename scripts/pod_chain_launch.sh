export PATH="$HOME/.local/bin:$PATH"
for i in $(seq 1 40); do
  sleep 60
  if grep -qE "Successfully installed|ERROR" /tmp/flashattn_build6.log 2>/dev/null; then
    break
  fi
done
grep -E "Successfully installed|ERROR" /tmp/flashattn_build6.log | tail -1
cd /workspace/prime-rl
if .venv/bin/python -c "import flash_attn, flash_attn_2_cuda" 2>/dev/null; then
  echo "FLASH_ATTN_OK"
  pkill -f vllm.entrypoints || true
  sleep 10
  setsid uv run rl @ /workspace/grpo_smoke.toml --output-dir /workspace/runs/nv-grpo-smoke > /workspace/train_launch.log 2>&1 < /dev/null &
  disown
  echo "TRAINING_LAUNCHED"
else
  echo "FLASH_ATTN_FAILED - NOT LAUNCHING"
fi
