export PATH="/usr/local/cuda/bin:$HOME/.local/bin:$PATH"
export CUDA_HOME=/usr/local/cuda
export TORCH_CUDA_ARCH_LIST="8.9"
export MAX_JOBS=48
cd /workspace/prime-rl
.venv/bin/python -m ensurepip --upgrade > /tmp/ensurepip.log 2>&1
echo "ensurepip rc=$?"
nohup .venv/bin/python -m pip install --force-reinstall --no-deps --no-build-isolation --no-binary :all: flash-attn==2.8.3.post1 > /tmp/flashattn_build4.log 2>&1 &
echo "build pid $!"
sleep 300
grep -c "nvcc" /tmp/flashattn_build4.log
tail -2 /tmp/flashattn_build4.log
