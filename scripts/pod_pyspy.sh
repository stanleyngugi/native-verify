export PATH="$HOME/.local/bin:$PATH"
pip install -q py-spy 2>&1 | tail -1
py-spy dump --pid $(pgrep -f 'PRIME-RL::Launcher' | head -1) 2>&1 | head -30
