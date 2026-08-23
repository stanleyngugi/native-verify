pkill -9 -f "prime_rl|rl @" 2>/dev/null; sleep 2
export PATH="$HOME/.local/bin:$PATH"
export PYTHONUNBUFFERED=1
export PRL_RUN_ID=$(cat /proc/sys/kernel/random/uuid | tr -d '-')
export NATIVE_VERIFY_LEAN=/workspace/lean-4.23.0-linux/bin/lean
export WANDB_MODE=disabled
export UV_OFFLINE=1
rm -rf /tmp/runs/nv-smoke
mkdir -p /tmp/runs
timeout 60 /workspace/prime-rl/.venv/bin/python -m prime_rl.entrypoints.rl @ /workspace/grpo_smoke.toml --output-dir /tmp/runs/nv-smoke --dry-run > /tmp/dry_tmp.log 2>&1
echo rc:$?
cat /tmp/dry_tmp.log
ls /tmp/runs/nv-smoke/ 2>&1 | head -5
