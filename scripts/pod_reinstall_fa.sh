export PATH="$HOME/.local/bin:$PATH"
export UV_OFFLINE=1
cd /workspace/prime-rl
uv pip install flash-attn 2>&1 | tail -5
.venv/bin/python -c 'import flash_attn; print("ok")' 2>&1 | head -2
