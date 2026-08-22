cd /workspace/prime-rl
grep -A2 "submodule" .gitmodules | head -30
sed -i "s|git@github.com:|https://github.com/|" .gitmodules
git submodule sync --quiet 2>/dev/null || true
git submodule update --init 2>&1 | tail -4
echo SUBMODULES_DONE
