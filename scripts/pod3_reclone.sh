set -e
export PATH="$HOME/.local/bin:$PATH"
export UV_PROJECT_ENVIRONMENT=/tmp/prl_venv
cd /workspace
rm -rf prime-rl
git clone -q https://github.com/PrimeIntellect-ai/prime-rl.git
cd prime-rl
sed -i "s|git@github.com:|https://github.com/|" .gitmodules
git submodule update --init --recursive --force > /tmp/subm2.log 2>&1 || true
test -f deps/pydantic-config/pyproject.toml || git submodule update --force --recursive deps/pydantic-config >> /tmp/subm2.log 2>&1
test -f deps/prime-kernels/setup.py || git submodule update --force --recursive deps/prime-kernels >> /tmp/subm2.log 2>&1
ls packages/ 2>/dev/null | head -3 || echo "no packages dir"
uv sync > /tmp/uvsync3.log 2>&1
echo "sync rc=$?"
tail -2 /tmp/uvsync3.log
uv pip install -e /workspace/native-verify >> /tmp/uvsync3.log 2>&1
uv pip install -e /workspace/native-verify/environments/native_verify_seq >> /tmp/uvsync3.log 2>&1
echo "env rc=$?"
/tmp/prl_venv/bin/python -c "import prime_rl.entrypoints.rl; print('import ok')" 2>&1 | tail -1 || echo "(slow import, will verify later)"
echo "STAGE_B_DONE"
