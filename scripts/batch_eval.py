import argparse
import json
import os
import re
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "src"))

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

from native_verify import verify
from native_verify.canonical import canonicalize_unicode
from native_verify.tasks import FAMILIES, generate_tasks

SYSTEM_PROMPT = (
    "You are an expert Lean 4 programmer. You will receive a sequence problem. "
    "Respond with exactly one ```lean code block containing the definition "
    "`def f (n : Nat) : Nat` computing the sequence, plus optional helper "
    "definitions. Constraints: pure computational definitions only. No imports, "
    "no attributes (@[...]), no theorems, no `sorry`, no `partial`, no `unsafe`. "
    "Use structural recursion or explicit fuel loops for recursion. "
    "ASCII only: write `->` for function arrows, never the Unicode arrow character. "
    "Define f either as `def f (n : Nat) : Nat := ...` or as `def f : Nat -> Nat` "
    "with match patterns."
)


def _chat_request(url: str, payload: dict, api_key: str, timeout: float):
    request = urllib.request.Request(
        url,
        data=json.dumps(payload).encode("utf-8"),
        headers={
            "Content-Type": "application/json",
            "Authorization": f"Bearer {api_key}",
            "User-Agent": "native-verify/0.1",
        },
        method="POST",
    )
    with urllib.request.urlopen(request, timeout=timeout) as response:
        return json.loads(response.read().decode("utf-8"))

FENCE_RE = re.compile(r"```(?:lean|lean4)?\s*\n(.*?)```", re.DOTALL)


def extract_artifact(response_text: str) -> str | None:
    blocks = FENCE_RE.findall(response_text)
    if not blocks:
        return None
    return blocks[-1].strip()


def chat_completion(
    base_url: str,
    api_key: str,
    model: str,
    user_message: str,
    temperature: float,
    max_tokens: int,
) -> tuple[str | None, str | None]:
    url = base_url.rstrip("/") + "/chat/completions"
    payload = {
        "model": model,
        "messages": [
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content": user_message},
        ],
        "temperature": temperature,
        "max_tokens": max_tokens,
    }
    last_error = None
    for attempt in range(4):
        try:
            body = _chat_request(url, payload, api_key, timeout=120)
            break
        except urllib.error.HTTPError as exc:
            detail = exc.read().decode("utf-8", "replace")[:200]
            last_error = f"http_{exc.code}:{detail}"
            if exc.code == 429 and attempt < 3:
                time.sleep(15 * (attempt + 1))
                continue
            return None, last_error
        except (urllib.error.URLError, TimeoutError, OSError) as exc:
            return None, f"request_error:{exc}"
    try:
        content = body["choices"][0]["message"]["content"]
    except (KeyError, IndexError, TypeError, UnboundLocalError):
        return None, f"malformed_response:{json.dumps(body)[:200]}"
    return content, None


def run_eval(args: argparse.Namespace) -> int:
    api_key = os.getenv(args.api_key_env, "")
    if not api_key:
        print(f"error: environment variable {args.api_key_env} is not set", file=sys.stderr)
        return 2

    tasks = generate_tasks(
        families=None if args.families == "all" else args.families.split(","),
        per_family=args.per_family,
        seed=args.seed,
    )
    out_path = Path(args.out)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    rows: list[dict] = []

    with out_path.open("w", encoding="utf-8") as handle:
        for task in tasks:
            row: dict = {
                "task_id": task.task_id,
                "family": task.family,
                "difficulty": task.difficulty,
            }
            content, error = chat_completion(
                args.base_url,
                api_key,
                args.model,
                task.prompt,
                args.temperature,
                args.max_tokens,
            )
            if error is not None:
                row.update(stage="api_error", accepted=False, reason=error)
            else:
                artifact = extract_artifact(content)
                if artifact is None:
                    row.update(stage="extract", accepted=False, reason="no_lean_fence")
                elif len(artifact) > 10000:
                    row.update(stage="extract", accepted=False, reason="artifact_too_large")
                else:
                    artifact = canonicalize_unicode(artifact)
                    verdict = verify(
                        artifact,
                        task.train_values,
                        task.holdout_values,
                        timeout_seconds=args.verify_timeout,
                    )
                    row.update(
                        stage=verdict.stage,
                        accepted=verdict.accepted,
                        reason=verdict.reason,
                        duration_ms=verdict.duration_ms,
                    )
                    if args.save_artifacts:
                        row["artifact"] = artifact
            rows.append(row)
            handle.write(json.dumps(row) + "\n")
            handle.flush()
            marker = "OK " if row.get("accepted") else "FAIL"
            print(f"[{marker}] {task.task_id:16} stage={row['stage']:12} {row.get('reason') or ''}")

    accepted = sum(1 for row in rows if row.get("accepted"))
    print("\n== summary ==")
    print(f"tasks={len(rows)} accepted={accepted} rate={accepted / max(len(rows), 1):.2%}")
    by_stage: dict[str, int] = {}
    for row in rows:
        by_stage[row["stage"]] = by_stage.get(row["stage"], 0) + 1
    for stage in sorted(by_stage):
        print(f"  stage {stage}: {by_stage[stage]}")
    by_family: dict[str, list[int]] = {}
    for row in rows:
        stats = by_family.setdefault(row["family"], [0, 0])
        stats[1] += 1
        if row.get("accepted"):
            stats[0] += 1
    for family in sorted(by_family):
        hit, total = by_family[family]
        print(f"  family {family}: {hit}/{total}")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Batch-eval a model against generated tasks.")
    parser.add_argument("--base-url", default=os.getenv("NATIVE_VERIFY_BASE_URL", "https://api.primeintellect.ai/api/v1"))
    parser.add_argument("--model", required=True)
    parser.add_argument("--api-key-env", default="NATIVE_VERIFY_API_KEY")
    parser.add_argument("--families", default="all", help="comma-separated family names or 'all'")
    parser.add_argument("--per-family", type=int, default=4)
    parser.add_argument("--seed", type=int, default=0)
    parser.add_argument("--temperature", type=float, default=0.7)
    parser.add_argument("--max-tokens", type=int, default=2048)
    parser.add_argument("--verify-timeout", type=float, default=60.0)
    parser.add_argument("--out", default="artifacts/batch_eval.jsonl")
    parser.add_argument("--save-artifacts", action="store_true")
    args = parser.parse_args()
    return run_eval(args)


if __name__ == "__main__":
    raise SystemExit(main())
