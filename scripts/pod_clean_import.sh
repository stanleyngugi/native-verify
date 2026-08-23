pkill -9 -f "uv run" 2>/dev/null; sleep 2
rm -f /tmp/.uv*lock 2>/dev/null; echo cleaned
export UV_OFFLINE=1
timeout 90 /workspace/prime-rl/.venv/bin/python -c 'import prime_rl.configs.rl; print("import_ok")' 2>&1
echo rc:$?
timeout 30 /workspace/prime-rl/.venv/bin/python -m prime_rl.entrypoints.rl --help 2>&1 | head -3
echo help_rc:$?
