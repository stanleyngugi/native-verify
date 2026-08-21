import argparse
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "src"))

from native_verify import locate_lean, verify


def fib(n: int) -> int:
    a, b = 0, 1
    for _ in range(n):
        a, b = b, a + b
    return a


PROBLEM = (
    "Compute a(n): the n-th Fibonacci number with a(0)=0, a(1)=1. "
    "Submit a Lean definition `def f (n : Nat) : Nat` computing a(n). "
    "Reference values: a(0)=0, a(1)=1, ..., a(11)=89."
)

ARTIFACT = """def fib : Nat -> Nat
  | 0 => 0
  | 1 => 1
  | n + 2 => fib (n + 1) + fib n

def f (n : Nat) : Nat := fib n"""


def main() -> int:
    parser = argparse.ArgumentParser(description="Positive case: honest artifact accepted.")
    parser.add_argument("--strict", action="store_true")
    args = parser.parse_args()

    train = [fib(n) for n in range(12)]
    holdout = [fib(n) for n in range(12, 16)]

    verdict = verify(ARTIFACT, train, holdout)
    backend = locate_lean()
    payload = {
        "problem": PROBLEM,
        "artifact": ARTIFACT,
        "train_cases": train,
        "holdout_hidden": len(holdout),
        "lean_backend": None if backend is None else {"mode": backend.mode, "executable": backend.executable},
        "verdict": {
            "accepted": verdict.accepted,
            "stage": verdict.stage,
            "reason": verdict.reason,
            "duration_ms": verdict.duration_ms,
            "backend": verdict.backend,
            "diagnostics": verdict.diagnostics,
        },
    }
    print(json.dumps(payload, indent=2))

    if args.strict and not (verdict.accepted and verdict.stage == "verified"):
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
