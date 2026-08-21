from __future__ import annotations

from typing import Sequence

TEMPLATE_OPTIONS = (
    "set_option maxRecDepth 10000",
    "set_option maxHeartbeats 1000000",
)

VERIFY_SHAPE = (
    "theorem {name} :\n"
    "  (Array.range {data}.size).all (fun n => f n == {data}[n]!) = true := by\n"
    "  native_decide"
)


def build_checker_source(
    model_code: str,
    train_values: Sequence[int],
    holdout_values: Sequence[int],
) -> tuple[str, dict[str, int]]:
    if len(train_values) == 0:
        raise ValueError("train_values must be non-empty")
    if len(holdout_values) == 0:
        raise ValueError("holdout_values must be non-empty")
    for value in (*train_values, *holdout_values):
        if not isinstance(value, int) or isinstance(value, bool) or value < 0:
            raise ValueError(f"case values must be non-negative ints, got {value!r}")

    source = "\n".join(TEMPLATE_OPTIONS)
    lines = source.splitlines()

    model_start = len(lines) + 1
    source += "\n\n" + model_code.strip("\n")
    lines = source.splitlines()

    extended_values = (*train_values, *holdout_values)
    source += "\n\ndef trainExpected : Array Nat := " + _lean_nat_array_literal(train_values)
    source += "\ndef holdoutExpected : Array Nat := " + _lean_nat_array_literal(extended_values)
    lines = source.splitlines()

    verify_train_line = len(lines) + 1
    source += "\n\n" + VERIFY_SHAPE.format(name="verify_train", data="trainExpected")
    lines = source.splitlines()
    verify_holdout_line = len(lines) + 1
    source += "\n\n" + VERIFY_SHAPE.format(name="verify_holdout", data="holdoutExpected")
    source += "\n"

    markers = {
        "model_start": model_start,
        "verify_train": verify_train_line,
        "verify_holdout": verify_holdout_line,
    }
    return source, markers


def _lean_nat_array_literal(values: Sequence[int]) -> str:
    return "#[" + ", ".join(str(int(v)) for v in values) + "]"
