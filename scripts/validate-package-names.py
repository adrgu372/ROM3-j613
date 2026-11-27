#!/usr/bin/env python3
"""Reject Aurora/Aura branding in ROM3 package identifiers."""

from __future__ import annotations

from pathlib import Path
import re
import subprocess
import sys


ROOT = Path(__file__).resolve().parent.parent
PACKAGES = ROOT / "packages"
FORBIDDEN = re.compile(r"aura|aurora", re.IGNORECASE)


def main() -> int:
    failures: list[str] = []
    names: dict[str, Path] = {}

    for pkgbuild in sorted(PACKAGES.glob("*/PKGBUILD")):
        result = subprocess.run(
            ["makepkg", "--printsrcinfo"],
            cwd=pkgbuild.parent,
            text=True,
            capture_output=True,
            check=False,
        )
        if result.returncode != 0:
            failures.append(
                f"{pkgbuild.parent.name}: makepkg --printsrcinfo failed: "
                f"{result.stderr.strip()}"
            )
            continue

        values = re.findall(
            r"^\s*pkgbase = (.+)$",
            result.stdout,
            flags=re.MULTILINE,
        )
        for name in values:
            if FORBIDDEN.search(name):
                failures.append(f"{pkgbuild}: forbidden pkgbase {name}")

        values = re.findall(
            r"^\s*pkgname = (.+)$",
            result.stdout,
            flags=re.MULTILINE,
        )
        for name in values:
            if FORBIDDEN.search(name):
                failures.append(f"{pkgbuild}: forbidden package identifier {name}")
            if name in names:
                failures.append(
                    f"duplicate package identifier {name}: "
                    f"{names[name]} and {pkgbuild}"
                )
            else:
                names[name] = pkgbuild

    if failures:
        print("\n".join(f"error: {failure}" for failure in failures), file=sys.stderr)
        return 1

    print(f"Validated {len(names)} ROM3 package identifiers.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
