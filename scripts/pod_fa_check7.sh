grep -c "Killed" /tmp/flashattn_build6.log
tail -c 250 /tmp/flashattn_build6.log
echo ""
pgrep -f "pip install" | wc -l
nvidia-smi --query-gpu=memory.used --format=csv,noheader 2>/dev/null
