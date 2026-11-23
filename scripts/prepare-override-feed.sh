#!/bin/bash
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
tag=${1:-}
base_snapshot=${2:-}
source_dir=${3:-"$root/artifacts"}
gnupg=${ROM3_GNUPGHOME:-"$HOME/.config/rom3-j613/gnupg"}
key=${ROM3_GPG_KEY:-}
destination="$root/repo/overrides/$tag/aarch64"

[[ -n $tag ]] || {
    echo "usage: $0 TAG BASE_SNAPSHOT [ARTIFACT_DIR]" >&2
    exit 2
}
[[ $tag =~ ^override-[0-9]{8}\.[0-9]+$ ]] || {
    echo "override tag must look like override-YYYYMMDD.N" >&2
    exit 2
}
[[ $base_snapshot =~ ^stable-[0-9]{8}\.[0-9]+$ ]] || {
    echo "base snapshot must look like stable-YYYYMMDD.N" >&2
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
[[ ! -e $destination ]] || {
    echo "refusing to overwrite override feed: $destination" >&2
    exit 1
}

mkdir -p "$destination"

shopt -s nullglob
packages=("$source_dir"/*.pkg.tar.*)
package_files=()
for package in "${packages[@]}"; do
    case $package in
        *.sig) continue ;;
    esac
    staged="$destination/$(basename "$package")"
    cp "$package" "$staged"
    package_files+=("$staged")
done
(( ${#package_files[@]} > 0 )) || {
    echo "no package artifacts in $source_dir" >&2
    exit 1
}

for package in "${package_files[@]}"; do
    GNUPGHOME="$gnupg" gpg --batch --yes --local-user "$key" \
        --detach-sign "$package"
done

db="$destination/rom3-j613-overrides.db.tar.zst"
GNUPGHOME="$gnupg" repo-add --sign --key "$key" --include-sigs "$db" \
    "${package_files[@]}"

python3 - "$destination" "$base_snapshot" <<'PY'
import hashlib
import json
from pathlib import Path
import sys
import tarfile

destination = Path(sys.argv[1])
base_snapshot = sys.argv[2]
artifacts = []
versions = {}

for package in sorted(destination.glob("*.pkg.tar.*")):
    if package.name.endswith(".sig"):
        continue
    with tarfile.open(package, "r:*") as archive:
        member = archive.extractfile(".PKGINFO")
        if member is None:
            raise SystemExit(f"{package.name}: missing .PKGINFO")
        metadata = {}
        for line in member.read().decode("utf-8").splitlines():
            key, separator, value = line.partition(" = ")
            if separator:
                metadata[key] = value
    name = metadata.get("pkgname")
    version = metadata.get("pkgver")
    if not name or not version:
        raise SystemExit(f"{package.name}: incomplete .PKGINFO")
    if name in versions:
        raise SystemExit(f"duplicate package in override feed: {name}")
    versions[name] = version
    artifacts.append(
        {
            "package": name,
            "version": version,
            "file": package.name,
            "sha256": hashlib.sha256(package.read_bytes()).hexdigest(),
        }
    )

manifest = {
    "schema_version": 1,
    "distribution": "ROM3-j613",
    "base_snapshot": base_snapshot,
    "packages": dict(sorted(versions.items())),
    "artifacts": artifacts,
}
(destination / "rom3-overrides.json").write_text(
    json.dumps(manifest, indent=2) + "\n"
)
PY

GNUPGHOME="$gnupg" gpg --batch --yes --local-user "$key" \
    --detach-sign "$destination/rom3-overrides.json"

(
    cd "$destination"
    sha256sum ./*.pkg.tar.* ./*.db* ./*.files* rom3-overrides.json \
        rom3-overrides.json.sig > SHA256SUMS
)
GNUPGHOME="$gnupg" gpg --batch --yes --local-user "$key" \
    --detach-sign "$destination/SHA256SUMS"

(
    cd "$destination"
    sha256sum -c SHA256SUMS
    GNUPGHOME="$gnupg" gpg --verify SHA256SUMS.sig SHA256SUMS
    GNUPGHOME="$gnupg" gpg --verify rom3-overrides.json.sig \
        rom3-overrides.json
)

cat <<EOF
Signed override feed: $destination

Publish that directory as a GitHub release in any repository. The feed URL is:
  https://github.com/OWNER/REPOSITORY/releases/download/$tag
EOF
