from __future__ import annotations

import re

from .types import SanitizeResult

MAX_CHARS = 10000
MAX_LINES = 500
MAX_DEFS = 20
MAX_LITERAL_DIGITS = 12

BANNED_CHARS = {'"', "`", "@", "\\", "#"}

CHAR_LITERAL_RE = re.compile(r"'(\\.|[^'\\\n])'")

BANNED_WORDS = (
    "admit",
    "attribute",
    "axiom",
    "by",
    "class",
    "Classical",
    "csimp",
    "decide",
    "decreasing_by",
    "deriving",
    "do",
    "elab",
    "end",
    "example",
    "extern",
    "Float",
    "Float32",
    "implemented_by",
    "import",
    "inductive",
    "initialize",
    "instance",
    "IO",
    "lemma",
    "macro",
    "macro_rules",
    "mutual",
    "native_decide",
    "namespace",
    "ofReduceBool",
    "ofReduceNat",
    "opaque",
    "open",
    "partial",
    "prelude",
    "run_cmd",
    "run_elab",
    "section",
    "set_option",
    "sorry",
    "structure",
    "syntax",
    "theorem",
    "unsafe",
    "where",
)

RESERVED_NAMES = {"f", "trainExpected", "holdoutExpected"}
ENTRY_SIG_EXPLICIT_RE = re.compile(r"^def\s+f\s*\(\s*n\s*:\s*Nat\s*\)\s*:\s*Nat\s*:=")
ENTRY_SIG_TYPED_RE = re.compile(r"^def\s+f\s*:\s*Nat\s*->\s*Nat\s*$")
DEF_NAME_RE = re.compile(r"^def\s+([A-Za-z][A-Za-z0-9_]*)")
HELPER_NAME_RE = re.compile(r"^[a-z][A-Za-z0-9_]*$")
LITERAL_RE = re.compile(r"\d+")
IDENT_RE = re.compile(r"[A-Za-z_][A-Za-z0-9_]*")


def sanitize_model_code(model_code: str) -> SanitizeResult:
    errors: list[str] = []
    cleaned = strip_comments(model_code)

    if len(model_code) > MAX_CHARS:
        errors.append(f"model_code exceeds {MAX_CHARS} characters")
    if len(model_code.splitlines()) > MAX_LINES:
        errors.append(f"model_code exceeds {MAX_LINES} lines")

    for index, ch in enumerate(model_code):
        if ord(ch) > 127 or (ord(ch) < 32 and ch != "\n" and ch != "\t"):
            errors.append(f"disallowed character at offset {index}")
            break
    for ch in BANNED_CHARS:
        if ch in model_code:
            errors.append(f"banned character {ch!r} in model_code")
    if CHAR_LITERAL_RE.search(model_code):
        errors.append("char literals are not allowed")

    for word in BANNED_WORDS:
        pattern = re.compile(r"\b" + re.escape(word) + r"\b")
        if pattern.search(cleaned):
            errors.append(f"banned token `{word}` in model_code")

    for match in LITERAL_RE.finditer(cleaned):
        if len(match.group(0)) > MAX_LITERAL_DIGITS:
            errors.append(
                f"numeric literal exceeds {MAX_LITERAL_DIGITS} digits: {match.group(0)[:20]}"
            )
            break

    def_headers = _def_headers(cleaned.splitlines())
    names: list[str] = []
    entry_found = False
    for header in def_headers:
        name_match = DEF_NAME_RE.match(header)
        if name_match is None:
            errors.append(f"unparsable top-level declaration: {header.strip()[:60]}")
            continue
        name = name_match.group(1)
        names.append(name)
        if name == "f":
            entry_found = True
            collapsed = _collapse(header)
            if not (
                ENTRY_SIG_EXPLICIT_RE.match(collapsed) or ENTRY_SIG_TYPED_RE.match(collapsed)
            ):
                errors.append(
                    "entry point must be `def f (n : Nat) : Nat :=` "
                    "or `def f : Nat -> Nat` with match patterns"
                )
            continue
        if not HELPER_NAME_RE.match(name):
            errors.append(f"helper name `{name}` must start with a lowercase letter")
        if name in RESERVED_NAMES:
            errors.append(f"helper name `{name}` is reserved")
        if name.startswith("verify") or name.startswith("_"):
            errors.append(f"helper name `{name}` uses a forbidden prefix")

    if len(names) > MAX_DEFS:
        errors.append(f"more than {MAX_DEFS} defs")
    if not entry_found:
        errors.append("missing entry point `def f (n : Nat) : Nat :=`")
    if names.count("f") > 1:
        errors.append("duplicate entry point `f`")

    trimmed = "\n".join(line.rstrip() for line in cleaned.splitlines()).strip("\n")
    if errors:
        return SanitizeResult(accepted=False, reason=errors[0], errors=errors)
    return SanitizeResult(accepted=True, model_code=trimmed)


def strip_comments(source: str) -> str:
    out: list[str] = []
    depth = 0
    i = 0
    while i < len(source):
        if depth > 0:
            if source.startswith("/-", i):
                depth += 1
                i += 2
                continue
            if source.startswith("-/", i):
                depth -= 1
                i += 2
                continue
            if source[i] == "\n":
                out.append("\n")
            i += 1
            continue
        if source.startswith("--", i):
            while i < len(source) and source[i] != "\n":
                i += 1
            continue
        if source.startswith("/-", i):
            depth += 1
            i += 2
            continue
        out.append(source[i])
        i += 1
    return "".join(out)


def _def_headers(lines: list[str]) -> list[str]:
    headers: list[str] = []
    for line in lines:
        stripped = line.strip()
        if not stripped:
            continue
        if line[0].isspace() or stripped.startswith("|"):
            continue
        headers.append(line)
    return headers


def _collapse(text: str) -> str:
    return re.sub(r"\s+", " ", text.strip())
