import pathlib
p = pathlib.Path('/workspace/prime-rl/src/prime_rl/utils/cp.py')
t = p.read_text()
old = 'from ring_flash_attn import update_ring_flash_attn_params'
new = 'try:\n    from ring_flash_attn import update_ring_flash_attn_params\nexcept ImportError:\n    update_ring_flash_attn_params = lambda *a, **k: None'
if old in t:
    p.write_text(t.replace(old, new))
    print('patched cp.py')
else:
    print('not found')
