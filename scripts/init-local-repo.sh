#!/bin/bash
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
repo="$root/repo/aarch64"
db="$repo/rom3-j613.db.tar.zst"

mkdir -p "$repo"

if ! command -v repo-add >/dev/null; then
    echo "repo-add is missing; install pacman-contrib" >&2
    exit 1
fi

packages=("$@")
if (( ${#packages[@]} == 0 )); then
    echo "usage: $0 PACKAGE.pkg.tar.zst [...]" >&2
    echo "No packages were published." >&2
    exit 2
fi

for package in "${packages[@]}"; do
    [[ -f $package ]] || { echo "missing package: $package" >&2; exit 1; }
done

repo-add --sign "$db" "${packages[@]}"

echo "Repository database: $db"
echo "Signatures must also be copied beside the package files."

