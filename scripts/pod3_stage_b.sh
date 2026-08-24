set -e
export PATH="$HOME/.local/bin:$PATH"
echo "== uv =="
curl -LsSf https://astral.sh/uv/install.sh | sh > /tmp/uv_install.log 2>&1 || true
uv --version
echo "== clone =="
cd /workspace
if [ ! -d prime-rl ]; then
  git clone -q https://github.com/PrimeIntellect-ai/prime-rl.git
fi
cd prime-rl
sed -i "s|git@github.com:|https://github.com/|" .gitmodules || true
git submodule update --init --recursive --force > /tmp/subm.log 2>&1 || true
test -f deps/pydantic-config/pyproject.toml || git submodule update --force --recursive deps/pydantic-config >> /tmp/subm.log 2>&1
test -f deps/prime-kernels/setup.py || git submodule update --force --recursive deps/prime-kernels >> /tmp/subm.log 2>&1
ls deps/pydantic-config/pyproject.toml deps/prime-kernels/setup.py > /dev/null && echo "submodules OK"
echo "== sync =="
uv sync > /tmp/uvsync.log 2>&1
echo "sync rc=$?"
uv pip install -e /workspace/native-verify > /tmp/uvenv.log 2>&1
uv pip install -e /workspace/native-verify/environments/native_verify_seq >> /tmp/uvenv.log 2>&1
echo "env rc=$?"
.venv/bin/python -m ensurepip --upgrade > /tmp/ensurepip.log 2>&1
echo "ensurepip rc=$?"
echo "PRIME_RL_SYNC_DONE"
