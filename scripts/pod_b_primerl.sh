set -e
export PATH="$HOME/.local/bin:$PATH"
cd /workspace
curl -LsSf https://astral.sh/uv/install.sh | sh > /tmp/uv_install.log 2>&1 || true
if [ ! -d prime-rl ]; then
  git clone -q https://github.com/PrimeIntellect-ai/prime-rl.git
fi
cd prime-rl
sed -i "s|git@github.com:|https://github.com/|" .gitmodules || true
git submodule update --init --recursive --force > /tmp/subm.log 2>&1 || git submodule update --init --recursive --force >> /tmp/subm.log 2>&1
test -f deps/pydantic-config/pyproject.toml || (git submodule update --force --recursive deps/pydantic-config)
test -f deps/prime-kernels/setup.py || (git submodule update --force --recursive deps/prime-kernels)
echo "submodules: $(ls deps/pydantic-config/pyproject.toml deps/prime-kernels/setup.py 2>&1 | wc -l)"
uv sync > /tmp/uvsync.log 2>&1
echo "sync rc=$?"
uv pip install -e /workspace/native-verify > /tmp/uvenv.log 2>&1
uv pip install -e /workspace/native-verify/environments/native_verify_seq >> /tmp/uvenv.log 2>&1
echo "env rc=$?"
MAX_JOBS=48 uv pip install --python .venv/bin/python --no-build-isolation flash-attn > /tmp/flashattn_build.log 2>&1
echo "flashattn rc=$?"
.venv/bin/python -c "import flash_attn; print('flash_attn OK')"
echo "PRIMERL_SETUP_COMPLETE"
