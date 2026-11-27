#!/bin/bash
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
tag=${1:-}
gnupg=${ROM3_GNUPGHOME:-"$HOME/.config/rom3-j613/gnupg"}
key=${ROM3_GPG_KEY:-}
output=${ROM3_SOURCE_OUTPUT_DIR:-"$root/artifacts/source-$tag"}

boot_repo=${AURA_SOURCE_REPO:-/home/adi/aura-b17-work}
boot_patch=$root/packages/rom3/0001-kboot-audio-card-idle-mask.patch
kernel_upstream_dir=${KERNEL_SOURCE_DIR:-/home/adi/aurora-kernel-build/alarm-aurora/packages/linux-aurora}
kernel_dir=$root/packages/linux-rom3
kernel_pkgbuild=$root/packages/linux-rom3/PKGBUILD
boot_pkgbuild=$root/packages/rom3/PKGBUILD
kernel_commit=$(sed -n 's/^_commit=//p' "$kernel_pkgbuild")
kernel_auroraver=$(sed -n 's/^_auroraver=//p' "$kernel_pkgbuild")
kernel_aurorarel=$(sed -n 's/^_aurorarel=//p' "$kernel_pkgbuild")
kernel_pkgrel=$(sed -n 's/^pkgrel=//p' "$kernel_pkgbuild")
kernel_pkgver=${kernel_auroraver}.aurora${kernel_aurorarel}-${kernel_pkgrel}
boot_pkgver=$(sed -n 's/^pkgver=//p' "$boot_pkgbuild")
boot_pkgrel=$(sed -n 's/^pkgrel=//p' "$boot_pkgbuild")
kernel_tar=$kernel_upstream_dir/linux-${kernel_commit}.tar.gz

[[ -n $tag ]] || {
    echo "usage: $0 RELEASE_TAG" >&2
    exit 2
}
[[ -n $key ]] || {
    echo "set ROM3_GPG_KEY to the signing key fingerprint" >&2
    exit 1
}
[[ -d $boot_repo/.git ]]
[[ -f $boot_patch ]]
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

mkdir -p "$temporary/rom3"
git -C "$boot_repo" archive v1.0.0b17 | tar -x -C "$temporary/rom3"
patch -d "$temporary/rom3" -Np1 < "$boot_patch"
cp "$root/packages/rom3/PKGBUILD" "$root/packages/rom3/build-qualification.json" \
    "$boot_patch" "$temporary/rom3/"
cp "$root/docs/source.md" "$temporary/rom3/SOURCE.md"
tar --zstd -cf "$output/rom3-${boot_pkgver}-${boot_pkgrel}-source.tar.zst" \
    -C "$temporary" rom3

mkdir -p "$temporary/linux/upstream"
ln "$kernel_tar" "$temporary/linux/upstream/$(basename "$kernel_tar")"
cp "$kernel_dir/PKGBUILD" "$kernel_dir/config" "$kernel_dir/dtb-abi" \
    "$kernel_dir/50-rom3-user4k.cfg" "$kernel_dir/rom3-userpages.hook" \
    "$kernel_dir/bindgen-kernel.py" "$kernel_dir/rust-toolchain.toml" \
    "$kernel_dir/validate-config.py" "$kernel_dir"/linux-*.patch \
    "$temporary/linux/"
printf '%s\n' "$kernel_commit" > "$temporary/linux/KERNEL_COMMIT"
cp "$root/docs/source.md" "$temporary/linux/SOURCE.md"
tar --zstd -cf "$output/linux-rom3-${kernel_pkgver}-source.tar.zst" \
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
