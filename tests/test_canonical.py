from native_verify.canonical import canonicalize_unicode


def test_arrow_translated():
    assert canonicalize_unicode("def f : Nat \u2192 Nat") == "def f : Nat -> Nat"


def test_all_mappings():
    text = "\u2192 \u21a6 \u00d7 \u2212 \u2264 \u2265 \u2260\u00a0x"
    result = canonicalize_unicode(text)
    assert all(ord(c) < 128 for c in result)


def test_ascii_passthrough():
    source = "def f (n : Nat) : Nat := n + 1"
    assert canonicalize_unicode(source) == source
