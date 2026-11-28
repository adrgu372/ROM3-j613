#!/bin/bash
set -euo pipefail

tag=rom3-updater-1.3
base=${ROM3_UPDATER_BASE:-https://github.com/adrgu372/ROM3-j613/releases/download/$tag}
fingerprint=FA80FF234BCDF36211649321EB9845C8BAA89A4A
key_name=rom3-j613-packages.pub
packages=(
    rom3-j613-control-1-3-aarch64.pkg.tar.xz
    rom3-j613-guard-1-13-any.pkg.tar.xz
    rom3-j613-keyring-1-3-any.pkg.tar.xz
    rom3-j613-meta-1-14-any.pkg.tar.xz
    rom3-j613-release-1-10-any.pkg.tar.xz
)

if (( EUID != 0 )); then
    echo "install.sh must run as root: sudo bash install.sh" >&2
    exit 1
fi
[[ $(uname -m) == aarch64 ]] || {
    echo "ROM3-j613 supports AArch64 only." >&2
    exit 1
}

work=$(mktemp -d /tmp/rom3-updater.XXXXXX)
cleanup() {
    find "$work" -depth -delete
}
trap cleanup EXIT

download() {
    local name=$1
    curl -fL --retry 5 --retry-all-errors \
        --output "$work/$name" "$base/$name"
}

download SHA256SUMS
download SHA256SUMS.sig
download "$key_name"

if ! pacman-key --list-keys "$fingerprint" >/dev/null 2>&1; then
    pacman-key --add "$work/$key_name"
    pacman-key --lsign-key "$fingerprint"
fi

gpg --homedir /etc/pacman.d/gnupg --batch --verify \
    "$work/SHA256SUMS.sig" "$work/SHA256SUMS"

for package in "${packages[@]}"; do
    download "$package"
    download "$package.sig"
done

(
    cd "$work"
    sha256sum -c SHA256SUMS
)

if [[ ${ROM3_UPDATER_DRY_RUN:-0} == 1 ]]; then
    echo "ROM3 Updater packages downloaded and verified; dry run complete."
    exit 0
fi

pacman -U --noconfirm "${packages[@]/#/$work/}"

echo
echo "ROM3 Updater installed successfully."
echo "Launch it from the application menu or run: rom3-j613-control"
