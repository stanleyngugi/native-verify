export PATH="$HOME/.local/bin:$PATH"
export UV_OFFLINE=1
export PYTHONUNBUFFERED=1
export PRL_RUN_ID=$(cat /proc/sys/kernel/random/uuid | tr -d '-')
export NATIVE_VERIFY_LEAN=/workspace/lean-4.23.0-linux/bin/lean
export WANDB_MODE=disabled
timeout 60 uv run rl @ /workspace/grpo_smoke.toml --output-dir /tmp/dryrun2 --dry-run > /tmp/dry_off2.log 2>&1
echo rc:$?
cat /tmp/dry_off2.log
