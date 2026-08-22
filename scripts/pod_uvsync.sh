export PATH="$HOME/.local/bin:$PATH"
cd /workspace/prime-rl
uv sync > /tmp/uvsync.log 2>&1
echo "sync rc=$?"
tail -3 /tmp/uvsync.log
uv pip install -e /workspace/native-verify > /tmp/uvenv.log 2>&1
uv pip install -e /workspace/native-verify/environments/native_verify_seq >> /tmp/uvenv.log 2>&1
echo "env install rc=$?"
uv run rl --help 2>&1 | head -4
