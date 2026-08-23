df -h / | tail -1
free -g | head -2
dmesg 2>/dev/null | grep -i "killed process" | tail -3
tail -c 300 /tmp/flashattn_build5.log
ls /tmp/pip-* /root/.cache/pip 2>/dev/null | head -3
which tmux || echo no-tmux
