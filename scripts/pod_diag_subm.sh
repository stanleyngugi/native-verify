cd /workspace/prime-rl
git submodule status | head -8
ls deps/pydantic-config 2>/dev/null | wc -l
git submodule update --init --recursive deps/pydantic-config 2>&1 | tail -3
ls deps/pydantic-config/ | head -5
