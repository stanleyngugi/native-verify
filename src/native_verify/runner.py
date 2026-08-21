from __future__ import annotations

import os
import re
import shutil
import subprocess
import sys
import tempfile
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Sequence

from .sanitizer import sanitize_model_code
from .template import build_checker_source
from .types import Verdict

ERROR_LINE_RE = re.compile(r":(\d+):\d+:\s*error")
PROBE_TIMEOUT_SECONDS = 20.0


@dataclass(slots=True)
class LeanBackend:
    mode: str
    executable: str


WSL_NATIVE_HOME_PREFIX = "$HOME/.native-verify/pinned"


def locate_lean(explicit: str | None = None) -> LeanBackend | None:
    candidates: list[LeanBackend] = []
    if explicit:
        candidates.append(_explicit_backend(explicit))
    env = os.getenv("NATIVE_VERIFY_LEAN") or os.getenv("LEAN_BIN")
    if env:
        candidates.append(_explicit_backend(env))

    if _is_windows():
        candidates.append(
            LeanBackend(
                mode="wsl_native",
                executable=f"{WSL_NATIVE_HOME_PREFIX}/lean-4.23.0-linux/bin/lean",
            )
        )

        own_root = Path(__file__).resolve().parents[2]
        folder_root = Path(__file__).resolve().parents[3]

        for base in (folder_root / "aimo", own_root):
            linux_lean = (
                base
                / "local"
                / "runtime"
                / "tools"
                / "pinned"
                / "lean-4.23.0-linux"
                / "bin"
                / "lean"
            )
            if linux_lean.is_file():
                candidates.append(LeanBackend(mode="wsl", executable=str(linux_lean)))
        windows_lean = (
            own_root
            / "local"
            / "runtime"
            / "tools"
            / "pinned"
            / "lean-4.23.0-windows"
            / "bin"
            / "lean.exe"
        )
        if windows_lean.is_file():
            candidates.append(LeanBackend(mode="direct", executable=str(windows_lean)))

    discovered = shutil.which("lean") or shutil.which("lean.exe")
    if discovered:
        candidates.append(LeanBackend(mode="direct", executable=discovered))

    seen: set[tuple[str, str]] = set()
    for candidate in candidates:
        key = (candidate.mode, candidate.executable)
        if key in seen:
            continue
        seen.add(key)
        if _probe(candidate):
            return candidate
    return None


def _is_windows() -> bool:
    return sys.platform == "win32"


def _explicit_backend(path: str) -> LeanBackend:
    if _is_windows() and path.startswith("/"):
        return LeanBackend(mode="wsl", executable=path)
    if path.startswith("~") or path.startswith("$"):
        return LeanBackend(mode="wsl_native", executable=path)
    return LeanBackend(mode="direct", executable=path)


def verify(
    model_code: str,
    train_values: Sequence[int],
    holdout_values: Sequence[int],
    *,
    lean_bin: str | None = None,
    timeout_seconds: float = 60.0,
) -> Verdict:
    start = time.perf_counter()

    def elapsed_ms() -> int:
        return int((time.perf_counter() - start) * 1000)

    sanitized = sanitize_model_code(model_code)
    if not sanitized.accepted:
        return Verdict(
            accepted=False,
            stage="sanitize",
            reason=sanitized.reason,
            diagnostics=sanitized.errors[:10],
            duration_ms=elapsed_ms(),
            backend="none",
        )

    try:
        source, markers = build_checker_source(sanitized.model_code, train_values, holdout_values)
    except ValueError as exc:
        return Verdict(
            accepted=False,
            stage="internal",
            reason=f"template_error:{exc}",
            duration_ms=elapsed_ms(),
            backend="none",
        )

    backend = locate_lean(lean_bin)
    if backend is None:
        return Verdict(
            accepted=False,
            stage="internal",
            reason="lean_not_found",
            duration_ms=elapsed_ms(),
            backend="none",
        )

    tmpdir = tempfile.mkdtemp(prefix="native_verify_")
    script_path = Path(tmpdir) / "checker.lean"
    script_path.write_text(source, encoding="utf-8")
    command = _build_command(backend, script_path)

    try:
        proc = subprocess.run(
            command,
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
            timeout=timeout_seconds,
            cwd=tmpdir,
        )
    except subprocess.TimeoutExpired:
        return Verdict(
            accepted=False,
            stage="timeout",
            reason="checker_timeout",
            duration_ms=elapsed_ms(),
            backend=backend.mode,
        )
    except OSError as exc:
        return Verdict(
            accepted=False,
            stage="internal",
            reason=f"execution_failed:{exc}",
            duration_ms=elapsed_ms(),
            backend=backend.mode,
        )
    finally:
        shutil.rmtree(tmpdir, ignore_errors=True)

    output = proc.stdout + "\n" + proc.stderr
    error_lines = [line.strip() for line in output.splitlines() if ": error" in line]
    if proc.returncode == 0 and not error_lines:
        return Verdict(
            accepted=True,
            stage="verified",
            reason=None,
            duration_ms=elapsed_ms(),
            backend=backend.mode,
        )
    stage, reason = classify_failure(output, markers)
    diagnostics = error_lines[:10] or [line.strip() for line in output.splitlines() if line.strip()][-5:]
    return Verdict(
        accepted=False,
        stage=stage,
        reason=reason,
        diagnostics=diagnostics,
        duration_ms=elapsed_ms(),
        backend=backend.mode,
    )


def classify_failure(output: str, markers: dict[str, int]) -> tuple[str, str]:
    match = ERROR_LINE_RE.search(output)
    if match is None:
        return "compile", "unknown_failure"
    line_no = int(match.group(1))
    if line_no >= markers["verify_holdout"]:
        return "holdout_check", "holdout_mismatch"
    if line_no >= markers["verify_train"]:
        return "train_check", "train_mismatch"
    return "compile", "model_or_template_error"


def _build_command(backend: LeanBackend, script_path: Path) -> list[str]:
    if backend.mode == "direct":
        return [backend.executable, str(script_path)]
    if backend.mode == "wsl":
        return ["wsl", "-e", _to_wsl_path(backend.executable), _to_wsl_path(script_path)]
    return [
        "wsl",
        "-e",
        "bash",
        "-c",
        f"{backend.executable} {_to_wsl_path(script_path)}",
    ]


def _probe(backend: LeanBackend) -> bool:
    if backend.mode == "direct":
        command = [backend.executable, "--version"]
    elif backend.mode == "wsl":
        command = ["wsl", "-e", _to_wsl_path(backend.executable), "--version"]
    else:
        command = ["wsl", "-e", "bash", "-c", f"{backend.executable} --version"]
    try:
        result = subprocess.run(
            command,
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
            timeout=PROBE_TIMEOUT_SECONDS,
        )
    except (OSError, subprocess.TimeoutExpired):
        return False
    return result.returncode == 0


def _to_wsl_path(path: Path | str) -> str:
    if isinstance(path, str) and path.startswith("/"):
        return path
    resolved = Path(path).resolve()
    drive = resolved.drive.rstrip(":").lower()
    rest = str(resolved)[len(resolved.drive):].replace("\\", "/")
    return f"/mnt/{drive}{rest}"
