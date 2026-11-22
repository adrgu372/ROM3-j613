#!/bin/bash
set -euo pipefail

gnupg=${ROM3_GNUPGHOME:-"$HOME/.config/rom3-j613/gnupg"}

mkdir -p "$gnupg"
chmod 700 "$gnupg"

cat >&2 <<EOF
Creating the ROM3-j613 package signing key in:
  $gnupg

Use a strong passphrase and keep an offline backup of the revocation
certificate. Never commit this directory or export a private key.

Suggested identity:
  Real name: ROM3-j613 package signing
  Email: packages@rom3-j613.invalid
  Key type: ECC (sign only)
  Expiry: 1y or 2y
EOF

GNUPGHOME="$gnupg" gpg --full-generate-key

echo
echo "Secret keys:"
GNUPGHOME="$gnupg" gpg --list-secret-keys --keyid-format long

