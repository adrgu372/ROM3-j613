#!/bin/bash
set -euo pipefail

gnupg=${ROM3_GNUPGHOME:-"$HOME/.config/rom3-j613/gnupg"}
key=${ROM3_GPG_KEY:-}
output=$(
    cd "$(dirname "$0")/.."
    pwd
)/repo/keys/rom3-j613-packages.pub

[[ -n $key ]] || {
    echo "set ROM3_GPG_KEY to the signing key fingerprint" >&2
    exit 1
}

mkdir -p "$(dirname "$output")"
GNUPGHOME="$gnupg" gpg --armor --export "$key" > "$output"
test -s "$output"
chmod 644 "$output"
echo "Public key: $output"

