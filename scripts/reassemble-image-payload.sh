#!/bin/bash
set -euo pipefail

tag=${ROM3_IMAGE_TAG:-image-20261122.5}
base=${ROM3_RELEASE_BASE:-https://github.com/adrgu372/ROM3-j613/releases/download/$tag}
destination=${1:-rom3-j613-$tag}
expected=0f01a50a55c3e48bd4fecfe45883b7f4e28e90328b88bf6a90a847e2a7951f68

mkdir -p "$destination"

download() {
    local name=$1
    if [[ ! -s $destination/$name ]]; then
        curl -fL --retry 5 --retry-all-errors \
            --output "$destination/$name" "$base/$name"
    fi
}

parts=(
    arch-kde-filesystems.tar.zst.part.00
    arch-kde-filesystems.tar.zst.part.01
    arch-kde-filesystems.tar.zst.part.02
    arch-kde-filesystems.tar.zst.part.03
    arch-kde-filesystems.tar.zst.part.04
)

for name in "${parts[@]}" arch-kde-image.json image-build.log \
    arch-kde-filesystems.tar.zst.attestation.jsonl \
    arch-kde-payload.json SHA256SUMS SHA256SUMS.sig
do
    download "$name"
done

(
    cd "$destination"
    sha256sum -c SHA256SUMS
    cat "${parts[@]}" > arch-kde-filesystems.tar.zst
    echo "$expected  arch-kde-filesystems.tar.zst" | sha256sum -c -
)

cat <<EOF
ROM3-j613 image payload reassembled in:
  $destination

Installer files:
  $destination/arch-kde-filesystems.tar.zst
  $destination/arch-kde-image.json

The filesystem archive digest is:
  sha256:$expected
EOF
