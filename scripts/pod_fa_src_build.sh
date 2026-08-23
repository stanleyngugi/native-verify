export PATH="/usr/local/cuda/bin:$HOME/.local/bin:$PATH"
export CUDA_HOME=/usr/local/cuda
export TORCH_CUDA_ARCH_LIST="8.9"
export MAX_JOBS=48
cd /workspace/prime-rl
ls .venv/bin/ | grep -E "^pip|^python" | head -4
nohup .venv/bin/python -m pip install --force-reinstall --no-deps --no-build-isolation --no-binary :all: flash-attn==2.8.3.post1 > /tmp/flashattn_build4.log 2>&1 &
echo "source build pid $!"
sleep 240
grep -icE "nvcc" /tmp/flashattn_build4.log
tail -3 /tmp/flashattn_build4.log
