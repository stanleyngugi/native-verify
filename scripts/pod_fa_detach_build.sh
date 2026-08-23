export PATH="/usr/local/cuda/bin:$HOME/.local/bin:$PATH"
export CUDA_HOME=/usr/local/cuda
export TORCH_CUDA_ARCH_LIST="8.9"
export MAX_JOBS=40
cd /workspace/prime-rl
setsid .venv/bin/python -m pip install --force-reinstall --no-deps --no-build-isolation --no-binary :all: flash-attn==2.8.3.post1 > /tmp/flashattn_build5.log 2>&1 < /dev/null &
disown
echo "detached build pid $!"
