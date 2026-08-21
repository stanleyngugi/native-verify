# ROADMAP

Experiment sequence from standalone verifier to RL environment. Phases are
gated: do not start a phase before the previous phase's exit criteria hold.

## Phase 0 - Hardened harness (complete)

- Sanitizer with fail-closed allowlist semantics.
- Fixed template with env-held train + holdout arrays and two `native_decide`
  verify theorems.
- Runner with WSL bridge to pinned Lean, timeouts, verdict classification.
- Positive demo (honest artifact accepted) and attack demo (eight rejection
  classes).

Exit criteria met: 43 tests green; all attack demos rejected at sanitize or
holdout stage; honest artifacts accepted end-to-end.

## Phase 1 - Task generator + batch eval (complete)

- Five procedural families with programmatic ground truth: linear,
  explicit_polynomial, closed_form_sum, geometric_mod, digit_sum.
- Batch CLI (`scripts/batch_eval.py`) against any OpenAI-compatible endpoint
  with per-stage verdict logging and 429 backoff.
- Unicode canonicalization layer; entry contract relaxed to type-level.
- Reference-artifact self-tests prove every family solvable end-to-end.

Exit criteria met: baseline measured (gpt-oss-20b via Groq, 90% acceptance on
10 tasks); acceptance report split by stage and family.

## Phase 2 - verifiers wheel (in progress, core complete)

- `environments/native_verify_seq/`: single-file env module exposing
  `load_environment()`; dataset = generated tasks with env-held holdouts in
  the answer field; rubric = binary `lean_pass` reward plus `stage_rank` and
  `verify_seconds` metrics; verdict cached in rollout state; Lean check
  offloaded via `asyncio.to_thread` per verifiers performance rules.
- Packaging per Environments Hub contract: hatchling build, git-URL dependency
  on this repo, eval defaults in pyproject.
- Integration smoke passed against installed verifiers 0.3.0 (dataset rows,
  honest/hack/no-fence scoring through real rubric funcs).

Remaining for Phase 2: `prime env push` to the Hub (needs Prime CLI auth) and
a `vf-eval` run against a live inference endpoint (deferred to RunPod setup).

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
