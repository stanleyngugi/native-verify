# native-verify

Execution-as-verification primitives for RL training of LLMs.

The model never proves anything and is never asked for a proof. It commits to a
computational artifact; the environment compiles the artifact into a fixed Lean
template and runs it with `native_decide`. The reward is the execution result.

```text
problem -> model artifact (pure defs) -> sanitize -> template + env-held cases -> lean run -> reward
```

## Why this exists

Two verification regimes dominate current RL environments, and this project is
deliberately orthogonal to both:

| Regime | Verifier | Weakness |
|---|---|---|
| Proof-search RL (miniF2F-style) | Lean kernel over tactic proofs | Brutal coverage cliffs; sparse rewards; model must learn Mathlib |
| Answer-match RL (math_verify) | String/numeric comparison | Trains answer shaping, not verification literacy; no process signal |
| **Execution-as-verification (this)** | `native_decide` over compiled claims | Trust boundary must be enforced by harness (this repo's core) |

`native_decide` turns Lean into a trusted evaluator: it compiles a decidable
proposition and runs it. No proof search, no tactics, no Mathlib. The claim is
verified because executing it returns true.

## Binding trust-boundary rules

These are non-negotiable design invariants. Under RL, gradient descent is an
adversary aimed at the verifier; any hole will be found.

1. The environment owns all ground truth. Model code can never name or embed
   expected values.
2. The model writes only pure computational definitions. One required entry
   point (`def f (n : Nat) : Nat`) plus optional helper defs. Everything else
   (theorems, attributes, imports, commands, types) is rejected.
3. Sanitization is fail-closed. Anything not explicitly allowed is rejected;
   unknown constructs are errors, not warnings.
4. Holdout cases extend the same index space beyond the values shown to the
   model and are checked in a separate gate. Hardcoding seen values fails the
   holdout gate; only computations that generalize pass.
5. Known unsoundness vectors are banned at the character/keyword level:
   `@[implemented_by]`, `@[extern]`, `@[csimp]`, `unsafe`, `partial`, `opaque`,
   `axiom`, `sorry`, `admit`, metaprogramming and IO surfaces.
6. Every checker invocation is timeout-bounded and sandboxed to a temp file.

## Layout

```text
src/native_verify/
  sanitizer.py    # fail-closed filter for model-submitted code
  template.py     # fixed checker template + stage markers
  runner.py       # Lean discovery (WSL bridge or native), execution, verdicts
  types.py        # result dataclasses
examples/
  demo_positive.py  # honest artifact -> accepted
  demo_attacks.py   # eight hacking attempts -> all rejected
tests/
ROADMAP.md       # experiment phases toward an RL environment
```

## Quickstart

No installation and no Lean setup are required on this machine: the runner
bridges to the pinned Lean 4.23.0 toolchain in the sibling `aimo` repo through
WSL automatically. Override with `NATIVE_VERIFY_LEAN` (direct executable path)
when needed.

```bash
python -m pytest tests -q
python examples/demo_attacks.py
python examples/demo_positive.py --strict
```

## Status

Phase 0 scaffold: standalone harness, positive/negative demos, unit tests.
See `ROADMAP.md` for the experiment sequence.

## Lineage

The sanitizer hardening approach descends from the Trace-to-Lean project
(`../aimo`). Domain machinery (mining families, consensus, algebra pipelines)
is deliberately excluded; that scaffolding becomes curriculum later or never.
