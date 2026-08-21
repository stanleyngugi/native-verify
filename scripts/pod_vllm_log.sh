grep -E "ERROR|RuntimeError|ValueError|Traceback" /workspace/vllm.log | head -10
echo ---
tail -20 /workspace/vllm.log
