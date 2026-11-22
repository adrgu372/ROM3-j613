#!/usr/bin/env python3
"""Compare the running package set with ROM3's verified stack."""

from __future__ import annotations

import json
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parent.parent
STACK = ROOT / "stack" / "verified-stack.json"


def installed() -> dict[str, str]:
    output = subprocess.check_output(["pacman", "-Q"], text=True)
    result = {}
    for line in output.splitlines():
        name, version = line.split(maxsplit=1)
        result[name] = version
    return result


def main() -> int:
    data = json.loads(STACK.read_text())
    packages = data["packages"]
    current = installed()
    failures = []

    for name, expected in packages.items():
        actual = current.get(name)
        if actual == expected:
            print(f"ok      {name} {actual}")
        else:
            failures.append((name, expected, actual))
            print(f"MISMATCH {name}: expected {expected}, found {actual or 'missing'}")

    if failures:
        print(f"\n{len(failures)} package mismatches", file=sys.stderr)
        return 1

    print("\nRunning package set matches the verified ROM3-j613 stack.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

