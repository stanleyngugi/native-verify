# Prime Intellect verifiers - research notes

Notes from the official docs (docs.primeintellect.ai), captured so Phase 2
packaging follows the platform contract exactly. Checked 2026-08-21.

## Environment contract

An environment is a self-contained Python module exposing:

```python
def load_environment(**args) -> vf.Environment
```

It packages three things:

1. a dataset of prompts (with ground truth or metadata);
2. a harness controlling model interaction (single-turn, multi-turn, tools);
3. a rubric of reward functions producing scalar signals.

The same definition drives RL training, standalone eval (`vf-eval`), and
synthetic data generation.

## Packaging rules

- `pyproject.toml` declares dependencies; distributed as a wheel.
- `verifiers` belongs in `dependencies`.
- Git URL dependencies must use PEP 508 direct format in `dependencies`
  (`pkg @ git+https://...`), never `[tool.uv.sources]` (not embedded in wheel
  metadata).
- Version bump + `prime env push` publishes a new version to the Environments
  Hub; previous versions stay installable.
- Local dev loop: `uv pip install -e .` then `uv run vf-eval <env-name>`.

## Rubric mechanics

- Reward functions are sync or async callables receiving kwargs like
  `prompt`, `completion`, `answer`, `state`, `parser`.
- Weighted combination into one scalar; non-reward metrics can be logged
  without affecting gradients.
- v0 base classes: `SingleTurnEnv`, `ToolEnv`, `StatefulToolEnv` (all extend
  `MultiTurnEnv`). v1 splits taskset (data+scoring) from harness (execution).

## Relevance to native-verify Phase 2

- dataset = procedural task families from `tasks.py` (train values in prompt,
  holdout held by env);
- harness = single-turn: model submits one ```lean fenced artifact;
- rubric components:
  - `lean_pass`: binary authoritative outcome (verdict.accepted);
  - stage shaping only when the GRPO group is degenerate (all-fail);
  - intra-group agreement as logged metric first, reward component later;
- sandboxing note: per-rollout Lean invocation must be timeout-bounded; the
  runner already satisfies this. For hosted training, verification likely runs
  in a sandbox image with the pinned toolchain.
