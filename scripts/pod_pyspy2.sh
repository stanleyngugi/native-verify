P=$(pgrep -f 'PRIME-RL::Launcher' | head -1)
echo "launcher pid: $P"
py-spy dump --pid $P 2>&1 | head -35
