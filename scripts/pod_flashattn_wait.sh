for i in $(seq 1 55); do
  sleep 60
  if grep -qE "Installed|error|Error" /tmp/flashattn_build.log 2>/dev/null; then
    break
  fi
done
tail -3 /tmp/flashattn_build.log
/workspace/prime-rl/.venv/bin/python -c "import flash_attn; print('OK', flash_attn.__version__)" 2>&1 | tail -1
