import pathlib
p = pathlib.Path('/workspace/prime-rl/src/prime_rl/entrypoints/rl.py')
t = p.read_text()
old = '    physical_gpu_ids = get_physical_gpu_ids()\n    if total_requested_gpus > len(physical_gpu_ids):\n        raise ValueError(\n            f"Requested {total_requested_gpus} GPUs via deployment settings, but only "\n            f"{len(physical_gpu_ids)} physical GPU(s) are available: {physical_gpu_ids}"\n        )\n    physical_gpu_mapping = {local_id: physical_gpu_ids[local_id] for local_id in range(total_requested_gpus)}'
new = '    physical_gpu_ids = get_physical_gpu_ids()\n    if total_requested_gpus > len(physical_gpu_ids):\n        if total_requested_gpus == 2 and len(physical_gpu_ids) == 1:\n            import logging as _lg\n            _lg.getLogger(__name__).warning("Single-GPU colocated mode: sharing GPU 0 for inference+trainer")\n            physical_gpu_mapping = {0: physical_gpu_ids[0], 1: physical_gpu_ids[0]}\n            infer_gpu_ids = [physical_gpu_mapping[local_gpu_id] for local_gpu_id in infer_local_gpu_ids]\n            trainer_gpu_ids = [physical_gpu_mapping[local_gpu_id] for local_gpu_id in trainer_local_gpu_ids]\n        else:\n            raise ValueError(\n                f"Requested {total_requested_gpus} GPUs via deployment settings, but only "\n                f"{len(physical_gpu_ids)} physical GPU(s) are available: {physical_gpu_ids}"\n            )\n    else:\n        physical_gpu_mapping = {local_id: physical_gpu_ids[local_id] for local_id in range(total_requested_gpus)}'
if old in t:
    p.write_text(t.replace(old, new))
    print('patched')
else:
    print('not found')
