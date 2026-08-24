# Course 02 — Building Environments with Prime Intellect's verifiers

> Part 2 of the curriculum. From zero to a packaged, Hub-publishable RL
> environment. All code examples are real — taken from
> `environments/native_verify_seq/native_verify_seq.py` in this repo.

---

## Chapter 1 — The environment model

A verifiers environment is a self-contained Python module exposing one
entrypoint:

```python
def load_environment(**args) -> vf.Environment:
    ...
```

Conceptually it packages three things:

1. **a dataset** of prompts (with ground truth or metadata columns),
2. **a harness** controlling how the model interacts (single-turn Q&A,
   multi-turn tool calling, agent sandboxes),
3. **a rubric** — reward functions that score rollouts into scalars.

The same object drives RL training, standalone evaluation (`vf-eval`), and
synthetic data generation. You write the environment; batching, weight sync,
GPU scheduling, and rollout concurrency belong to the trainer.

Two API generations exist:

- **v0 (legacy)**: `import verifiers as vf`; `SingleTurnEnv`, `ToolEnv`,
  `Rubric`. Still widely deployed; simplest to learn.
- **v1 (current)**: `Taskset`/`Task`/`Harness` classes with decorated reward
  methods; what current prime-rl consumes.

Learn v0 concepts first — they map one-to-one onto v1 — then read our v1
implementation.

---

## Chapter 2 — The three components, concretely

### Dataset

Rows need a `prompt` column (list of chat messages) or `question` (string,
auto-wrapped). Optional: `answer` (ground truth for scoring) and `info`
(JSON metadata).

Our rows carry ground truth *inside* the dataset but never shown to the
model — the prompt is one message; train/holdout values live in `answer`:

```python
rows.append({
    "prompt": [{"role": "user", "content": task.prompt}],
    "answer": json.dumps({"train": task.train_values,
                          "holdout": task.holdout_values}),
    "info": json.dumps({"task_id": task.task_id,
                        "family": task.family,
                        "difficulty": task.difficulty}),
})
```

**Design note:** custody lives here. The holdout values ride along in the row
so scoring is trivially available, but nothing ever puts them in the prompt.

### Harness

Controls turns and tools. For single-turn Q&A you use the built-in
`SingleTurnEnv` (v0) or the default null harness (v1) — no code from you.
Multi-turn, tools, and sandboxes subclass further; not needed for
artifact-submission environments where the artifact is the final message.

### Rubric

Reward functions are plain (async) callables whose parameter names select
what they receive: `prompt`, `completion`, `answer`, `info`, `state`.

```python
async def lean_pass(completion, answer, state) -> float:
    verdict = await _get_verdict(completion, answer, state)
    return 1.0 if verdict.accepted else 0.0

rubric = vf.Rubric(funcs=[lean_pass], weights=[1.0])
rubric.add_metric(stage_rank)        # weight 0: logged, never trained on
rubric.add_metric(verify_seconds)
```

Three mechanics worth internalizing:

1. **Weighted sum = final reward.** One authoritative binary component at
   weight 1.0 keeps the verifier supreme.
2. **Metrics (`weight=0` / `add_metric`) are observability.** They appear in
   logs without touching gradients. Our `stage_rank` (0=extract/sanitize …
   4=verified) diagnoses where failures concentrate.
3. **`state` is shared mutable dict across all rubric funcs for one rollout**
   — expensive computations run once and cache:

```python
async def _get_verdict(completion, answer, state):
    if "nv_verdict" in state:
        return state["nv_verdict"]
    ...run verification...
    state["nv_verdict"] = verdict
    return verdict
```

---

## Chapter 3 — The async rule

verifiers runs rollouts concurrently on one asyncio event loop. A synchronous
blocking call freezes *every* concurrent rollout. Our Lean check spawns a
subprocess and takes seconds — so it must be offloaded:

```python
verdict = await asyncio.to_thread(verify, canonicalize_unicode(artifact),
                                  case_data["train"], case_data["holdout"])
```

`asyncio.to_thread` releases the event loop while the subprocess runs. This
is the single most common environment bug at scale.

---

## Chapter 4 — Extraction and canonicalization (the adapter layer)

Models respond in free text; we need the Lean block:

```python
FENCE_RE = re.compile(r"```(?:lean|lean4)?\s*\n(.*?)```", re.DOTALL)
blocks = FENCE_RE.findall(text); artifact = blocks[-1].strip()
```

Then normalize harmless variance before verification — but strictly outside
the security layer:

```python
UNICODE_ASCII_MAP = {"\u2192": "->", "\u00d7": "*", "\u2212": "-", ...}
artifact = canonicalize_unicode(artifact)
```

**Layer separation principle:** the adapter may be forgiving (it translates);
the sanitizer may not (it decides). If canonicalization lived inside the
sanitizer, every future translation would be a potential bypass.

---

## Chapter 5 — The sanitizer (your trust boundary)

Full rules live in `src/native_verify/sanitizer.py`; the design principles
matter more than the list:

- **Allowlist, not blacklist**: only `def` declarations; only specific entry
  signatures (`def f (n : Nat) : Nat :=` OR `def f : Nat -> Nat | ...`);
  everything else fails.
- **Character-level bans** kill whole attack classes at once: `@` (attributes),
  backtick/quote (strings/char-literals), `#` (commands).
- **Keyword bans with word boundaries**: `sorry`, `partial`, `axiom`,
  `implemented_by`, `theorem`, `import`, ...
- **Fail-closed**: unknown construct => reject, with reason string returned so
  the model can (in multi-turn settings) recover.
- **Resource caps**: max chars/lines/defs/literal-digits blunt elaboration DoS.

Why attributes matter specifically: `native_decide` trusts the compiler.
`@[implemented_by]` lets submitted code substitute an implementation that
disagrees with the logical definition — historically enough to prove `False`.
Under RL this isn't theoretical; it's the first thing a policy would find.

---

## Chapter 6 — Packaging and the Environments Hub

Layout (per Hub convention):

```text
environments/native_verify_seq/
├── native_verify_seq.py   # implementation + load_environment()
├── pyproject.toml
└── README.md
```

pyproject essentials:

```toml
[project]
name = "native-verify-seq"
dependencies = [
    "verifiers>=0.1.8",
    "native-verify @ git+https://github.com/stanleyngugi/native-verify.git",
]

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[tool.hatch.metadata]
allow-direct-references = true     # REQUIRED for git URL deps

[tool.hatch.build]
include = ["native_verify_seq.py", "pyproject.toml"]

[tool.verifiers.eval]
num_examples = 20
rollouts_per_example = 4
```

Traps we hit:
- missing `allow-direct-references` -> build fails at metadata stage;
- `[tool.uv.sources]` is uv-local and NOT embedded in wheel metadata — the
  Hub loses the dependency;
- the module filename must match what the loader imports by env id.

Dev loop: `uv pip install -e .` then `uv run vf-eval <env-name>`; push with
`prime env push`.

---

## Chapter 7 — v1: Tasksets, Tasks, and decorated rewards

When prime-rl needs your environment, it imports the module by id and expects
exported (via `__all__`) `Taskset` and `TasksetConfig` subclasses:

```python
class NativeVerifyTaskData(TaskData):
    train_values: list[int]
    holdout_values: list[int]      # typed per-task payload

class NativeVerifyTask(Task[NativeVerifyTaskData, State, NativeVerifyTaskConfig]):
    NEEDS_CONTAINER = False

    @reward(weight=1.0)
    async def nv_lean_pass(self, trace: Trace, runtime: Runtime) -> float:
        verdict = await self._run(trace)
        trace.info["nv_stage"] = verdict.stage      # free-form diagnostics
        return 1.0 if verdict.accepted else 0.0

class NativeVerifyTaskset(Taskset[NativeVerifyTask, NativeVerifyTasksetConfig]):
    def load(self):
        for t in generate_tasks(...):
            yield NativeVerifyTask(NativeVerifyTaskData(idx=..., prompt=t.prompt,
                train_values=t.train_values, holdout_values=t.holdout_values),
                self.config.task)
```

Differences from v0 worth noting:

1. Rewards are **methods on the Task**, invoked by *parameter-name matching*
   against `{task: data, trace: trace, runtime: runtime}`.
2. `trace.last_reply` gives the model's final text — **it is a property**, not
   a method. Calling it raises `'str' object is not callable`, which silently
   zeroed every one of our first rollouts.
3. Metrics are just `@reward(weight=0.0)` methods.
4. The TOML side configures it declaratively:

```toml
[[orchestrator.train.source]]
name = "native-verify-seq"
[orchestrator.train.source.env.taskset]
id = "native-verify-seq"
num_per_family = 8
seed = 0
```

Unknown extra fields in the TOML flow through `model_extra` into engine args
— that is how we passed `max_num_seqs = 64` straight to vLLM without touching
prime-rl code.

---

## Chapter 8 — Testing your environment

Minimum viable test battery before any training run:

1. **Smoke test** (no GPU): construct env, score a known-good completion, a
   known-hack, and a garbage response through the real rubric functions.
   Assert exact rewards and stages.
2. **Reference-artifact self-test**: every task family's known-good solution
   must pass the full harness. Catches env bugs (ours caught the holdout
   index bug) rather than model errors.
3. **Attack battery**: sorry / implemented_by / hardcoded-table /
   partial / shadowing / injection / import / #eval — assert all rejected.
4. **One real end-to-end rollout** against a served model before training.

---

## Exercises

1. Add a new family (`sum_of_divisors`, say) to `tasks.py`: statement, values,
   reference artifact, difficulty. Prove it via the reference test.
2. Convert the batch-eval CLI's system prompt improvements into the env's
   `SYSTEM_PROMPT` — and write the test that would have caught the drift.
3. Implement a group-based metric: intra-group agreement rate using plural
   args (`completions`). Where would it plug into GRPO?
