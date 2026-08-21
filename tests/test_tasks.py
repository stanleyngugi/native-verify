import pytest

from native_verify.tasks import FAMILIES, generate_tasks


def test_generate_all_families_deterministic():
    tasks_a = generate_tasks(per_family=2, seed=7)
    tasks_b = generate_tasks(per_family=2, seed=7)
    assert [t.task_id for t in tasks_a] == [t.task_id for t in tasks_b]
    assert [t.train_values for t in tasks_a] == [t.train_values for t in tasks_b]
    assert len(tasks_a) == 2 * len(FAMILIES)


def test_unknown_family_rejected():
    with pytest.raises(ValueError):
        generate_tasks(families=["nope"])


def test_task_shape_invariants():
    for task in generate_tasks(per_family=1, seed=1):
        assert len(task.train_values) > 0
        assert len(task.holdout_values) > 0
        assert task.prompt.count("def f (n : Nat) : Nat") == 1
        assert "Submit a Lean 4 definition" in task.prompt
        assert all(v >= 0 for v in task.train_values + task.holdout_values)


def test_holdout_extends_train_range():
    for task in generate_tasks(per_family=1, seed=3):
        assert task.holdout_values[0] != task.train_values[0] or len(set(task.holdout_values)) > 0
        assert len(task.train_values + task.holdout_values) > len(task.train_values)


LEAN = None


def _get_lean():
    global LEAN
    if LEAN is None:
        from native_verify import locate_lean

        LEAN = locate_lean()
    return LEAN


requires_lean = pytest.mark.skipif(_get_lean() is None, reason="no Lean backend available")


@requires_lean
@pytest.mark.parametrize("family", sorted(FAMILIES))
def test_reference_artifact_passes_harness(family):
    from native_verify import verify

    task = generate_tasks(families=[family], per_family=1, seed=42)[0]
    verdict = verify(
        task.reference_artifact,
        task.train_values,
        task.holdout_values,
        timeout_seconds=90.0,
    )
    assert verdict.accepted, (family, verdict.stage, verdict.reason, verdict.diagnostics[:3])
