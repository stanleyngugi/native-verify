# ROADMAP

Experiment sequence from standalone verifier to RL environment. Phases are
gated: do not start a phase before the previous phase's exit criteria hold.

## Phase 0 - Hardened harness (current)

- Sanitizer with fail-closed allowlist semantics.
- Fixed template with env-held train + holdout arrays and two `native_decide`
  verify theorems.
- Runner with WSL bridge to pinned Lean, timeouts, verdict classification.
- Positive demo (honest artifact accepted) and attack demo (eight rejection
  classes).

Exit criteria: tests green; every attack demo rejected at sanitize or holdout
stage; honest artifact accepted end-to-end.

## Phase 1 - Task generator + batch eval

- Procedural numeric task families with programmatic ground truth
  (arithmetic identities, recurrences, combinatorial counts, modular
  properties). Each family emits: prompt with train cases, env-held holdout
  cases, difficulty label.
- Batch CLI: run any OpenAI-compatible chat model against N tasks, extract the
  final artifact from the response, verify, log per-task verdicts.

Exit criteria: contamination-free tasks generated at will; one model evaluated
end-to-end with acceptance-rate report split by stage
(sanitize/compile/train/holdout).

## Phase 2 - verifiers wheel

- Package as a Prime Intellect `verifiers` environment: dataset = generated
  tasks, rubric = weighted components:
  - `lean_pass` (binary, authoritative outcome),
  - `holdout_gate` (must pass for any nonzero reward),
  - stage-reached shaping (only when group is degenerate),
  - intra-group agreement rate (GRPO group = free consensus set).
- Sandboxed per-rollout Lean invocation contract documented.

Exit criteria: environment installable via wheel; runs under `vf` eval path;
rubric components logged independently.

## Phase 3 - GRPO training run

- Small open model via prime-rl (or Tinker) on Phase 2 environment.
- Track: acceptance rate, hack-attempt rate (sanitize rejections), holdout
  failures, VG gap, extrapolation slope.
- Anti-hacking audit: manual review of rejected artifacts each checkpoint.

Exit criteria: positive acceptance-rate trend without sanitize-rejection decay;
holdout failure rate does not grow relative to train success (no memorization
collapse).

## Phase 4 - Self-written checkers

- Model emits its own property checks alongside the answer artifact; env runs
  both. Reward requires the model's checker to be sound (passes on true
  variants, fails mutated variants).
- Trains verification literacy explicitly; enables sound process rewards from
  executed properties instead of learned PRMs.

Exit criteria: measurable gap between answer accuracy and self-check quality
closes over training.
