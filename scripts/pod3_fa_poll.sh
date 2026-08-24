for i in $(seq 1 55); do
  sleep 60
  if grep -qE "Successfully installed|ERROR" /tmp/fa_build.log 2>/dev/null; then
    break
  fi
done
grep -E "Successfully installed|ERROR" /tmp/fa_build.log | tail -1
/tmp/prl_venv/bin/python -c "import flash_attn, flash_attn_2_cuda; print('FA_CUDA_OK')" 2>&1 | tail -1
find /tmp -name "*.o" 2>/dev/null | wc -l
