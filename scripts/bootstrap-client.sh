#!/bin/bash
set -euo pipefail

expected_fingerprint=FA80FF234BCDF36211649321EB9845C8BAA89A4A
key_url=https://raw.githubusercontent.com/adrgu372/ROM3-j613/main/repo/keys/rom3-j613-packages.pub
server=https://github.com/adrgu372/ROM3-j613/releases/latest/download
work=$(mktemp -d)
trap 'find "$work" -type f -delete; find "$work" -depth -type d -exec rmdir {} \;' EXIT

if (( EUID != 0 )); then
    echo "bootstrap-client.sh must run as root" >&2
    exit 1
fi

curl -fsSL "$key_url" -o "$work/rom3-j613-packages.pub"

fingerprint=$(
    gpg --with-colons --import-options show-only --import "$work/rom3-j613-packages.pub" |
    awk -F: '$1=="fpr"{print $10; exit}'
)
[[ $fingerprint == "$expected_fingerprint" ]] || {
    echo "unexpected ROM3 key fingerprint: $fingerprint" >&2
    exit 1
}

pacman-key --add "$work/rom3-j613-packages.pub"
pacman-key --lsign-key "$expected_fingerprint"

install -Dm644 /dev/stdin /etc/pacman.d/rom3-j613-mirrorlist <<EOF
Server = $server
EOF

install -Dm644 /dev/stdin /etc/pacman.d/rom3-j613.conf <<'EOF'
[rom3-j613]
SigLevel = Required DatabaseOptional
Include = /etc/pacman.d/rom3-j613-mirrorlist
EOF

if ! grep -q '^Include = /etc/pacman.d/rom3-j613.conf$' /etc/pacman.conf; then
    cp -a /etc/pacman.conf /etc/pacman.conf.rom3-backup
    cat >> /etc/pacman.conf <<'EOF'

# BEGIN ROM3-j613
Include = /etc/pacman.d/rom3-j613.conf
# END ROM3-j613
EOF
fi

pacman -Sy --noconfirm
pacman -S --needed --noconfirm rom3-j613-release

echo
/usr/bin/rom3-j613-check
echo
echo "ROM3-j613 repository configured. Run:"
echo "  rom3-j613-update --check"

