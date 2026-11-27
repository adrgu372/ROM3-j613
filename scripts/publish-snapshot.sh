#!/bin/bash
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
tag=${1:-}
gnupg=${ROM3_GNUPGHOME:-"$HOME/.config/rom3-j613/gnupg"}
key=${ROM3_GPG_KEY:-}
source_dir=${ROM3_ARTIFACT_DIR:-"$root/artifacts"}

[[ -n $tag ]] || {
    echo "usage: $0 SNAPSHOT_TAG" >&2
    exit 2
}
[[ -n $key ]] || {
    echo "set ROM3_GPG_KEY to the signing key fingerprint" >&2
    exit 1
}
[[ -d $source_dir ]] || {
    echo "artifact directory does not exist: $source_dir" >&2
    exit 1
}

destination="$root/repo/snapshots/$tag/aarch64"
[[ ! -e $destination ]] || {
    echo "refusing to overwrite published snapshot: $destination" >&2
    exit 1
}

mkdir -p "$destination"
cp "$root/stack/package-builds.json" "$destination/rom3-package-builds.json"

shopt -s nullglob
packages=("$source_dir"/*.pkg.tar.*)
(( ${#packages[@]} > 0 )) || {
    echo "no package artifacts in $source_dir" >&2
    exit 1
}

package_files=()
for package in "${packages[@]}"; do
    case $package in
        *.sig) continue ;;
    esac
    # GitHub rewrites the epoch separator ":" to "." in release asset names.
    # Stage that same portable name so the database and manifest agree with
    # the URLs the image builder will download.
    staged="$destination/$(basename "$package" | tr ':' '.')"
    cp "$package" "$staged"
    package_files+=("$staged")
    GNUPGHOME="$gnupg" gpg --batch --yes --local-user "$key" --detach-sign "$staged"
done

db="$destination/rom3-j613.db.tar.zst"
GNUPGHOME="$gnupg" repo-add --sign --key "$key" --include-sigs "$db" \
    "${package_files[@]}"

(
    cd "$destination"
    sha256sum ./*.pkg.tar.* ./*.db* ./*.files* > SHA256SUMS
)

echo "Signed snapshot: $destination"

