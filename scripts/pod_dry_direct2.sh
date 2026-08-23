export PRL_RUN_ID=$(cat /proc/sys/kernel/random/uuid | tr -d '-')
export NATIVE_VERIFY_LEAN=/workspace/lean-4.23.0-linux/bin/lean
export WANDB_MODE=disabled
export PYTHONUNBUFFERED=1
timeout 60 /workspace/prime-rl/.venv/bin/rl @ /workspace/grpo_smoke.toml --output-dir /tmp/dryrun3 --dry-run > /tmp/dry3.log 2>&1
echo rc:$?
cat /tmp/dry3.log
ls /tmp/dryrun3/ 2>&1 | head -5
