#!/bin/bash
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
artifacts="$root/artifacts"
packages=${*:-"linux-rom3 rom3 rom3-audio mesa-rom3 uboot-rom3 alsa-ucm-conf-rom3 alsa-utils-rom3 speakersafetyd-rom3-profiles rom3-j613-package-migration rom3-j613-meta rom3-j613-guard"}

mkdir -p "$artifacts"

for name in $packages; do
    dir="$root/packages/$name"
    [[ -d $dir ]] || { echo "missing package recipe: $name" >&2; exit 1; }
    echo "=== Building $name ==="
    (
        cd "$dir"
        PKGDEST="$artifacts" makepkg -f --noconfirm
    )
done

echo
echo "Artifacts: $artifacts"
find "$artifacts" -maxdepth 1 -type f -name '*.pkg.tar.*' -printf '%f\n' | sort

