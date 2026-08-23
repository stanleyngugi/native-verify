cd /workspace
setsid bash /workspace/chain_launch_inner.sh > /workspace/chain.log 2>&1 < /dev/null &
disown
echo "chain armed pid $!"
