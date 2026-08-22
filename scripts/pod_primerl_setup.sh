set -e
curl -LsSf https://astral.sh/uv/install.sh | sh > /tmp/uv_install.log 2>&1 || true
export PATH="$HOME/.local/bin:$PATH"
uv --version
cd /workspace
if [ ! -d prime-rl ]; then
  git clone --recursive https://github.com/PrimeIntellect-ai/prime-rl.git > /tmp/clone.log 2>&1
fi
cd prime-rl
uv sync > /tmp/uvsync.log 2>&1 || uv sync --frozen > /tmp/uvsync.log 2>&1
echo SYNC_OK
uv pip install -e /workspace/native-verify > /tmp/uvenv.log 2>&1
uv pip install -e /workspace/native-verify/environments/native_verify_seq >> /tmp/uvenv.log 2>&1
echo ENV_INSTALLED
uv run rl --help 2>&1 | head -5
