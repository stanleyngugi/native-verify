import pathlib
p = pathlib.Path('/workspace/prime-rl/src/prime_rl/entrypoints/rl.py')
t = p.read_text()
anchor = 'logger.info(f"Starting trainer on GPU(s) {\' \'.join(map(str, trainer_gpu_ids))}")'
if anchor in t:
    t = t.replace(
        '    logger.info(f"Starting trainer on GPU(s) {\' \'.join(map(str, trainer_gpu_ids))}")',
        '    logger.info("Colocated mode: waiting 300s for inference to stabilize before trainer")\n'
        '    time.sleep(300)\n'
        '    logger.info(f"Starting trainer on GPU(s) {\' \'.join(map(str, trainer_gpu_ids))}")',
    )
    p.write_text(t)
    print('sleep patch applied')
else:
    print('anchor not found')
