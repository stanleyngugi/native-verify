cd /workspace/prime-rl
git submodule update --force --recursive deps/pydantic-config 2>&1 | tail -2
ls deps/pydantic-config/ | head -5
echo ---
git submodule update --force --recursive deps/prime-kernels 2>&1 | tail -2
ls deps/prime-kernels/ | head -5
