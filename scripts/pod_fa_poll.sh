for i in $(seq 1 50); do
  sleep 60
  if grep -qE "Successfully installed|ERROR" /tmp/flashattn_build4.log 2>/dev/null; then
    break
  fi
done
grep -E "Successfully installed|ERROR" /tmp/flashattn_build4.log | tail -1
