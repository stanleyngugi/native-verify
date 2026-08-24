# Course 01 — Designing RL Environments for LLMs

> Part 1 of the native-verify curriculum. This is the core skill: how to
> think about environments so that gradient descent teaches your model the
> thing you actually wanted it to learn.
>
> Every chapter ends with the real incident from our build that taught it.

---

## Chapter 1 — What an RL environment actually is

Forget games and agents-for-a-moment. For LLM post-training, an environment
is exactly three things and nothing else:

```text
1. A PROMPT DISTRIBUTION   where do tasks come from?
2. A ROLLOUT PROCEDURE     how does a model response become an action?
3. A REWARD FUNCTION       what scalar does each action receive?
```

That's it. Everything else — sandboxes, tools, sanitizers, routers — exists
only to serve one of those three.

Why this matters conceptually: **RL does not optimize "solve math." It
optimizes "maximize expected reward under the policy."** If your reward is a
poor proxy for the skill you care about, training works perfectly and gives
you the wrong thing. The environment designer owns that gap.

### The training loop you're feeding

Modern LLM RL almost always means a group-relative method (GRPO family):

```text
for each step:
    sample a batch of prompts
    for each prompt, sample G completions from the current policy   <- rollout
    score every completion with the reward function                 <- env
    advantage_i = (reward_i - mean(group_rewards)) / std(group_rewards)
    nudge policy weights to increase probability of above-average completions
```

Three consequences for environment design:

1. **Rewards are compared within a group**, not against an absolute bar.
   Absolute correctness calibration matters less than *discrimination* — the
   reward must separate better attempts from worse ones within the group.
2. **A group where all rewards are identical contributes zero gradient**
   ("degenerate group"). If your task is all-or-nothing and too hard, most
   groups are degenerate and training stalls.
3. **The policy will drift toward whatever is cheaply rewarding.** Any
   accidental pattern in your reward ("responses mentioning Lean get partial
   credit") becomes the learned behavior.

---

## Chapter 2 — The reward function defines the skill

The single most important sentence in this course.

When we say "we trained a model to solve sequences," what we actually trained
is "produce outputs that maximize `lean_pass`." Those are the same thing only
if the reward function is a faithful measure of solving. Faithfulness is
attacked from two sides:

- **False positives** (reward without skill): the model learns hacks.
- **False negatives** (skill without reward): the model learns to avoid good
  behavior because it wasn't recognized.

### Incident: the formatting ritual

Our entry-point contract originally required an exact signature:

```lean
def f (n : Nat) : Nat := ...
```

Qwen2.5-1.5B submitted this during training:

```lean
def f (n : Nat) := 4 * n + 10
```

This is *valid Lean*. The return type is inferred. The template's own verify
theorem forces `f : Nat -> Nat` at compile time regardless. But the sanitizer
rejected it, so a correct solution earned reward 0.

**Principle:** every requirement in your reward path must be load-bearing.
If removing it would never let an incorrect solution through, it isn't a
safety rule — it's noise you're actively training the model to satisfy.

Test to apply to each rule: *"If I delete this check, what incorrect output
becomes accepted?"* If the answer is "none," relax the rule.

### Incident: the two syntaxes of the same function

Later, models submitted:

```lean
def f : Nat -> Nat
  | 0 => 0
  | n + 1 => f n + (n + 1)
```

Also valid, also correct, also rejected — because our regex demanded the
parameter form. We widened acceptance to both forms. The contract should
specify the *type and totality* (`Nat -> Nat`, exhaustively defined), not one
surface syntax.

---

## Chapter 3 — Verification regimes and where execution sits

There are three ways to know whether a model output is correct, and they have
very different properties:

| Regime | Verifier | Failure mode |
|---|---|---|
| Answer-match | string/numeric compare | trains answer shaping; needs a predetermined answer |
| Proof-search | formal kernel over tactic proofs | brutal coverage cliffs; sparse rewards |
| Execution-as-proof | run a compiled claim | trust boundary must be enforced by harness |

Our choice is the third: the model submits a *program*, the environment runs
it inside a fixed template with `native_decide`. The claim verified is a
bounded instance statement ("this function reproduces these values"), not a
universal theorem. We buy soundness-of-execution and give up universality —
and price that in with holdout checks.

Two honest caveats we keep in view:

1. When the env already knows ground truth values, plain Python comparison
   would accept/reject identically. The Lean path earns its keep because
   (a) the artifact IS Lean and must execute somewhere sound, (b) arbitrary
   precision and total functions come free, (c) later, the model can write
   its own property checks — impossible to evaluate safely in Python-land.
2. `native_decide` trusts the compiler. That expanded trust base is exactly
   why Chapter 4 exists.

---

## Chapter 4 — The trust boundary: sanitization as anti-reward-hacking

Under RL, **gradient descent is an adversary aimed directly at your
verifier.** Any inconsistency, any shortcut, any "technically true" exploit
will be discovered by the policy given enough rollouts. This is not a
hypothetical; it is what optimization does.

Our sanitizer enforces a fail-closed allowlist on model-submitted code:

```text
ALLOWED: pure computational defs over Nat; structural recursion or fuel loops;
         helper defs with lowercase names; ASCII only
REJECTED: attributes (@[implemented_by] can make native_decide prove False),
          sorry/admit, unsafe/partial/opaque/axiom, imports, theorems,
          metaprogramming, IO/Float, unknown constructs (fail-closed)
```

Design rules that generalize:

1. **Fail-closed beats fail-open always.** An unknown construct must be an
   error, not a warning. You cannot enumerate attacks; you can enumerate
   legitimate needs.
2. **The security layer and the convenience layer live in different files.**
   Unicode->ASCII canonicalization (so models writing `→` aren't punished)
   happens in the eval adapter BEFORE the sanitizer sees the text. The
   sanitizer itself never grows exceptions.
3. **Ground truth custody**: the environment owns expected values. Model code
   can neither read nor embed them, and reserved names prevent shadowing the
   template's data arrays.

### Incident: the holdout index bug

Our first template checked holdout cases as a separate array indexed from
zero — so `f(0) == 144` failed for an honest Fibonacci implementation. Two
lessons: (a) holdouts must extend the same index space as train cases;
(b) the bug was caught because honest reference artifacts are tested against
the harness — **always ship a known-good solution test for your own env**.

---

## Chapter 5 — Procedural task generation

Curated datasets have three problems: they run out, they may be contaminated
(in the model's pretraining), and their difficulty distribution is fixed.

Procedural generation solves all three. Our generator has five families:

```text
linear              a(n) = p*n + q                     easy
explicit_polynomial cubic with small coefficients      medium
closed_form_sum     triangular / squares / cubes       medium
geometric_mod       b^n mod m via modpow               hard
digit_sum           decimal digit sum                  hard
```

Each family yields: a precisely-stated problem, K train values shown in the
prompt, held-out values owned by the env, and a reference artifact.

Rules we learned:

1. **State the rule precisely in words AND show values.** Values alone invite
   ambiguous generalizations; the holdout then punishes valid interpretations
   and your reward becomes noisy.
2. **Ship a reference artifact per task and test it through the full harness.**
   This proves each family is solvable end-to-end and catches env bugs (it
   caught the index bug).
3. **Seed deterministically.** Reproducible batches make debugging possible.
4. **Balance families per batch during training.** Our smoke run's reward
   swung 0.03–0.94 purely because linear-heavy batches are easy and
   digit_sum-heavy ones hard. Unbalanced mix makes the learning curve unreadable.

---

## Chapter 6 — Dense signal is free if you log stages

Binary pass/fail hides *where* failures happen. Because our verifier is a
pipeline (extract → sanitize → compile → train gate → holdout gate), every
failure lands in a stage, and the stage distribution is diagnostic gold:

```text
stage 0  extract/sanitize   format & hacking problems
stage 1  compile            Lean errors — model's Lean literacy
stage 2  train_check        wrong computation
stage 3  holdout_check      right on seen data, wrong on unseen (memorization!)
stage 4  verified           genuinely correct + generalizing
```

We log this as a zero-weight metric (never touching gradients). It tells you:
- rising sanitize failures = the policy is probing the trust boundary;
- train-pass-but-holdout-fail = memorizing tables instead of computing;
- compile-error dominance = the model needs Lean fluency, not math ability.

Dense shaping rewards built from these stages are tempting but dangerous
(every term is a new hacking surface). Log first; shape only when a specific
diagnosed problem demands it.

---

## Chapter 7 — The design review checklist

Before shipping an environment, answer these in order:

1. What exact skill does the reward measure? State it in one sentence.
2. For each reward-path requirement: what incorrect output slips through if
   I delete it? (Delete the ones with answer "none.")
3. Who holds ground truth, and can the policy influence any byte of it?
4. What happens on the worst legit output? On the worst adversarial output?
5. Is there a known-good reference artifact tested against the full harness?
6. Are groups guaranteed non-degenerate often enough for signal?
7. Where do failures concentrate, and can I see that without re-running?

---

## Exercises

1. Our sanitizer rejects all attributes. Name the concrete unsoundness that
   `@[implemented_by]` enables specifically with `native_decide`.
2. Design a reward for "model writes its own property checker" (Phase 4).
   What makes a checker reward hackable, and what gates would you add?
3. Suppose a family's holdout values are predictable from train values by a
   simpler rule than the stated one (e.g., all even). What goes wrong and how
   would you detect it from stage metrics?
4. Our batch mix confounded the learning curve. Sketch two sampling schemes
   that remove the confound, and their trade-offs.
