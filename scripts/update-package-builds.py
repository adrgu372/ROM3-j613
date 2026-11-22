#!/usr/bin/env python3
"""Generate stack/package-builds.json from local artifact archives."""

from __future__ import annotations

import json
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parent.parent
ARTIFACTS = ROOT / "artifacts"
OUTPUT = ROOT / "stack" / "package-builds.json"


def field(info: str, name: str) -> str:
    prefix = name + " "
    for line in info.splitlines():
        if line.startswith(prefix):
            return line[len(prefix):].strip()
    raise SystemExit(f"missing {name} in package metadata")


def main() -> int:
    artifacts = []
    for package in sorted(ARTIFACTS.glob("*.pkg.tar.*")):
        if package.name.endswith(".sig"):
            continue
        info = subprocess.check_output(["pacman", "-Qip", package], text=True)
        artifacts.append(
            {
                "package": field(info, "Name"),
                "version": field(info, "Version"),
                "file": package.name,
                "sha256": subprocess.check_output(
                    ["sha256sum", package], text=True
                ).split()[0],
            }
        )

    artifacts.sort(key=lambda item: item["package"])
    OUTPUT.write_text(
        json.dumps(
            {
                "schema_version": 1,
                "distribution": "ROM3-j613",
                "artifacts": artifacts,
            },
            indent=2,
        )
        + "\n"
    )
    print(f"Wrote {len(artifacts)} artifacts to {OUTPUT}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

