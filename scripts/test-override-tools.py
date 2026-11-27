#!/usr/bin/env python3
"""Focused tests for the installed ROM3 override helper."""

from __future__ import annotations

import contextlib
import io
import json
from pathlib import Path
import runpy
import tempfile


ROOT = Path(__file__).resolve().parents[1]
MODULE = runpy.run_path(
    str(ROOT / "packages/rom3-j613-guard/rom3-j613-override")
)
validate_manifest = MODULE["validate_manifest"]
update_ignore_pkg = MODULE["update_ignore_pkg"]
update_include = MODULE["update_include"]


def sample_manifest() -> dict[str, object]:
    digest = "0" * 64
    return {
        "schema_version": 1,
        "distribution": "ROM3-j613",
        "base_snapshot": "stable-20261122.9",
        "packages": {"linux-rom3": "7.3.0.aurora1-44"},
        "artifacts": [
            {
                "package": "linux-rom3",
                "version": "7.3.0.aurora1-44",
                "file": "linux-rom3-7.3.0.aurora1-44-aarch64.pkg.tar.xz",
                "sha256": digest,
            }
        ],
    }


def main() -> int:
    manifest = validate_manifest(sample_manifest())
    assert manifest["packages"] == {"linux-rom3": "7.3.0.aurora1-44"}

    invalid = sample_manifest()
    invalid["artifacts"][0]["file"] = "../linux-rom3.pkg.tar.xz"
    with contextlib.redirect_stderr(io.StringIO()):
        try:
            validate_manifest(invalid)
        except SystemExit:
            pass
        else:
            raise AssertionError("unsafe artifact path was accepted")

    legacy = sample_manifest()
    legacy["packages"] = {"linux-aurora": "7.3.0.aurora1-44"}
    legacy["artifacts"][0].update(
        {
            "package": "linux-aurora",
            "file": "linux-aurora-7.3.0.aurora1-44-aarch64.pkg.tar.xz",
        }
    )
    with contextlib.redirect_stderr(io.StringIO()):
        try:
            validate_manifest(legacy)
        except SystemExit:
            pass
        else:
            raise AssertionError("legacy Aurora package name was accepted")

    with tempfile.TemporaryDirectory(prefix="rom3-override-test-") as temporary:
        path = Path(temporary) / "pacman.conf"
        path.write_text(
            "[options]\n"
            "IgnorePkg = kwin linux-rom3\n\n"
            "[rom3-j613]\n"
            "Include = /etc/pacman.d/rom3-j613.conf\n"
        )
        update_ignore_pkg(path, {"linux-rom3"}, remove=False)
        assert "IgnorePkg = kwin linux-rom3" in path.read_text()
        update_ignore_pkg(path, {"linux-rom3"}, remove=True)
        assert "IgnorePkg = kwin" in path.read_text()
        update_include(path, add=True)
        assert path.read_text().index("rom3-j613-overrides.conf") < path.read_text().index(
            "Include = /etc/pacman.d/rom3-j613.conf"
        )
        update_include(path, add=False)
        assert "rom3-j613-overrides.conf" not in path.read_text()

    print("ROM3 override helper tests passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
