export PATH="$HOME/.local/bin:$PATH"
export UV_PROJECT_ENVIRONMENT=/tmp/prl_venv
cd /workspace/prime-rl
rm -rf .venv
uv sync > /tmp/uvsync2.log 2>&1
echo "sync rc=$?"
tail -2 /tmp/uvsync2.log
uv pip install -e /workspace/native-verify > /tmp/uvenv2.log 2>&1
uv pip install -e /workspace/native-verify/environments/native_verify_seq >> /tmp/uvenv2.log 2>&1
echo "env rc=$?"
/tmp/prl_venv/bin/python -m ensurepip --upgrade > /tmp/ensurepip.log 2>&1
echo "ensurepip rc=$?"
echo "PRIME_RL_SYNC_DONE"
