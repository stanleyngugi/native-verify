export PATH="/usr/local/cuda/bin:$HOME/.local/bin:$PATH"
export CUDA_HOME=/usr/local/cuda
export TORCH_CUDA_ARCH_LIST="8.9"
export FLASH_ATTENTION_FORCE_BUILD=1
export MAX_JOBS=2
export NVCC_THREADS=1
cd /workspace/prime-rl
setsid .venv/bin/python -m pip install --force-reinstall --no-deps --no-build-isolation --no-binary :all: flash-attn==2.8.3.post1 > /tmp/flashattn_build6.log 2>&1 < /dev/null &
disown
echo "detached low-mem build pid $!"
