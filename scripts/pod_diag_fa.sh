which nvcc || echo "no nvcc"
ls /usr/local/ | grep -i cuda || echo "no /usr/local/cuda"
ls /workspace/prime-rl/.venv/lib/python3.12/site-packages/nvidia/ 2>/dev/null | head
tail -20 /tmp/flashattn_build.log | grep -iE "nvcc|cuda|skipping|warning" | head -8
