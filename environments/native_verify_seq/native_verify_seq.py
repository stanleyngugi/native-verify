import asyncio
import json

import verifiers as vf
from datasets import Dataset

from native_verify import verify
from native_verify.canonical import canonicalize_unicode
from native_verify.extract import extract_artifact
from native_verify.tasks import FAMILIES, generate_tasks

SYSTEM_PROMPT = (
    "You are an expert Lean 4 programmer. You will receive a sequence problem. "
    "Respond with exactly one ```lean code block containing the definition "
    "`def f (n : Nat) : Nat` computing the sequence, plus optional helper "
    "definitions. Constraints: pure computational definitions only. No imports, "
    "no attributes (@[...]), no theorems, no `sorry`, no `partial`, no `unsafe`. "
    "Use structural recursion or explicit fuel loops for recursion. "
    "ASCII only: write `->` for function arrows, never the Unicode arrow character. "
    "Define f either as `def f (n : Nat) : Nat := ...` or as `def f : Nat -> Nat` "
    "with match patterns."
)

STAGE_RANK = {
    "extract": 0.0,
    "sanitize": 0.0,
    "compile": 1.0,
    "train_check": 2.0,
    "holdout_check": 3.0,
    "timeout": 0.0,
    "internal": 0.0,
    "verified": 4.0,
}


class _ExtractFailure:
    def __init__(self, reason: str):
        self.accepted = False
        self.stage = "extract"
        self.reason = reason
        self.duration_ms = 0


def _build_split(families, per_family: int, seed: int) -> Dataset:
    tasks = generate_tasks(families=families, per_family=per_family, seed=seed)
    rows = []
    for task in tasks:
        rows.append(
            {
                "prompt": [{"role": "user", "content": task.prompt}],
                "answer": json.dumps(
                    {
                        "train": task.train_values,
                        "holdout": task.holdout_values,
                    }
                ),
                "info": json.dumps(
                    {
                        "task_id": task.task_id,
                        "family": task.family,
                        "difficulty": task.difficulty,
                    }
                ),
            }
        )
    return Dataset.from_list(rows)


async def _get_verdict(completion, answer, state):
    if "nv_verdict" in state:
        return state["nv_verdict"]
    response_text = ""
    if completion:
        last = completion[-1]
        response_text = last.get("content") or "" if isinstance(last, dict) else str(last)
    artifact = extract_artifact(response_text)
    if artifact is None:
        verdict = _ExtractFailure("no_lean_fence")
    elif len(artifact) > 10000:
        verdict = _ExtractFailure("artifact_too_large")
    else:
        case_data = json.loads(answer)
        verdict = await asyncio.to_thread(
            verify,
            canonicalize_unicode(artifact),
            case_data["train"],
            case_data["holdout"],
            timeout_seconds=90.0,
        )
    state["nv_verdict"] = verdict
    return verdict


async def lean_pass(completion, answer, state) -> float:
    verdict = await _get_verdict(completion, answer, state)
    return 1.0 if verdict.accepted else 0.0


async def stage_rank(completion, answer, state) -> float:
    verdict = await _get_verdict(completion, answer, state)
    return STAGE_RANK.get(verdict.stage, 0.0)


async def verify_seconds(completion, answer, state) -> float:
    verdict = await _get_verdict(completion, answer, state)
    return verdict.duration_ms / 1000.0


def load_environment(
    families: str = "all",
    num_per_family: int = 8,
    seed: int = 0,
    eval_num_per_family: int = 2,
    eval_seed: int = 1000,
) -> vf.Environment:
    family_list = None if families == "all" else [f.strip() for f in families.split(",")]
    unknown = set(family_list or []) - set(FAMILIES)
    if unknown:
        raise ValueError(f"unknown families: {sorted(unknown)}")

    dataset = _build_split(family_list, num_per_family, seed)
    eval_dataset = _build_split(family_list, eval_num_per_family, eval_seed)

    rubric = vf.Rubric(funcs=[lean_pass], weights=[1.0])
    rubric.add_metric(stage_rank)
    rubric.add_metric(verify_seconds)

    return vf.SingleTurnEnv(
        dataset=dataset,
        eval_dataset=eval_dataset,
        system_prompt=SYSTEM_PROMPT,
        rubric=rubric,
    )
