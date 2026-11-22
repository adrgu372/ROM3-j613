#!/bin/bash
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
package="$root/packages/rom3-j613-release"
files=("rom3-j613.conf" "rom3-j613-mirrorlist")

for file in "${files[@]}"; do
    cp "$root/configs/$file" "$package/$file"
done

python3 - "$package/PKGBUILD" "$package" <<'PY'
from pathlib import Path
import hashlib
import re
import sys

pkgbuild = Path(sys.argv[1])
directory = Path(sys.argv[2])
names = ["rom3-j613.conf", "rom3-j613-mirrorlist"]
sums = "\n".join(
    f"  '{hashlib.sha256((directory / name).read_bytes()).hexdigest()}'"
    for name in names
)
text = pkgbuild.read_text()
text = re.sub(r"sha256sums=\(\n.*?\n\)", f"sha256sums=(\n{sums}\n)", text, flags=re.S)
pkgbuild.write_text(text)
PY

echo "Prepared ROM3 release package sources and checksums."

