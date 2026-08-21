import pytest

from native_verify.sanitizer import sanitize_model_code, strip_comments

HONEST_FIB = """def fib : Nat -> Nat
  | 0 => 0
  | 1 => 1
  | n + 2 => fib (n + 1) + fib n

def f (n : Nat) : Nat := fib n"""


def test_honest_artifact_accepted():
    result = sanitize_model_code(HONEST_FIB)
    assert result.accepted, result.errors


def test_helper_def_allowed():
    code = "def helper (m : Nat) : Nat := m * 2\n\ndef f (n : Nat) : Nat := helper n"
    assert sanitize_model_code(code).accepted


def test_sorry_rejected():
    result = sanitize_model_code("def f (n : Nat) : Nat := sorry")
    assert not result.accepted
    assert any("sorry" in error for error in result.errors)


def test_partial_rejected():
    code = "partial def f (n : Nat) : Nat := f n"
    assert not sanitize_model_code(code).accepted


def test_attribute_rejected():
    code = "@[implemented_by g] def f (n : Nat) : Nat := n\ndef g (n : Nat) : Nat := n + 1"
    result = sanitize_model_code(code)
    assert not result.accepted
    assert any("@" in error for error in result.errors)


def test_import_rejected():
    code = "import Init\n\ndef f (n : Nat) : Nat := n"
    result = sanitize_model_code(code)
    assert not result.accepted


def test_theorem_injection_rejected():
    code = HONEST_FIB + "\n\ntheorem verify_train : True := by trivial"
    result = sanitize_model_code(code)
    assert not result.accepted


def test_reserved_name_rejected():
    code = "def trainExpected : Array Nat := #[0]\n\ndef f (n : Nat) : Nat := n"
    result = sanitize_model_code(code)
    assert not result.accepted
    assert any("reserved" in error for error in result.errors)


def test_missing_entry_point_rejected():
    assert not sanitize_model_code("def helper (n : Nat) : Nat := n").accepted


def test_wrong_signature_rejected():
    result = sanitize_model_code("def f (x : Nat) : Nat := x")
    assert not result.accepted
    assert any("entry point" in error for error in result.errors)


def test_typed_pattern_form_accepted():
    code = "def f : Nat -> Nat\n  | 0 => 0\n  | n + 1 => f n + (n + 1)"
    assert sanitize_model_code(code).accepted


def test_non_ascii_rejected():
    code = "def f (n : Nat) : Nat := id n \u2192 n"
    assert not sanitize_model_code(code).accepted


def test_oversize_rejected():
    code = "def f (n : Nat) : Nat := " + "1 + " * 5000 + "1"
    assert not sanitize_model_code(code).accepted


def test_huge_literal_rejected():
    code = "def big : Nat := 1234567890123456\n\ndef f (n : Nat) : Nat := n"
    assert not sanitize_model_code(code).accepted


def test_banned_word_in_comment_allowed():
    code = "def f (n : Nat) : Nat := n -- TODO: remove the sorry later"
    assert sanitize_model_code(code).accepted


def test_too_many_defs_rejected():
    helpers = "\n".join(f"def h{i} (m : Nat) : Nat := m" for i in range(25))
    code = helpers + "\n\ndef f (n : Nat) : Nat := h0 n"
    assert not sanitize_model_code(code).accepted


def test_strip_comments_nested_block():
    source = "def a : Nat := 1\n/- outer /- inner -/ still comment -/\ndef b : Nat := 2"
    cleaned = strip_comments(source)
    assert "inner" not in cleaned
    assert "def a" in cleaned
    assert "def b" in cleaned
