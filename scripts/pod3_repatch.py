import pathlib
p = pathlib.Path('/workspace/prime-rl/src/prime_rl/entrypoints/rl.py')
src = pathlib.Path('/workspace/native-verify/patches/prime-rl/rl.py')
p.write_text(src.read_text())
print('base colocated patch restored:', 'colocated mode' in p.read_text())

t = p.read_text()
anchor = '''        logger.info(f"Starting trainer on GPU(s) {' '.join(map(str, trainer_gpu_ids))}")'''
replacement = '''        logger.info("Colocated: waiting 300s for inference to stabilize")
        time.sleep(300)
''' + anchor
if t.count(anchor) == 1:
    p.write_text(t.replace(anchor, replacement))
    print('sleep inserted correctly')
else:
    print('anchor count:', t.count(anchor))
