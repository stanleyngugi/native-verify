export PATH="$HOME/.local/bin:$PATH"
export MAX_JOBS=64
nohup uv pip install --python /workspace/prime-rl/.venv/bin/python --no-build-isolation flash-attn > /tmp/flashattn_build.log 2>&1 &
echo "build started pid $!"
sleep 240
tail -3 /tmp/flashattn_build.log
/workspace/prime-rl/.venv/bin/python -c "import flash_attn; print('OK', flash_attn.__version__)" 2>&1 | tail -1
