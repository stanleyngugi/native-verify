set -e
echo "== lean =="
apt-get update -qq > /dev/null 2>&1 || true
apt-get install -y -qq zstd > /dev/null 2>&1 || true
cd /workspace
if [ ! -x lean-4.23.0-linux/bin/lean ]; then
  curl -sL -o lean.tar.zst https://github.com/leanprover/lean4/releases/download/v4.23.0/lean-4.23.0-linux.tar.zst
  tar --zstd -xf lean.tar.zst
  rm -f lean.tar.zst
fi
./lean-4.23.0-linux/bin/lean --version
echo "== repo =="
rm -rf native-verify
git clone -q https://github.com/stanleyngugi/native-verify.git
cd native-verify
pip install -q . verifiers pytest 2>&1 | tail -1 || true
export NATIVE_VERIFY_LEAN=/workspace/lean-4.23.0-linux/bin/lean
python3 scripts/smoke_env.py 2>&1 | grep -E "smoke|reward=" 
echo "== vllm =="
pip install -q vllm 2>&1 | tail -1
python3 -c "import flashinfer; print('flashinfer', flashinfer.__version__)" 2>/dev/null || echo "no flashinfer"
pip show flashinfer-python 2>/dev/null | grep Version || true
