# Learning Curriculum — RL Environments, Verifiers, prime-rl

Everything here was learned by doing (and mostly by failing) during the
native-verify build, August 2026. Three parts, ordered by importance. Each
lesson cites the concrete incident that taught it.

## Part 1 — RL environment design (the core skill)

1. **An RL environment is exactly three things**: a prompt distribution, a
   rollout procedure, and a reward function. Everything else is plumbing.
   (Lesson: the whole Phase 0/1 design.)
2. **The reward function defines the skill.** Every strictness choice trains
   something — intended or not. Our first entry-contract rejected inferred
   return types and trained "formatting ritual," not math.
   (Incident: Qwen wrote valid `def f (n : Nat) := ...` and got zero reward.)
3. **Binary verifier-authoritative rewards beat clever shaping by default.**
   Shaping terms are hacking surfaces; log them as metrics until proven safe.
   (Doctrine from V2_EXECUTION_SPEC + VeriGate-style gating.)
4. **Ground truth custody is non-negotiable.** Env holds data points and
   holdouts; model never sees them; holdout gate extends the same index
   space. Hardcoding seen values must fail.
   (Incident: holdout array restarting at index 0 failed honest functions.)
5. **Fail-closed sanitization is the anti-reward-hacking layer.** Unknown
   construct = reject. Under RL, gradient descent attacks your verifier;
   any hole will be found. (Attack demo: 8/8 rejections.)
6. **Procedural generation beats curated datasets**: infinite, seeded,
   contamination-free, difficulty-stratified, with programmatic ground truth.
7. **Canonicalize in the adapter, never weaken the sanitizer.** Unicode->ASCII
   mapping lives in eval code; the security boundary stays strict.
8. **Trace consensus ≈ GRPO groups.** K-sample consensus at inference is the
   hand-rolled version of what group-relative advantage does natively.
9. **Dense process signals come free from stage logs** (sanitize/compile/
   train/holdout). Use them for diagnostics before touching gradients.

## Part 2 — Prime Intellect verifiers (building environments)

1. **Environment = Python module exposing `load_environment()`**, packaged as
   a wheel. Dataset + harness + rubric is the mental model; the file is small.
2. **Two API generations**: legacy v0 (`vf.SingleTurnEnv` + `Rubric`, still
   everywhere) and v1 (`Taskset`/`Task`/`Harness` with `@reward` decorators).
   prime-rl current requires v1; know both.
3. **Rubric mechanics**: weighted reward funcs, `add_metric` (weight 0) for
   observability, shared mutable `state` to compute expensive verdicts once.
4. **Group-based reward functions use plural args** (`completions`) and return
   lists — that is GRPO's advantage computation surfacing at the env layer.
5. **Never block the event loop**: subprocess/CPU work goes through
   `asyncio.to_thread`; sync calls serialize all concurrent rollouts.
6. **Packaging traps**: hatchling needs `allow-direct-references = true` for
   git-URL deps; `[tool.uv.sources]` breaks Hub installs; include
   `pyproject.toml` in the wheel.
7. **v1 Taskset shape**: config-in, tasks-out via `load()`; per-task pydantic
   `TaskData`; rewards are decorated methods invoked by parameter-name
   matching against `{task, trace, runtime}`.
8. **Trace API gotchas**: `trace.last_reply` is a property, not a method.
   (Incident: 'str' object is not callable killed every scoring call.)

## Part 3 — prime-rl infrastructure (operational reality)

1. **Pre-flight checks save hours**: GPU count, `cat
   /sys/fs/cgroup/memory.max` (advertised RAM != container limit), disk type
   (network FS vs local overlay).
2. **prime-rl hard-requires >= 2 GPUs for `rl`** (strict train/infer
   partitioning, no colocate mode upstream). Single-GPU needs the launcher
   patch in `patches/prime-rl/`.
3. **flash-attn source builds are the long pole** (~2h constrained): need
   nvcc (CUDA_HOME), explicit arch list, MAX_JOBS sized to the cgroup limit,
   pip --no-binary :all: (uv cache serves stale CPU-only wheels), ensurepip
   (uv venvs lack pip), setsid+disown (ssh drops kill process groups).
4. **Colocated memory budgeting**: vLLM's profiling peak scales with
   max_num_seqs x max_model_len; cap both on shared GPUs; stagger trainer
   start after inference stabilizes.
5. **Hidden dependencies surface as FileNotFoundError**: vllm-router binary,
   ring_flash_attn imports deep in trainer code. Patch imports optional when
   the feature is unreachable on your topology.
6. **Network filesystems poison everything**: torch imports take minutes,
   uv can't rm -rf .venv, output dirs crawl. Put venvs and run outputs on
   local overlay (/tmp), keep only sources on /workspace.
7. **Config system is layered**: TOML base + overlays + CLI dotted flags,
   later wins; extra TOML fields flow through `model_extra` into vLLM args
   (that's how max_num_seqs passed without patching).
8. **--dry-run validates everything except runtime**; use it relentlessly,
   but expect runtime-only failures (imports, memory races, custody bugs).
9. **Detach long jobs properly**: setsid + nohup + disown + </dev/null; a
   timed-out polling ssh WILL kill your build otherwise.
10. **Commit patches as full files** in the repo, applied by copy after each
    clone — reproducible across ephemeral pods.

## Suggested session order for teaching

Sessions 1-3: Part 1 (concepts + reading our own sanitizer/template/tasks).
Sessions 4-5: Part 2 (build a toy verifiers env from scratch, then dissect
ours). Sessions 6+: Part 3 (only what's needed to launch; reference the
runbook rather than memorizing).
