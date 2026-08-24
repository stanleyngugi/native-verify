import pathlib
p = pathlib.Path('/tmp/ton.sh')
t = p.read_text()
t = t.replace('export PATH=/tmp/prl_venv/bin:\n', 'export PATH="/tmp/prl_venv/bin:$PATH"\n')
p.write_text(t)
print(t.split('\n')[1])
