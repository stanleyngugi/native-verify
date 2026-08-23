cat > /tmp/fix_toml.py << 'PY'
import pathlib
p = pathlib.Path('/workspace/grpo_smoke.toml')
t = p.read_text()
if 'router = "None"' not in t:
    t = t.replace('[inference]\n', '[inference]\nrouter = "None"\n')
    p.write_text(t)
    print('added router')
else:
    print('router already there')
# ensure HF offline in env_vars
if 'HF_HUB_OFFLINE' not in t:
    t = p.read_text()
    t = t.replace('[env_vars]\n', '[env_vars]\nHF_HUB_OFFLINE = "1"\n')
    p.write_text(t)
    print('added HF offline')
print(open('/workspace/grpo_smoke.toml').read().split('[inference]')[1].split('\n\n')[0])
PY
python3 /tmp/fix_toml.py
cat /workspace/grpo_smoke.toml | grep -A2 "^\[inference"
