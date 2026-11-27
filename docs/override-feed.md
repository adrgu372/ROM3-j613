# Signed override feed

The stable ROM3 repository deliberately pins packages that can prevent boot,
display or audio from working. An override feed is an authenticated exception
to that pin for one exact set of package versions.

It can be hosted as the assets of any GitHub release, including another
repository. The installed system follows it through the
`[rom3-j613-overrides]` pacman repository. Images built by CI can consume the
same release before sealing.

`SigLevel = Required DatabaseRequired` remains active for the override
repository. Its database, every package and `rom3-overrides.json` must all be
signed. The image builder accepts override feeds signed by the existing ROM3
signing key, so it does not add a second boot-time trust root.

## Prepare the package set

Select every package that must move together. If exact dependencies in
`rom3-j613-meta` change, rebuild and include the new `rom3-j613-meta` package
in the same feed. Kernel headers should move with the kernel, and the ROM3 bootloader or
`rom3-userpages` should move with a kernel when their ABI requires it.

The output must include all direct replacement packages, not the complete ROM3
snapshot. Base packages not named by the override manifest remain pinned to
the base snapshot.

From an aarch64 host with the ROM3 signing key:

```bash
export ROM3_GNUPGHOME="$HOME/.config/rom3-j613/gnupg"
export ROM3_GPG_KEY=FA80FF234BCDF36211649321EB9845C8BAA89A4A

./scripts/prepare-override-feed.sh \
  override-20261123.1 \
  stable-20261122.9 \
  /path/to/replacement-packages
```

This creates:

```text
repo/overrides/override-20261123.1/aarch64
```

That directory contains the signed pacman repository, package signatures,
`rom3-overrides.json`, its detached signature and `SHA256SUMS`.

## Publish it

Publish an immutable release in any GitHub repository:

```bash
gh release create override-20261123.1 \
  repo/overrides/override-20261123.1/aarch64/* \
  --repo OWNER/REPOSITORY \
  --title "Tested ROM3 override 20261123.1" \
  --prerelease \
  --notes "Replacement kernel and matching components for apple,j613."
```

Use the exact release URL, not `latest`, when configuring an installed system:

```text
https://github.com/OWNER/REPOSITORY/releases/download/override-20261123.1
```

The override release must be marked as a prerelease even when its packages are
qualified. Otherwise its newer release timestamp can replace the stable
snapshot behind `releases/latest/download`, breaking the base repository URL.

The manifest records its `stable-YYYYMMDD.N` base snapshot. An image must use
packages from the same base plus the replacements in this manifest.

## Build an image with it

For a local native image build:

```bash
export ROM3_OVERRIDE_FEED=https://github.com/OWNER/REPOSITORY/releases/download/override-20261123.1
./scripts/build-rom3-image.sh
```

The `rom3-j613-image` GitHub Actions workflow exposes the same value as the
`override_feed` input. `override_manifest_url` can override the default
`<feed>/rom3-overrides.json` location.

The builder downloads the signed manifest, verifies its signature with the
ROM3 key, checks every replacement against both the manifest SHA-256 and its
package signature, and verifies the installed exact versions. The override
repository and active manifest are retained in the image.

## Use it on an installed system

An image built with an override feed is already configured. Inspect it with:

```bash
rom3-j613-override status
sudo rom3-j613-update --check
```

On an existing image, authenticate and configure the same immutable release:

```bash
sudo rom3-j613-override configure \
  --feed https://github.com/OWNER/REPOSITORY/releases/download/override-20261123.1 \
  --fingerprint FA80FF234BCDF36211649321EB9845C8BAA89A4A
```

If the signing key is not already in the pacman keyring:

```bash
sudo rom3-j613-override configure \
  --feed https://github.com/OWNER/REPOSITORY/releases/download/override-20261123.1 \
  --fingerprint FINGERPRINT \
  --key https://example.invalid/override-signing-key.asc
```

The manifest signature is checked before the public key is locally trusted.
The command then authenticates the repository database with `pacman -Sy`.

Apply the approved stack only after a successful check:

```bash
sudo rom3-j613-update --check
sudo rom3-j613-update --apply
```

`--apply` takes a Btrfs snapshot, keeps every quarantined package outside the
manifest blocked, removes only manifest packages from `IgnorePkg` for the
transaction, requests their exact signed versions, and runs `rom3-j613-check`
afterward. Direct `pacman -Syu` remains unable to move the protected set.

## Disable it

```bash
sudo rom3-j613-override disable
```

This removes the repository and its approved version map. It does not
downgrade already installed packages; return to the base versions through a
separately tested snapshot if that is required.
