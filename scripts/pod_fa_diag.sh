grep -iE "cuda|nvcc|arch|skip|building|running build_ext|error" /tmp/flashattn_build2.log | head -20
echo ====
wc -l /tmp/flashattn_build2.log
head -15 /tmp/flashattn_build2.log
