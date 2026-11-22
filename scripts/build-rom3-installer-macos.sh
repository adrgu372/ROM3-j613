#!/bin/bash
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
commit=a0b34140669f69e3a777c70480e60244a470d50f
upstream=${ROM3_INSTALLER_SOURCE:-$HOME/aurora-installer-rom3}
output=${ROM3_INSTALLER_OUTPUT:-$HOME/ROM3-j613-installer-output}
public_key=$root/installer/keys/catalog-signing.ed25519.pub
catalog_dir=${ROM3_CATALOG_DIR:-$root/cache/catalog-image-20261122.5}
catalog_base=https://github.com/adrgu372/ROM3-j613/releases/download/image-20261122.5

[[ $(uname -s) == Darwin ]] || {
    echo "this build must run on macOS with Xcode and Swift 6.2+" >&2
    exit 1
}
mkdir -p "$catalog_dir"
for name in catalog.json catalog.json.sig; do
    if [[ ! -s $catalog_dir/$name ]]; then
        curl -fL --retry 5 --retry-all-errors \
            --output "$catalog_dir/$name" "$catalog_base/$name"
    fi
done
for file in "$public_key" \
    "$catalog_dir/catalog.json" \
    "$catalog_dir/catalog.json.sig"
do
    [[ -f $file && ! -L $file ]] || {
        echo "missing catalog input: $file" >&2
        exit 1
    }
done

if [[ ! -d $upstream/.git ]]; then
    git clone https://github.com/aurora-silicon/aurora-installer.git "$upstream"
fi
git -C "$upstream" fetch origin "$commit"
git -C "$upstream" checkout --detach "$commit"
[[ $(git -C "$upstream" rev-parse HEAD) == "$commit" ]]
installer_patches=(
    "$root/patches/aurora-installer-macos26-cdhash.patch"
    "$root/patches/aurora-installer-rom3-recovery-name.patch"
    "$root/patches/aurora-installer-rom3-ui.patch"
)
for installer_patch in "${installer_patches[@]}"; do
    git -C "$upstream" apply --check "$installer_patch"
    git -C "$upstream" apply "$installer_patch"
done
source_root=$upstream/macOS
[[ -d $source_root/Packaging && -d $source_root/Release && -d $source_root/scripts ]] || {
    echo "pinned installer source has an unexpected layout: $source_root" >&2
    exit 1
}

python3 - "$source_root" "$root/installer/release.json" "$public_key" <<'PY'
import json
import pathlib
import re
import sys

source_root = pathlib.Path(sys.argv[1])
release_descriptor = pathlib.Path(sys.argv[2]).read_bytes()
public_key = pathlib.Path(sys.argv[3]).read_bytes()

identity_path = source_root / "Packaging/identity.conf"
identity = identity_path.read_text()
values = {
    "INSTALLER_APP_NAME": "ROM3-j613 Installer",
    "INSTALLER_FILE_STEM": "ROM3-j613-Installer",
    "INSTALLER_APP_IDENTIFIER": "org.rom3j613.installer",
    "INSTALLER_HELPER_IDENTIFIER": "org.rom3j613.installer.helper",
    "INSTALLER_RESTORE_IMAGE_IDENTIFIER": "org.rom3j613.installer.restore-image",
    "INSTALLER_PKG_IDENTIFIER": "org.rom3j613.installer.pkg",
    "INSTALLER_TRUST_ROOT_FINGERPRINT":
        "sha256:2b7e847f34019f26eb9fc0dbd675611446357078f3057434be9491ba97c4404c",
    "INSTALLER_CATALOG_KEY_SERVICE": "rom3-j613-catalog-signing-key",
    "INSTALLER_STREAM_PATH": "rom3-j613",
    "INSTALLER_GITHUB_RELEASE_REPO": "adrgu372/ROM3-j613",
    "INSTALLER_GITHUB_RELEASE_LOGIN": "adrgu372",
}
for name, value in values.items():
    pattern = rf'^{re.escape(name)}="[^"]*"$'
    identity, count = re.subn(
        pattern, f'{name}="{value}"', identity, flags=re.MULTILINE
    )
    if count != 1:
        raise SystemExit(f"could not replace {name} in identity.conf")
identity_path.write_text(identity)

(source_root / "Release/release.json").write_bytes(release_descriptor)
(source_root / "Release/trust-root.ed25519.pub").write_bytes(public_key)

models_path = source_root / "scripts/supported-models.json"
models = {
    "schema_version": 1,
    "supported": ["apple,j613"],
    "refused": {},
    "developer": {},
    "stage1_caution": {},
}
models_path.write_text(json.dumps(models, indent=2) + "\n")

inputs = {
    "payload_name": "arch-kde-filesystems.tar.zst",
    "metadata_name": "arch-kde-image.json",
    "evidence_revision": "rom3-image-45026998485",
    "asahi_installer_tag": "v0.9.2",
    "asahi_installer_revision": "a0b34140669f69e3a777c70480e60244a470d50f",
    "asahi_installer_data_revision": "5c64c2c0d47387b5d84fa760019dca67ca98d45b",
    "downstream_revision": "5c64c2c0d47387b5d84fa760019dca67ca98d45b",
    "installation_profile": "arch-kde",
    "device_identifiers": ["apple,j613"],
}
(source_root / "scripts/release-inputs.template.json").write_text(
    json.dumps(inputs, indent=2) + "\n"
)
PY

release_inputs="$output/release-inputs"
mkdir -p "$release_inputs" "$output"
cp "$source_root/Release/release.json" "$release_inputs/release.json"
cp "$source_root/Release/trust-root.ed25519.pub" "$release_inputs/trust-root.ed25519.pub"
cp "$catalog_dir/catalog.json" "$release_inputs/catalog.json"
cp "$catalog_dir/catalog.json.sig" "$release_inputs/catalog.json.sig"

cd "$source_root"
AURORA_DEVELOPER_BUILD=1 \
AURORA_ROM3_J613=1 \
AURORA_APP_SIGNING_IDENTITY="-" \
AURORA_APP_VERSION="0.1.1" \
bash Packaging/build-app.sh "$release_inputs" "$output/app"

if [[ -x Packaging/build-developer-pkg.sh ]]; then
    bash Packaging/build-developer-pkg.sh \
        "$output/app/ROM3-j613 Installer.app" \
        "$output/ROM3-j613-Installer-0.1.1.pkg"
fi

cat <<EOF
Technical-preview installer built at:
  $output

This is an ad-hoc developer build. It is not Developer ID signed or notarized
and must not be presented as a public production installer.
EOF
