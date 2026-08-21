from __future__ import annotations

from dataclasses import dataclass, field


@dataclass(slots=True)
class SanitizeResult:
    accepted: bool
    model_code: str = ""
    reason: str | None = None
    errors: list[str] = field(default_factory=list)


@dataclass(slots=True)
class Verdict:
    accepted: bool
    stage: str
    reason: str | None
    diagnostics: list[str] = field(default_factory=list)
    duration_ms: int = 0
    backend: str = ""
