set -e
echo "== lean =="
apt-get update -qq > /dev/null 2>&1 || true
apt-get install -y -qq zstd > /dev/null 2>&1 || true
cd /workspace
if [ ! -x lean-4.23.0-linux/bin/lean ]; then
  curl -sL -o lean.tar.zst https://github.com/leanprover/lean4/releases/download/v4.23.0/lean-4.23.0-linux.tar.zst
  tar --zstd -xf lean.tar.zst --no-same-owner
  rm -f lean.tar.zst
fi
./lean-4.23.0-linux/bin/lean --version
echo "== repo =="
rm -rf native-verify
git clone -q https://github.com/stanleyngugi/native-verify.git
cd native-verify
pip install -q . verifiers pytest > /tmp/pip1.log 2>&1
export NATIVE_VERIFY_LEAN=/workspace/lean-4.23.0-linux/bin/lean
python3 scripts/smoke_env.py 2>/dev/null | grep -E "smoke passed|reward="
echo "== vllm =="
pip install -q vllm > /tmp/pipvllm.log 2>&1
pip show flashinfer-python 2>/dev/null | grep Version
pip install -q -U flashinfer-python > /tmp/pipfi.log 2>&1
python3 -c "import flashinfer.comm; print('flashinfer OK')"
echo "STAGE_A_DONE"
