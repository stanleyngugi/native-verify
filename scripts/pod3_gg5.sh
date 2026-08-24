grep -n "make_arg_parser\|build_subprocess\|args_from\|config.vllm" /workspace/prime-rl/src/prime_rl/inference/vllm/server.py | head -10
grep -rn "serve\b.*--port\|\"serve\"\|'serve'" /workspace/prime-rl/src/prime_rl/inference/*.py 2>/dev/null | grep -v pycache | head -6
