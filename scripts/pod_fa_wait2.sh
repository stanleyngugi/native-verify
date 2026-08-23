for i in $(seq 1 60); do
  sleep 60
  if grep -qE "Successfully installed|ERROR|error:" /tmp/flashattn_build4.log 2>/dev/null; then
    break
  fi
done
grep -E "Successfully installed|error" /tmp/flashattn_build4.log | tail -2
cd /workspace/prime-rl && .venv/bin/python -c "import flash_attn, flash_attn_2_cuda; print('FLASH_ATTN CUDA OK', flash_attn.__version__)" 2>&1 | tail -1
