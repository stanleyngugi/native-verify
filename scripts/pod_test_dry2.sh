export PATH="$HOME/.local/bin:$PATH"
export PYTHONUNBUFFERED=1
export PRL_RUN_ID=$(cat /proc/sys/kernel/random/uuid | tr -d '-')
export NATIVE_VERIFY_LEAN=/workspace/lean-4.23.0-linux/bin/lean
export WANDB_MODE=disabled
export WANDB_DISABLED=true
cd /workspace/prime-rl
timeout 30 uv run rl @ /workspace/grpo_smoke.toml --output-dir /tmp/dryrun2 --dry-run > /tmp/dry2.log 2>&1
echo dryrun_rc=$?
tail -5 /tmp/dry2.log
