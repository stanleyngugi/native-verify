from __future__ import annotations

UNICODE_ASCII_MAP = {
    "\u2192": "->",
    "\u21a6": "->",
    "\u00d7": "*",
    "\u2212": "-",
    "\u2264": "<=",
    "\u2265": ">=",
    "\u2260": "!=",
    "\u00a0": " ",
}


def canonicalize_unicode(text: str) -> str:
    result = text
    for source, target in UNICODE_ASCII_MAP.items():
        result = result.replace(source, target)
    return result
