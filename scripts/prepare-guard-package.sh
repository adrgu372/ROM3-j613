#!/bin/bash
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
package="$root/packages/rom3-j613-guard"

cp "$root/scripts/rom3-j613-check" "$package/"
cp "$root/scripts/rom3-j613-update" "$package/"
cp "$root/scripts/verify-live-system.sh" "$package/"
cp "$root/stack/verified-stack.json" "$package/"
cp "$root/stack/quarantine.packages" "$package/"

python3 - "$package/PKGBUILD" "$package" <<'PY'
from pathlib import Path
import hashlib
import re
import sys

pkgbuild = Path(sys.argv[1])
directory = Path(sys.argv[2])
text = pkgbuild.read_text()
files = [
    "rom3-j613-check",
    "rom3-j613-update",
    "rom3-j613-override",
    "verify-live-system.sh",
    "verified-stack.json",
    "quarantine.packages",
]
sums = "\n".join(
    f"  '{hashlib.sha256((directory / name).read_bytes()).hexdigest()}'"
    for name in files
)
text = re.sub(r"sha256sums=\(\n.*?\n\)", f"sha256sums=(\n{sums}\n)", text, flags=re.S)
pkgbuild.write_text(text)
PY

echo "Prepared guard package sources and checksums."

