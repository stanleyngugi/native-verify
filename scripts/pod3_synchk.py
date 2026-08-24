import ast
src = open('/workspace/prime-rl/src/prime_rl/entrypoints/rl.py').read()
ast.parse(src)
print('syntax ok')
