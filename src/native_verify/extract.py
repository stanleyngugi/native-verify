from __future__ import annotations

import re

FENCE_RE = re.compile(r"```(?:lean|lean4)?\s*\n(.*?)```", re.DOTALL)


def extract_artifact(response_text: str) -> str | None:
    blocks = FENCE_RE.findall(response_text)
    if not blocks:
        return None
    return blocks[-1].strip()
