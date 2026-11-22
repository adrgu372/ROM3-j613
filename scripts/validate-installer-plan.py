#!/usr/bin/env python3
"""Validate ROM3 installer profile and payload planning metadata."""

from __future__ import annotations

import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parent.parent


def fail(message: str) -> None:
    print(f"error: {message}", file=sys.stderr)
    raise SystemExit(1)


def main() -> int:
    profile = json.loads((ROOT / "installer" / "profile.json").read_text())
    payload = json.loads((ROOT / "installer" / "payload-plan.json").read_text())

    if profile.get("distribution") != "ROM3-j613":
        fail("profile distribution mismatch")
    if profile.get("upstream_distribution_profile") != "arch-kde":
        fail("initial installer must reuse arch-kde")
    if profile.get("device_identifiers") != ["apple,j613"]:
        fail("installer profile must target only apple,j613")

    if payload.get("distribution") != "ROM3-j613":
        fail("payload distribution mismatch")
    if payload.get("profile") != "arch-kde":
        fail("payload profile mismatch")
    if "rom3-j613-release" not in payload.get("required_packages", []):
        fail("payload must install rom3-j613-release")
    if "cold_boot" not in payload.get("required_checks", []):
        fail("payload plan must require cold boot")

    print("ROM3 installer planning metadata is valid.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

