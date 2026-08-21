set -e
cd /workspace/native-verify
pip install -q . 'verifiers>=0.1.8' pytest 2>&1 | tail -2 || true
python3 -c 'import verifiers, native_verify; print("imports OK, verifiers", verifiers.__version__)'
export NATIVE_VERIFY_LEAN=/workspace/lean-4.23.0-linux/bin/lean
python scripts/smoke_env.py 2>&1 | grep -v "examples/s"
