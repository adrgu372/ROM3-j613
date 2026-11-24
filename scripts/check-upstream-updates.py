#!/usr/bin/env python3
"""Report upstream changes and whether they justify a ROM3 rebuild."""

from __future__ import annotations

import argparse
import datetime
import json
from pathlib import Path
import re
import subprocess
import sys
import urllib.parse

ROOT = Path(__file__).resolve().parent.parent
STATE_MARKER = re.compile(
    r"<!-- ROM3_WATCH_STATE\n(.*?)\n-->",
    re.DOTALL,
)
CATEGORY_RULES = (
    (re.compile(r"(^|/)arch/arm64/boot/dts/apple/(t8122|t602)", re.I), "J613 DT"),
    (
        re.compile(
            r"drivers/(gpu/drm/(apple|asahi)|mux/apple-)|"
            r"(display|pmp).*apple",
            re.I,
        ),
        "display/GPU",
    ),
    (
        re.compile(r"drivers/media/platform/apple/|apple.*isp|isp.*apple", re.I),
        "camera/ISP",
    ),
    (
        re.compile(r"sound/soc/apple/|apple.*audio|speaker", re.I),
        "audio",
    ),
    (
        re.compile(r"drivers/(soc|pmdomain|firmware)/apple/|t8122|pmp", re.I),
        "power/firmware",
    ),
)
IMPORTANT_WORDS = re.compile(
    r"\b("
    r"cve[- ]?\d+|security|regression|panic|crash|lockup|hang|"
    r"blank|display|gpu|isp|camera|audio|speaker|mca|dcp|pmp|"
    r"j613|t8122|suspend|resume|wifi|bluetooth|usb"
    r")\b",
    re.I,
)
FIX_WORDS = re.compile(
    r"\b(fix|repair|correct|restore|prevent|avoid|revert|workaround)\b",
    re.I,
)


def gh_api(endpoint: str) -> dict:
    command = ["gh", "api", endpoint]
    error = ""
    for _ in range(3):
        result = subprocess.run(
            command,
            text=True,
            capture_output=True,
        )
        if result.returncode == 0:
            return json.loads(result.stdout)
        error = result.stderr.strip()
    raise RuntimeError(f"gh api failed for {endpoint}: {error}")


def encoded_ref(reference: str) -> str:
    return urllib.parse.quote(reference, safe="")


def extract_pin(path: Path, expression: str) -> str:
    match = re.search(expression, path.read_text())
    if not match:
        raise RuntimeError(f"could not find a commit pin in {path}")
    return match.group(1)


def message_text(commit: dict) -> str:
    return commit.get("commit", {}).get("message", "").splitlines()[0]


def compare(repository: str, base: str, head: str) -> dict:
    return gh_api(
        f"repos/{repository}/compare/{base}..."
        f"{encoded_ref(head)}"
    )


def current_head(repository: str, branch: str) -> tuple[str, str]:
    try:
        data = gh_api(f"repos/{repository}/commits/{encoded_ref(branch)}")
        return branch, data["sha"]
    except RuntimeError:
        info = gh_api(f"repos/{repository}")
        fallback = info["default_branch"]
        data = gh_api(f"repos/{repository}/commits/{encoded_ref(fallback)}")
        return fallback, data["sha"]


def classify(source: dict, files: list[str], messages: list[str]) -> tuple[str, list[str]]:
    def is_critical(path: str) -> bool:
        return any(
            path.startswith(prefix) if prefix else True
            for prefix in source["critical_paths"]
        )

    critical = [
        path
        for path in files
        if is_critical(path)
    ]
    categories = sorted(
        {
            label
            for path in files
            for pattern, label in CATEGORY_RULES
            if pattern.search(path)
        }
    )
    text = "\n".join(messages)
    important_words = sorted(
        {match.group(0).lower() for match in IMPORTANT_WORDS.finditer(text)}
    )
    meaningful_fix = bool(important_words and FIX_WORDS.search(text))
    role = source["role"]
    has_changes = bool(files or messages)

    if role == "kernel":
        if (
            critical
            or meaningful_fix
            or any(
                word in {"cve", "security", "regression", "panic", "crash"}
                for word in important_words
            )
        ) and (
            any("J613 DT" in item for item in categories)
            or meaningful_fix
            or important_words
        ):
            decision = "BUILD CANDIDATE"
        elif critical:
            decision = "REVIEW"
        elif has_changes:
            decision = "REVIEW"
        else:
            decision = "WAIT"
    elif role in {"aura", "audio"}:
        decision = "REVIEW MATCHED STACK" if critical else "WAIT"
    elif role in {"image", "installer"}:
        decision = "REVIEW REBUILD" if has_changes else "WAIT"
    else:
        decision = "REVIEW" if has_changes else "WAIT"
    return decision, categories


def read_previous_state(previous_report: Path | None, state_file: Path | None) -> dict:
    if state_file and state_file.is_file():
        return json.loads(state_file.read_text())
    if previous_report and previous_report.is_file():
        match = STATE_MARKER.search(previous_report.read_text())
        if match:
            return json.loads(match.group(1))
    return {"schema_version": 1, "sources": {}}


def render_report(
    generated_at: datetime.datetime,
    results: list[dict],
    errors: list[str],
    state: dict,
) -> str:
    decisions = {item["decision"] for item in results if item["new_commits"]}
    if "BUILD CANDIDATE" in decisions:
        overall = "BUILD CANDIDATE"
        summary = (
            "A new kernel change touches a J613-critical subsystem or appears "
            "to fix a relevant crash, display, GPU, camera, audio or security issue."
        )
    elif decisions & {"REVIEW MATCHED STACK", "REVIEW REBUILD"}:
        overall = "REVIEW"
        summary = (
            "Upstream changed a matched package, image-builder or installer "
            "component. Review it before the next ROM3 snapshot."
        )
    elif decisions:
        overall = "REVIEW"
        summary = (
            "New upstream commits exist, but none currently match the highest-"
            "priority J613 paths automatically."
        )
    else:
        overall = "WAIT"
        summary = "No relevant upstream change since the previous daily check."

    lines = [
        "# ROM3-j613 daily upstream watch",
        "",
        f"Generated: `{generated_at.isoformat()}`",
        "",
        "## Decision",
        "",
        f"**{overall}** — {summary}",
        "",
        "This monitor never compiles or publishes packages. A kernel build still",
        "requires the qualification and rollback process described in",
        "[`docs/update-model.md`](https://github.com/adrgu372/ROM3-j613/blob/main/docs/update-model.md).",
        "",
        "## Sources",
        "",
        "| Source | Branch | Pinned | Upstream | Ahead | Behind | New | Relevant | Decision |",
        "|---|---|---:|---:|---:|---:|---:|---:|---|",
    ]
    for item in results:
        lines.append(
            "| {id} | `{branch}` | `{pin}` | `{head}` | {ahead} | {behind} | "
            "{new} | {relevant} | **{decision}** |".format(
                id=item["id"],
                branch=item["branch"],
                pin=item["pin"][:12],
                head=item["head"][:12],
                ahead=item["ahead_of_pin"],
                behind=item["behind_pin"],
                new=item["new_commits"],
                relevant=len(item["critical_files"]),
                decision=item["decision"],
            )
        )

    lines.extend(["", "## Change details", ""])
    changed_any = False
    for item in results:
        if not item["new_commits"]:
            continue
        changed_any = True
        lines.extend(
            [
                f"### {item['id']}",
                "",
                f"- Decision: **{item['decision']}**",
                f"- Branch: `{item['branch']}`",
                f"- Previous branch: `{item['previous_branch'] or 'baseline'}`",
                f"- New commits: `{item['new_commits']}`",
                f"- Pin distance observed: `{item['ahead_of_pin']}` ahead, "
                f"`{item['behind_pin']}` behind",
                f"- Categories: {', '.join(item['categories']) or 'none'}",
            ]
        )
        for message in item["messages"][:12]:
            lines.append(f"- {message}")
        if item["critical_files"]:
            lines.extend(["", "Relevant files:"])
            for path in item["critical_files"][:20]:
                lines.append(f"- `{path}`")
        lines.append("")
    if not changed_any:
        lines.extend(
            [
                "No new commits were observed. Existing distance from the pinned",
                "snapshot remains visible in the table but is not a daily build cue.",
                "",
            ]
        )

    if errors:
        lines.extend(["## Errors", ""])
        lines.extend(f"- {error}" for error in errors)
        lines.append("")

    if any(
        item["ahead_of_pin"] > 0 and item["new_commits"] == 0
        for item in results
    ):
        lines.extend(
            [
                "## Note",
                "",
                "A non-zero pin distance is expected between planned ROM3 snapshots.",
                "Promote a new upstream baseline deliberately, not merely because the",
                "counter increased.",
                "",
            ]
        )

    state_json = json.dumps(state, sort_keys=True, separators=(",", ":"))
    lines.extend(
        [
            "<!-- ROM3_WATCH_STATE",
            state_json,
            "-->",
            "",
        ]
    )
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--config",
        type=Path,
        default=ROOT / "maintenance/watch-sources.json",
    )
    parser.add_argument("--previous-report", type=Path)
    parser.add_argument("--state-in", type=Path)
    parser.add_argument("--state-out", type=Path, required=True)
    parser.add_argument("--report", type=Path, required=True)
    args = parser.parse_args()

    config = json.loads(args.config.read_text())
    if config.get("schema_version") != 1:
        raise SystemExit("watch config schema_version must be 1")
    sources = config.get("sources")
    if not isinstance(sources, list) or not sources:
        raise SystemExit("watch config needs a non-empty sources list")

    previous = read_previous_state(args.previous_report, args.state_in)
    previous_sources = previous.get("sources", {})
    generated_at = datetime.datetime.now(datetime.timezone.utc).replace(
        microsecond=0
    )
    next_sources: dict[str, str] = {}
    results = []
    errors = []

    for source in sources:
        source_id = source["id"]
        repository = source["repository"]
        configured_branch = source["branch"]
        try:
            pin = extract_pin(ROOT / source["pin_file"], source["pin_regex"])
            branch, head = current_head(repository, configured_branch)
            distance = compare(repository, pin, branch)
            previous_entry = previous_sources.get(source_id)
            if isinstance(previous_entry, dict):
                previous_head = previous_entry.get("sha")
                previous_branch = previous_entry.get("branch")
            else:
                previous_head = previous_entry
                previous_branch = None
            commits: list[dict] = []
            files: list[str] = []
            new_commit_count = 0
            if previous_head and previous_head != head:
                change = compare(repository, previous_head, head)
                commits = change.get("commits", [])
                new_commit_count = int(
                    change.get("ahead_by", len(commits))
                )
                files = sorted(
                    {
                        item["filename"]
                        for item in change.get("files", [])
                        if item.get("filename")
                    }
                )
            messages = [message_text(commit) for commit in commits]
            decision, categories = classify(source, files, messages)
            critical_files = [
                path
                for path in files
                if any(
                    path.startswith(prefix) if prefix else True
                    for prefix in source["critical_paths"]
                )
            ]
            results.append(
                {
                    "id": source_id,
                    "role": source["role"],
                    "branch": branch,
                    "previous_branch": previous_branch,
                    "pin": pin,
                    "head": head,
                    "ahead_of_pin": int(distance.get("ahead_by", 0)),
                    "behind_pin": int(distance.get("behind_by", 0)),
                    "new_commits": new_commit_count,
                    "critical_files": critical_files,
                    "categories": categories,
                    "messages": messages,
                    "decision": decision,
                }
            )
            next_sources[source_id] = {
                "sha": head,
                "branch": branch,
            }
        except (RuntimeError, KeyError, ValueError) as error:
            errors.append(f"{source_id}: {error}")

    if errors and len(errors) == len(sources):
        print("\n".join(errors), file=sys.stderr)
        return 1

    state = {
        "schema_version": 1,
        "checked_at": generated_at.isoformat(),
        "sources": next_sources,
    }
    report = render_report(generated_at, results, errors, state)
    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.state_out.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text(report)
    args.state_out.write_text(json.dumps(state, indent=2) + "\n")
    print(report)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
