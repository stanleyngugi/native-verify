grep -B5 "EngineCore failed" /workspace/manual_run/inference.log | grep -vE "^\(APIServer" | head -10
grep -iE "out of memory|OOM|Killed|ValueError|AssertionError|TypeError" /workspace/manual_run/inference.log | sort -u | head -6
