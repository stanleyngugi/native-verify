import pathlib

# Patch train.py: make ring_flash_attn import optional (single GPU never uses ring attention)
p = pathlib.Path('/workspace/prime-rl/src/prime_rl/trainer/rl/train.py')
t = p.read_text()
old = 'from ring_flash_attn import substitute_hf_flash_attn'
new = 'try:\n    from ring_flash_attn import substitute_hf_flash_attn\nexcept ImportError:\n    substitute_hf_flash_attn = None'
count = t.count(old)
t = t.replace(old, new)
p.write_text(t)
print(f'patched {count} occurrences in train.py')

# Check other files importing it
import subprocess
r = subprocess.run(['grep', '-rln', 'ring_flash_attn', '/workspace/prime-rl/src/'], capture_output=True, text=True)
print(r.stdout)
