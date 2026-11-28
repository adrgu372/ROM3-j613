#!/bin/bash
set -euo pipefail

tag=${ROM3_IMAGE_TAG:-image-20261128.1}
base=${ROM3_RELEASE_BASE:-https://github.com/adrgu372/ROM3-j613/releases/download/$tag}
destination=${1:-rom3-j613-$tag}

mkdir -p "$destination"

download() {
    local name=$1
    if [[ ! -s $destination/$name ]]; then
        curl -fL --retry 5 --retry-all-errors \
            --output "$destination/$name" "$base/$name"
    fi
}

download arch-kde-payload.json
mapfile -t parts < <(
    python3 - "$destination/arch-kde-payload.json" <<'PY'
import json
import sys

payload = json.load(open(sys.argv[1], encoding="utf-8"))
print("\n".join(chunk["name"] for chunk in payload["chunks"]))
PY
)
expected=$(
    python3 - "$destination/arch-kde-payload.json" <<'PY'
import json
import sys

payload = json.load(open(sys.argv[1], encoding="utf-8"))
print(payload["filesystem_archive"]["sha256"])
PY
)

for name in "${parts[@]}" arch-kde-image.json image-build.log \
    arch-kde-filesystems.tar.zst.attestation.jsonl \
    SHA256SUMS SHA256SUMS.sig
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
