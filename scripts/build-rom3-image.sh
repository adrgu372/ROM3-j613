#!/bin/bash
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
commit=7c486c9125f88a463612f4450ee67c66d6db183c
tag=${ROM3_AURORA_TAG:-testing-20261122.1}
channel=${ROM3_AURORA_CHANNEL:-testing}
work=${ROM3_IMAGE_ROOT:-$HOME/rom3-image-build}
source_repo="$work/alarm-aurora"

if (( EUID != 0 )); then
    echo "build-rom3-image.sh must run as root" >&2
    exit 1
fi
[[ $(uname -m) == aarch64 ]] || {
    echo "native aarch64 host required" >&2
    exit 1
}

mkdir -p "$work"
if [[ ! -d $source_repo/.git ]]; then
    git init "$source_repo"
    git -C "$source_repo" remote add origin \
        https://github.com/aurora-silicon/alarm-aurora.git
fi

git -C "$source_repo" fetch --depth 1 origin "$commit"
git -C "$source_repo" checkout -q --detach FETCH_HEAD
git -C "$source_repo" reset --hard "$commit"
for patch_file in \
    "$root/patches/0001-build-image-add-rom3-overlay.patch" \
    "$root/patches/0002-build-image-signed-override-feed.patch"; do
    git -C "$source_repo" apply "$patch_file"
done

export ROM3_FEED=https://github.com/adrgu372/ROM3-j613/releases/download/stable-20261124.1
export ROM3_OVERRIDE_FEED=${ROM3_OVERRIDE_FEED:-}
export ROM3_OVERRIDE_MANIFEST_URL=${ROM3_OVERRIDE_MANIFEST_URL:-}
export ROM3_OVERRIDE_FINGERPRINT=${ROM3_OVERRIDE_FINGERPRINT:-FA80FF234BCDF36211649321EB9845C8BAA89A4A}
export ROM3_KEY_URL=https://raw.githubusercontent.com/adrgu372/ROM3-j613/main/repo/keys/rom3-j613-packages.pub
export ROM3_FINGERPRINT=FA80FF234BCDF36211649321EB9845C8BAA89A4A

cd "$source_repo"
bash scripts/build-image arch-kde "$tag" "$channel"

echo
echo "ROM3 image output: $source_repo/out/arch-kde"

