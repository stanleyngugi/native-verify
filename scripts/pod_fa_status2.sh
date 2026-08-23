tail -2 /tmp/flashattn_build4.log
cd /workspace/prime-rl && .venv/bin/python -c "import flash_attn, flash_attn_2_cuda; print('FLASH_ATTN CUDA OK', flash_attn.__version__)" 2>&1 | tail -1
pgrep -f "pip install" | wc -l
