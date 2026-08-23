D=/tmp/runs/nv-smoke/native-verify-seq--qwen2.5-1.5b-instruct--b9dd453b/logs/attempt_1
echo '===INF==='
tail -6 $D/inference.log
echo '===ORCH==='
tail -5 $D/orchestrator.log
echo '===ENV==='
tail -4 $D/envs/train/native-verify-seq.log
echo '===GPU==='
nvidia-smi --query-gpu=memory.used --format=csv,noheader
