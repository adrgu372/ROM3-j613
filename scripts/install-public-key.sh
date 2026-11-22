#!/bin/bash
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
key=${ROM3_PUBLIC_KEY:-"$root/repo/keys/rom3-j613-packages.pub"}

if (( EUID != 0 )); then
    echo "run as root" >&2
    exit 1
fi

[[ -s $key ]] || {
    echo "missing public key: $key" >&2
    exit 1
}

pacman-key --add "$key"
fingerprint=$(
    gpg --with-colons --import-options show-only --import "$key" |
    awk -F: '$1=="fpr"{print $10; exit}'
)
[[ -n $fingerprint ]]
pacman-key --lsign-key "$fingerprint"

echo "Imported and locally trusted ROM3 key: $fingerprint"

