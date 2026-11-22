#!/bin/bash
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
public_key=${ROM3_PUBLIC_KEY:-"$root/repo/keys/rom3-j613-packages.pub"}
package="$root/packages/rom3-j613-keyring"
work=$(mktemp -d)
trap 'find "$work" -type f -delete; find "$work" -depth -type d -exec rmdir {} \;' EXIT

[[ -s $public_key ]] || {
    echo "missing public key: $public_key" >&2
    exit 1
}

mkdir -p "$package"
cp "$root/packages/rom3-j613-keyring/PKGBUILD.template" "$package/PKGBUILD"
cp "$public_key" "$package/rom3-j613-packages.pub"

GNUPGHOME="$work" gpg --batch --import "$package/rom3-j613-packages.pub"
GNUPGHOME="$work" gpg --batch --export > "$package/rom3-j613.gpg"
GNUPGHOME="$work" gpg --batch --with-colons --list-keys |
    awk -F: '$1=="pub"{want=1; next} want && $1=="fpr"{print $10; exit}' \
    > "$package/rom3-j613-trusted"

[[ -s $package/rom3-j613.gpg ]]
[[ -s $package/rom3-j613-trusted ]]

python3 - "$package/PKGBUILD" "$package" <<'PY'
from pathlib import Path
import hashlib
import re
import sys

pkgbuild = Path(sys.argv[1])
directory = Path(sys.argv[2])
names = [
    "rom3-j613-packages.pub",
    "rom3-j613.gpg",
    "rom3-j613-trusted",
]
sums = "\n".join(
    f"  '{hashlib.sha256((directory / name).read_bytes()).hexdigest()}'"
    for name in names
)
text = pkgbuild.read_text()
text = re.sub(r"sha256sums=\(\n.*?\n\)", f"sha256sums=(\n{sums}\n)", text, flags=re.S)
pkgbuild.write_text(text)
PY

echo "Prepared ROM3 keyring package in $package"

