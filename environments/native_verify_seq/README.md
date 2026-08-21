# native-verify-seq

Execution-as-verification RL environment for Prime Intellect's verifiers.

The model receives a numeric sequence problem and must submit a Lean 4
definition `def f (n : Nat) : Nat` in a ```lean code block. The environment
compiles the submission into a fixed checker template and runs it with
`native_decide`. The reward is binary: the definition must reproduce all
training values AND generalize to held-out values the model never saw.

## Reward

- `lean_pass` (weight 1.0): 1.0 iff the artifact passes sanitization, compiles,
  matches train cases, and passes the holdout gate. Binary by design - the
  verifier is authoritative.
- Metrics: `stage_rank` (how far the rollout reached: 0 extract/sanitize,
  1 compile, 2 train gate, 3 holdout gate, 4 verified), `verify_seconds`.

## Task families (procedural, contamination-free)

- `linear`: a(n) = p*n + q (easy)
- `explicit_polynomial`: cubic with small coefficients (medium)
- `closed_form_sum`: triangular / sum of squares / sum of cubes (medium)
- `geometric_mod`: b^n mod m via fuel-based modpow (hard)
- `digit_sum`: decimal digit sum via fuel loop (hard)

## Trust boundary

The environment owns all ground truth. Submissions may contain only pure
computational definitions: no imports, attributes, theorems, `sorry`,
`partial`, or `unsafe`. Unknown constructs are rejected fail-closed. Holdout
values are never shown in prompts.

## Required environment variables

None. But a Lean 4 toolchain (>= 4.22) must be available on the machine
running rollouts:

- set `NATIVE_VERIFY_LEAN` to the `lean` executable path, or
- have `lean` on PATH.

## Local development

```bash
uv pip install -e .
vf-eval native-verify-seq
```
