export PYTHONUNBUFFERED=1
export PRL_RUN_ID=$(cat /proc/sys/kernel/random/uuid | tr -d '-')
export NATIVE_VERIFY_LEAN=/workspace/lean-4.23.0-linux/bin/lean
export WANDB_MODE=disabled
timeout 60 /workspace/prime-rl/.venv/bin/python -m prime_rl.entrypoints.rl @ /workspace/grpo_smoke.toml --output-dir /tmp/dryrun4 --dry-run > /tmp/dry4.log 2>&1
echo rc:$?
cat /tmp/dry4.log
