#!/bin/bash
set -euo pipefail

door=${1:-rom3-j613-installer-payload-20261123.2}
base=${ROM3_PAYLOAD_BASE:-https://github.com/adrgu372/ROM3-j613/releases/download/image-20261123.2}
mkdir -p "$door"

download() {
    local name=$1
    if [[ ! -s $door/$name ]]; then
        curl -fL --retry 5 --retry-all-errors --output "$door/$name" "$base/$name"
    fi
}

mapfile -t parts < <(
    curl -fsSL "$base/payload.json" |
        python3 -c 'import json,sys; print("\n".join(x["name"] for x in json.load(sys.stdin)["payload_parts"]))'
)

for name in "${parts[@]}" \
    installer-data-arch-kde.json delivery.json payload.json SHA256SUMS
do
    download "$name"
done

(
    cd "$door"
    sha256sum -c SHA256SUMS
    cat "${parts[@]}" > arch-kde-20261123.2.zip
    sha256sum "$(python3 -c \
        'import json; print(json.load(open("payload.json"))["payload_asset"])')"
)

printf 'ROM3-j613 native installer payload reassembled in %s\n' "$door"
