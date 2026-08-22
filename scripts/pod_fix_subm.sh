cd /workspace/prime-rl
git submodule update --init deps/pydantic-config deps/prime-kernels 2>&1 | tail -3
ls deps/pydantic-config/ | head -3
export PATH="$HOME/.local/bin:$PATH"
uv sync > /tmp/uvsync.log 2>&1
echo "sync rc=$?"
tail -2 /tmp/uvsync.log
