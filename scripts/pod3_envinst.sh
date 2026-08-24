export PATH="$HOME/.local/bin:$PATH"
export VIRTUAL_ENV=/tmp/prl_venv
uv pip install --python /tmp/prl_venv/bin/python -e /workspace/native-verify > /tmp/uv2.log 2>&1
echo "nv rc=$?"
uv pip install --python /tmp/prl_venv/bin/python -e /workspace/native-verify/environments/native_verify_seq >> /tmp/uv2.log 2>&1
echo "env rc=$?"
/tmp/prl_venv/bin/python -m ensurepip --upgrade > /tmp/ensurepip2.log 2>&1
echo "ensurepip rc=$?"
