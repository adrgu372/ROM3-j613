#!/bin/bash
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
tag=${1:-}
gnupg=${ROM3_GNUPGHOME:-"$HOME/.config/rom3-j613/gnupg"}
key=${ROM3_GPG_KEY:-}
output=${ROM3_SOURCE_OUTPUT_DIR:-"$root/artifacts/source-$tag"}

aura_repo=${AURA_SOURCE_REPO:-/home/adi/aura-b17-work}
aura_patch=$root/packages/aura/0001-kboot-audio-card-idle-mask.patch
kernel_dir=${KERNEL_SOURCE_DIR:-/home/adi/aurora-kernel-build/alarm-aurora/packages/linux-aurora}
kernel_commit=9125b31475836ce0a6634df45b539c6d604f36a5
kernel_tar=$kernel_dir/linux-${kernel_commit}.tar.gz

[[ -n $tag ]] || {
    echo "usage: $0 RELEASE_TAG" >&2
    exit 2
}
[[ -n $key ]] || {
    echo "set ROM3_GPG_KEY to the signing key fingerprint" >&2
    exit 1
}
[[ -d $aura_repo/.git ]]
[[ -f $aura_patch ]]
[[ -f $kernel_tar ]]
[[ ! -e $output ]] || {
    echo "refusing to overwrite source output: $output" >&2
    exit 1
}

commit=$(git -C "$root" rev-parse HEAD)
[[ -z $(git -C "$root" status --porcelain) ]] || {
    echo "ROM3 source tree must be clean" >&2
    exit 1
}

mkdir -p "$output"
temporary=$(mktemp -d "$output/.source-work.XXXXXX")
trap 'rm -rf "$temporary"' EXIT

git -C "$root" archive --format=tar.gz \
    --prefix="ROM3-j613-$commit/" \
    -o "$output/rom3-j613-source-$commit.tar.gz" HEAD

mkdir -p "$temporary/aura"
git -C "$aura_repo" archive v1.0.0b17 | tar -x -C "$temporary/aura"
patch -d "$temporary/aura" -Np1 < "$aura_patch"
cp "$root/packages/aura/PKGBUILD" "$root/packages/aura/build-qualification.json" \
    "$aura_patch" "$temporary/aura/"
cp "$root/docs/source.md" "$temporary/aura/SOURCE.md"
tar --zstd -cf "$output/aura-1.0.0b17-1-source.tar.zst" \
    -C "$temporary" aura

mkdir -p "$temporary/linux/upstream"
ln "$kernel_tar" "$temporary/linux/upstream/$(basename "$kernel_tar")"
cp "$kernel_dir/PKGBUILD" "$kernel_dir/config" "$kernel_dir/dtb-abi" \
    "$kernel_dir/50-aurora-user4k.cfg" "$kernel_dir/aurora-userpages.hook" \
    "$kernel_dir/bindgen-kernel.py" "$kernel_dir/rust-toolchain.toml" \
    "$kernel_dir/validate-config.py" "$kernel_dir"/linux-*.patch \
    "$temporary/linux/"
printf '%s\n' "$kernel_commit" > "$temporary/linux/KERNEL_COMMIT"
cp "$root/docs/source.md" "$temporary/linux/SOURCE.md"
tar --zstd -cf "$output/linux-7.3.0.aurora1-44-source.tar.zst" \
    -C "$temporary" linux

cp "$root/docs/source.md" "$output/SOURCE.md"
(
    cd "$output"
    sha256sum SOURCE.md *.tar.gz *.tar.zst > SOURCE-SHA256SUMS
)
GNUPGHOME="$gnupg" gpg --batch --yes --local-user "$key" \
    --detach-sign "$output/SOURCE-SHA256SUMS"

(
    cd "$output"
    sha256sum -c SOURCE-SHA256SUMS
    GNUPGHOME="$gnupg" gpg --batch --verify SOURCE-SHA256SUMS.sig \
        SOURCE-SHA256SUMS
)

echo "Source release: $output"
