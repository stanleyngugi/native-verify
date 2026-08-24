D=$(ls -d /tmp/runs/nv-smoke/*/logs/attempt_1 | head -1)
grep -A3 "EngineCore failed" $D/inference.log | grep -vE "core.py:1330\]\s+(Traceback|File|engine_core|super)" | head -15
grep -E "ERROR.*core.py.*(Error|error)" $D/inference.log | tail -5
