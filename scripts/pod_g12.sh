ls /workspace/runs/nv-grpo-smoke/native-verify-seq--qwen2.5-1.5b-instruct--1346e277/configs/
grep -o "gpu_memory_utilization[^,}]*" /workspace/runs/nv-grpo-smoke/*/configs/inference.toml | head -3
grep -o "address[^,}]*" /workspace/runs/nv-grpo-smoke/*/configs/orchestrator.toml | head -5
