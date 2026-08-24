export PATH="$HOME/.local/bin:$PATH"
export VIRTUAL_ENV=/tmp/prl_venv
echo "== apply patches =="
cp /workspace/native-verify/patches/prime-rl/rl.py /workspace/prime-rl/src/prime_rl/entrypoints/rl.py
cp /workspace/native-verify/patches/prime-rl/cp.py /workspace/prime-rl/src/prime_rl/utils/cp.py
cp /workspace/native-verify/patches/prime-rl/train.py /workspace/prime-rl/src/prime_rl/trainer/rl/train.py
grep -c "colocated" /workspace/prime-rl/src/prime_rl/entrypoints/rl.py
grep -c "except ImportError" /workspace/prime-rl/src/prime_rl/utils/cp.py
grep -c "substitute_hf_flash_attn = None" /workspace/prime-rl/src/prime_rl/trainer/rl/train.py
echo "== flash-attn build =="
export CUDA_HOME=/usr/local/cuda
export TORCH_CUDA_ARCH_LIST="8.9"
export FLASH_ATTENTION_FORCE_BUILD=1
export MAX_JOBS=2
export NVCC_THREADS=1
cd /workspace/prime-rl
setsid /tmp/prl_venv/bin/python -m pip install --force-reinstall --no-deps --no-build-isolation --no-binary :all: flash-attn==2.8.3.post1 > /tmp/fa_build.log 2>&1 < /dev/null &
disown
echo "build detached pid $!"
