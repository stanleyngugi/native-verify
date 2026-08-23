export PATH="$HOME/.local/bin:$PATH"
export PYTHONUNBUFFERED=1
export PRL_RUN_ID=$(cat /proc/sys/kernel/random/uuid | tr -d '-')
export NATIVE_VERIFY_LEAN=/workspace/lean-4.23.0-linux/bin/lean
export WANDB_MODE=disabled
export UV_OFFLINE=1
cd /workspace/prime-rl
timeout 60 uv run rl @ /workspace/grpo_smoke.toml --output-dir /tmp/dryrun --dry-run > /tmp/dry_off.log 2>&1
echo rc=$?
cat /tmp/dry_off.log
