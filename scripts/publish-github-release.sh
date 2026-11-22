#!/bin/bash
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
tag=${1:-}
snapshot="$root/repo/snapshots/$tag/aarch64"
repo=adrgu372/ROM3-j613

[[ -n $tag ]] || {
    echo "usage: $0 SNAPSHOT_TAG" >&2
    exit 2
}
[[ -d $snapshot ]] || {
    echo "missing signed snapshot: $snapshot" >&2
    exit 1
}
[[ -s $snapshot/SHA256SUMS ]] || {
    echo "snapshot lacks SHA256SUMS" >&2
    exit 1
}

for signature in "$snapshot"/*.pkg.tar.*.sig \
    "$snapshot"/rom3-j613.db.tar.zst.sig \
    "$snapshot"/rom3-j613.files.tar.zst.sig; do
    [[ -s $signature ]] || {
        echo "missing signature: $signature" >&2
        exit 1
    }
done

(
    cd "$snapshot"
    sha256sum -c SHA256SUMS
)

gh release create "$tag" "$snapshot"/* \
    --repo "$repo" \
    --title "ROM3-j613 $tag" \
    --notes "Signed ROM3-j613 package snapshot for apple,j613." \
    --latest

