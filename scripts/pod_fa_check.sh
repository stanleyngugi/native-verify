tail -c 400 /tmp/flashattn_build4.log
echo ""
cd /workspace/prime-rl && .venv/bin/python -c "import flash_attn, flash_attn_2_cuda; print('FLASH_ATTN_CUDA_OK', flash_attn.__version__)" 2>&1 | tail -1
pgrep -f "pip install" | head -2 | wc -l
