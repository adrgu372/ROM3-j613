#!/usr/bin/env python3
"""Validate ROM3 stack metadata without touching the installed system."""

from __future__ import annotations

import json
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parent.parent
STACK = ROOT / "stack" / "verified-stack.json"
QUARANTINE = ROOT / "stack" / "quarantine.packages"

REQUIRED_KEYS = {
    "schema_version",
    "distribution",
    "channel",
    "verified_at",
    "source_baseline",
    "hardware",
    "kernel_release",
    "stage2_sha256",
    "packages",
    "required_outputs",
}


def fail(message: str) -> None:
    print(f"error: {message}", file=sys.stderr)
    raise SystemExit(1)


def main() -> int:
    data = json.loads(STACK.read_text())
    if data.keys() != REQUIRED_KEYS:
        fail(f"unexpected top-level keys: {sorted(data.keys())}")
    if data["schema_version"] != 1:
        fail("unsupported stack schema")
    if data["distribution"] != "ROM3-j613":
        fail("unexpected distribution name")
    if data["channel"] != "stable":
        fail("initial stack must be stable")
    if not re.fullmatch(r"[0-9a-f]{64}", data["stage2_sha256"]):
        fail("invalid Stage 2 digest")

    compatible = [item["compatible"] for item in data["hardware"]]
    if compatible != ["apple,j613"]:
        fail("initial ROM3 release must target only apple,j613")

    packages = data["packages"]
    quarantine = {
        line.strip()
        for line in QUARANTINE.read_text().splitlines()
        if line.strip() and not line.startswith("#")
    }
    if not quarantine:
        fail("quarantine list is empty")
    missing = quarantine - packages.keys()
    if missing:
        fail(f"quarantine packages lack verified versions: {sorted(missing)}")

    for name, version in packages.items():
        if not name or not version:
            fail("empty package name or version")

    print("ROM3-j613 stack metadata is valid.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

