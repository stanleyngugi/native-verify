export PYTHONUNBUFFERED=1
export PRL_RUN_ID=$(cat /proc/sys/kernel/random/uuid | tr -d '-')
export NATIVE_VERIFY_LEAN=/workspace/lean-4.23.0-linux/bin/lean
export WANDB_MODE=disabled
export HF_HUB_OFFLINE=1
timeout 90 /workspace/prime-rl/.venv/bin/rl @ /workspace/grpo_smoke.toml --output-dir /tmp/dryrun5 --dry-run > /tmp/dry5.log 2>&1
echo rc:$?
cat /tmp/dry5.log
ls /tmp/dryrun5/ 2>&1 | head -5
