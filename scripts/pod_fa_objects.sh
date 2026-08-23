find /tmp/pip-install-* -name "*.o" 2>/dev/null | wc -l
ls -t /tmp/pip-install-*/flash-attn-*/build/temp*/csrc/flash_attn/src/ 2>/dev/null | head -3
ps aux | grep -E "nvcc|cicc" | grep -v grep | wc -l
