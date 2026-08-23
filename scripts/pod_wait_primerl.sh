for i in $(seq 1 90); do
  sleep 60
  if grep -q "PRIMERL_SETUP_COMPLETE" /tmp/primerl_stage.log 2>/dev/null; then
    echo "SETUP COMPLETE"
    tail -4 /tmp/primerl_stage.log
    exit 0
  fi
  if grep -qiE "error|failed" /tmp/primerl_stage.log 2>/dev/null; then
    echo "POSSIBLE ERROR:"
    tail -8 /tmp/primerl_stage.log
    exit 1
  fi
done
echo "STILL RUNNING after 90 min"
tail -4 /tmp/primerl_stage.log
tail -3 /tmp/flashattn_build.log 2>/dev/null
