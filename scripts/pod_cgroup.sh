cat /sys/fs/cgroup/memory.max 2>/dev/null || cat /sys/fs/cgroup/memory/memory.limit_in_bytes 2>/dev/null
nvidia-smi --query-gpu=name,compute_cap --format=csv,noheader
