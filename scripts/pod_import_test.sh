timeout 60 /workspace/prime-rl/.venv/bin/python -c 'import time; s=time.time(); import prime_rl.entrypoints.rl; print("import_ok", time.time()-s)' 2>&1
echo exit:$?
