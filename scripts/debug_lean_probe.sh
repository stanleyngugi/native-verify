import os
import subprocess
import sys

print("env var:", repr(os.getenv("NATIVE_VERIFY_LEAN")))
exe = "/workspace/lean-4.23.0-linux/bin/lean"
r = subprocess.run([exe, "--version"], capture_output=True, text=True, timeout=20)
print("direct probe rc:", r.returncode, r.stdout.strip()[:50])

sys.path.insert(0, "/workspace/native-verify/src")
from native_verify import locate_lean

backend = locate_lean()
print("locate_lean:", backend)
