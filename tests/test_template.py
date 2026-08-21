import pytest

from native_verify.template import build_checker_source

MODEL = "def f (n : Nat) : Nat := n"


def test_source_contains_env_held_data():
    source, _ = build_checker_source(MODEL, [1, 2, 3], [4, 5])
    assert "def trainExpected : Array Nat := #[1, 2, 3]" in source
    assert "def holdoutExpected : Array Nat := #[1, 2, 3, 4, 5]" in source


def test_source_contains_both_theorems():
    source, _ = build_checker_source(MODEL, [1], [2])
    assert "theorem verify_train :" in source
    assert "theorem verify_holdout :" in source
    assert "holdoutExpected : Array Nat := #[1, 2]" in source
    assert source.count("native_decide") == 2


def test_markers_ordered():
    _, markers = build_checker_source(MODEL, [1], [2])
    assert markers["model_start"] < markers["verify_train"] < markers["verify_holdout"]


def test_empty_train_rejected():
    with pytest.raises(ValueError):
        build_checker_source(MODEL, [], [1])


def test_empty_holdout_rejected():
    with pytest.raises(ValueError):
        build_checker_source(MODEL, [1], [])


def test_negative_value_rejected():
    with pytest.raises(ValueError):
        build_checker_source(MODEL, [-1], [1])
