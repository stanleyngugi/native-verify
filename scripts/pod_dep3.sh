cd /workspace/prime-rl
.venv/bin/python - <<'EOF'
import typing
from prime_rl.entrypoints.rl import RLConfig
ann = RLConfig.model_fields["deployment"].annotation
print("annotation:", ann)
args = typing.get_args(ann)
for a in args:
    if hasattr(a, "model_fields"):
        print(a.__name__, {k: (v.default, str(v.annotation)) for k, v in a.model_fields.items()})
EOF
