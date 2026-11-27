#!/usr/bin/env python3
"""Repackage a verified binary under a ROM3 package name.

This is used only for rename-only changes where rebuilding the upstream
component would not alter its payload. The generated package records the
legacy package as a provide, conflict and replacement.
"""

from __future__ import annotations

import argparse
import os
from pathlib import Path
import shlex
import shutil
import subprocess
import tempfile


RENAMES = {
    "alsa-ucm-conf-aurora": "alsa-ucm-conf-rom3",
    "alsa-utils-aurora": "alsa-utils-rom3",
    "aura": "rom3",
    "aurora-audio": "rom3-audio",
    "aurora-userpages": "rom3-userpages",
    "fprintd-aurora": "fprintd-rom3",
    "libfprint-aurora": "libfprint-rom3",
    "linux-aurora": "linux-rom3",
    "linux-aurora-headers": "linux-rom3-headers",
    "mesa-aurora": "mesa-rom3",
    "speakersafetyd-aurora-profiles": "speakersafetyd-rom3-profiles",
    "uboot-aurora": "uboot-rom3",
    "upower-aurora": "upower-rom3",
    "vulkan-aurora": "vulkan-rom3",
}


def pkg_info(path: Path) -> dict[str, list[str]]:
    output = subprocess.check_output(["pacman", "-Qip", str(path)], text=True)
    info: dict[str, list[str]] = {}
    for line in output.splitlines():
        if " : " not in line:
            continue
        key, value = line.split(" : ", 1)
        info.setdefault(key.strip(), []).append(value.strip())
    return info


def field(info: dict[str, list[str]], name: str, default: str = "") -> str:
    values = info.get(name)
    return values[0] if values else default


def split_items(values: list[str]) -> list[str]:
    result: list[str] = []
    for value in values:
        result.extend(item for item in value.split() if item != "None")
    return result


def rewrite(value: str) -> str:
    for old, new in sorted(RENAMES.items(), key=lambda item: len(item[0]), reverse=True):
        value = value.replace(old, new)
    return value


def shell_array(name: str, values: list[str]) -> str:
    if not values:
        return ""
    items = " ".join(shlex.quote(value) for value in values)
    return f"{name}=({items})\n"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("package", type=Path)
    parser.add_argument("--name", required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()

    old_path = args.package.resolve()
    old = pkg_info(old_path)
    old_name = field(old, "Name")
    full_version = field(old, "Version")
    if not old_name or not full_version:
        raise SystemExit(f"cannot read package identity from {old_path}")

    epoch = "0"
    if ":" in full_version:
        epoch_text, full_version = full_version.split(":", 1)
        epoch = epoch_text
    if "-" not in full_version:
        raise SystemExit(f"package version has no pkgrel: {full_version}")
    pkgver, pkgrel = full_version.rsplit("-", 1)

    depends = [rewrite(value) for value in split_items(old.get("Depends On", []))]
    provides = split_items(old.get("Provides", []))
    conflicts = split_items(old.get("Conflicts With", []))
    replaces = split_items(old.get("Replaces", []))
    groups = [rewrite(value) for value in split_items(old.get("Groups", []))]
    backup = split_items(old.get("Backup Files", []))
    licenses = split_items(old.get("Licenses", []))

    provides.append(f"{old_name}={field(old, 'Version')}")
    conflicts.append(old_name)
    replaces.append(old_name)

    args.output.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="rom3-repack-") as temporary:
        work = Path(temporary)
        archive = work / old_path.name
        shutil.copy2(old_path, archive)

        install_source = ""
        has_install = subprocess.run(
            ["bsdtar", "-tf", str(archive)],
            text=True,
            capture_output=True,
            check=True,
        ).stdout.splitlines()
        if ".INSTALL" in has_install:
            install_data = subprocess.check_output(
                ["bsdtar", "-xOf", str(archive), ".INSTALL"]
            )
            (work / "legacy.install").write_bytes(install_data)
            install_source = "legacy.install "

        source = f"{old_path.name} {install_source}".strip()
        checksum_sources = [archive]
        if install_source:
            checksum_sources.append(work / "legacy.install")
        checksums = " ".join(
            shlex.quote(subprocess.check_output(["sha256sum", str(item)], text=True).split()[0])
            for item in checksum_sources
        )
        pkgdesc = field(old, "Description").replace("Aurora", "ROM3")
        pkgbuild = [
            f"pkgname={args.name}\n",
            f"pkgver={pkgver}\n",
            f"pkgrel={pkgrel}\n",
            f"epoch={epoch}\n",
            f"pkgdesc={shlex.quote(pkgdesc)}\n",
            f"arch=({shlex.quote(field(old, 'Architecture', 'aarch64'))})\n",
            f"url={shlex.quote(field(old, 'URL', 'https://github.com/adrgu372/ROM3-j613'))}\n",
            "install=legacy.install\n" if install_source else "",
            shell_array("license", licenses),
            shell_array("groups", groups),
            shell_array("depends", depends),
            shell_array("provides", provides),
            shell_array("conflicts", conflicts),
            shell_array("replaces", replaces),
            shell_array("backup", backup),
            f"source=({source})\n",
            f"sha256sums=({checksums})\n",
            "options=('!strip' '!debug')\n",
            "\npackage() {\n",
            "  bsdtar -xpf \"$srcdir/$source_filename\" -C \"$pkgdir\" \\\n",
            "    --exclude='.PKGINFO' --exclude='.BUILDINFO' --exclude='.MTREE' \\\n",
            "    --exclude='.INSTALL' --exclude='.CHANGELOG'\n",
            "}\n",
        ]
        pkgbuild.insert(0, f"source_filename={shlex.quote(old_path.name)}\n")
        (work / "PKGBUILD").write_text("".join(pkgbuild))

        subprocess.run(
            [
                "makepkg",
                "-f",
                "--nodeps",
                "--nocheck",
            ],
            cwd=work,
            env={**os.environ, "PKGDEST": str(args.output.resolve())},
            check=True,
        )

    print(args.output)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
