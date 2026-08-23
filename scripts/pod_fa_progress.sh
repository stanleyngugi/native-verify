grep -oE "\[[0-9]+/73\]" /tmp/flashattn_build6.log | tail -1
grep -cE "Killed" /tmp/flashattn_build6.log
grep -E "Successfully installed" /tmp/flashattn_build6.log | tail -1
