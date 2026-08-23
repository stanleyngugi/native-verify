ps aux | grep -E "python|uv" | grep -v grep | head -5
ls -la /workspace/runs/ 2>/dev/null
find /workspace/runs -name "*.log" 2>/dev/null | head -5
cat /workspace/runs/nv-grpo-smoke/logs/envs/train/*.log 2>/dev/null | tail -5
