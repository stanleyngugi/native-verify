export PATH="$HOME/.local/bin:$PATH"
cd /workspace/prime-rl
rm -rf /workspace/runs/nv-grpo-smoke
nohup uv run rl @ /workspace/grpo_smoke.toml --output-dir /workspace/runs/nv-grpo-smoke > /workspace/train_launch2.log 2>&1 &
echo $!
sleep 4
tail -6 /workspace/train_launch2.log
