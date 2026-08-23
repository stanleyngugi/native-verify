grep -B3 -A8 -iE "error|failed" /tmp/flashattn_build5.log | grep -v "^--$" | head -40
