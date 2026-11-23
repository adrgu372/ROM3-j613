#!/bin/bash
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
patches=(
    "$root/patches/0001-build-image-add-rom3-overlay.patch"
    "$root/patches/0002-build-image-signed-override-feed.patch"
)
commit=7c486c9125f88a463612f4450ee67c66d6db183c
work=$(mktemp -d)
trap 'find "$work" -type f -delete; find "$work" -depth -type d -exec rmdir {} \;' EXIT

git init -q "$work"
git -C "$work" remote add origin https://github.com/aurora-silicon/alarm-aurora.git
git -C "$work" fetch --depth 1 origin "$commit"
git -C "$work" checkout -q FETCH_HEAD
for patch_file in "${patches[@]}"; do
    git -C "$work" apply --check "$patch_file"
    git -C "$work" apply "$patch_file"
done

echo "ROM3 image patches apply to alarm-aurora $commit"

