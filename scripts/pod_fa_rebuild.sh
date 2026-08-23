ls /usr/local/cuda/bin/nvcc 2>/dev/null && echo "toolkit nvcc found"
export PATH="/usr/local/cuda/bin:$HOME/.local/bin:$PATH"
export CUDA_HOME=/usr/local/cuda
export TORCH_CUDA_ARCH_LIST="8.9"
export MAX_JOBS=48
nvcc --version 2>/dev/null | tail -1
cd /workspace/prime-rl
nohup uv pip install --python .venv/bin/python --no-build-isolation --reinstall-package flash-attn flash-attn > /tmp/flashattn_build2.log 2>&1 &
echo "rebuild launched pid $!"
