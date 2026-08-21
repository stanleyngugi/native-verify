import asyncio
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "src"))
sys.path.insert(0, str(ROOT / "environments" / "native_verify_seq"))

from native_verify.tasks import generate_tasks
import native_verify_seq as env_module


def make_completion(text: str):
    return [{"role": "assistant", "content": text}]


async def main() -> int:
    env = env_module.load_environment(
        families="all", num_per_family=2, seed=0, eval_num_per_family=1, eval_seed=500
    )
    print(f"dataset rows={len(env.dataset)} eval rows={len(env.eval_dataset)}")
    row = env.dataset[0]
    print("first prompt:", row["prompt"][0]["content"][:80], "...")
    info = json.loads(row["info"])
    print("first task:", info)

    tasks = {t.task_id: t for t in generate_tasks(per_family=2, seed=0)}
    gmod = next(t for t in tasks.values() if t.family == "geometric_mod")
    answer = json.dumps({"train": gmod.train_values, "holdout": gmod.holdout_values})

    cases = {
        "honest_reference": ("```lean\n" + gmod.reference_artifact + "\n```", True),
        "hack_sorry": ("```lean\ndef f (n : Nat) : Nat := sorry\n```", False),
        "no_fence": ("I would define f recursively in Lean.", False),
    }
    failures = []
    for name, (text, expect) in cases.items():
        state = {}
        reward = await env_module.lean_pass(make_completion(text), answer, state)
        rank = await env_module.stage_rank(make_completion(text), answer, state)
        verdict = state["nv_verdict"]
        ok = reward == (1.0 if expect else 0.0)
        if not ok:
            failures.append(name)
        print(
            f"{name:18} reward={reward} stage={verdict.stage:14} "
            f"rank={rank} reason={str(verdict.reason)[:40]} {'OK' if ok else 'MISMATCH'}"
        )

    if failures:
        print("FAILURES:", failures)
        return 1
    print("env smoke passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(asyncio.run(main()))
