for i in $(seq 1 70); do
  sleep 60
  if grep -qE "Installed|Prepared|uninstalled" /tmp/flashattn_build2.log 2>/dev/null; then
    echo "BUILD FINISHED:"; tail -2 /tmp/flashattn_build2.log
    break
  fi
done
cd /workspace/prime-rl
.venv/bin/python -c "import flash_attn; import flash_attn_2_cuda; print('flash_attn CUDA OK', flash_attn.__version__)" 2>&1 | tail -1
