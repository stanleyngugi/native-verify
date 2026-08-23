export PATH="/usr/local/cuda/bin:$HOME/.local/bin:$PATH"
export CUDA_HOME=/usr/local/cuda
export TORCH_CUDA_ARCH_LIST="8.9"
export MAX_JOBS=48
cd /workspace/prime-rl
uv cache clean flash-attn 2>&1 | tail -1
nohup uv pip install --python .venv/bin/python --no-build-isolation --no-cache --reinstall-package flash-attn flash-attn > /tmp/flashattn_build3.log 2>&1 &
echo "true rebuild launched pid $!"
sleep 120
tail -4 /tmp/flashattn_build3.log
