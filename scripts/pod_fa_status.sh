tail -3 /tmp/flashattn_build.log
/workspace/prime-rl/.venv/bin/python -c "import flash_attn; print('OK', flash_attn.__version__)" 2>&1 | tail -1
pgrep -f flash_attn | wc -l
