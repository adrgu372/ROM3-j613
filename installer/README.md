# Installer integration

ROM3-j613 initially reuses Aurora Installer's existing `arch-kde` profile. No
installer UI fork is needed for the first image.

The catalog will admit one model only:

```text
apple,j613
```

The payload must be built from the same signed package snapshot recorded in
`../stack/verified-stack.json`. A payload with upstream kernel or Aura packages
is not a valid ROM3 delivery.

## Delivery sequence

1. Publish a signed package snapshot.
2. Build an `alarm-btrfs-v1` KDE image with the ROM3 package set.
3. Verify the Stage 2 image and J613 device trees.
4. Assemble the native installer payload.
5. Sign a schema-5 catalog restricted to `apple,j613`.
6. Cold-boot and run install verification.
7. Publish the installer and catalog.

`profile.json` and `payload-plan.json` are the ROM3-owned source of truth until
the final signed catalog is generated.

The verified source filesystem image is published at:

https://github.com/adrgu372/ROM3-j613/releases/tag/image-20261122.5

The release splits the filesystem archive below GitHub's per-asset size limit.
Its signed `SHA256SUMS` and `reassemble-image-payload.sh` reconstruct the exact
archive covered by the Sigstore provenance attestation.

The native installer payload and current catalog are published at:

https://github.com/adrgu372/ROM3-j613/releases/tag/image-20261122.6

That release contains the native ZIP in six parts and `os_list` metadata. Its
schema-5 testing catalog is signed by the ROM3 Ed25519 key and admits only
`apple,j613`. It cannot be used with an installer binary that trusts the
upstream Aurora catalog root; a ROM3 installer build must bundle
`installer/keys/catalog-signing.ed25519.pub`.

## Technical-preview macOS build

On a macOS host with Xcode and Swift 6.2 or newer, the preparation script pins
the upstream installer revision, applies the ROM3 identity and trust root,
restricts its model manifest to `apple,j613`, downloads the signed catalog, and
builds an ad-hoc developer app:

```bash
ROM3_INSTALLER_OUTPUT="$HOME/ROM3-j613-installer-output" \
  ./scripts/build-rom3-installer-macos.sh
```

This produces a technical-preview package. It is not Developer ID signed or
notarized and is not a production download. A public installer build still
requires an Apple Developer ID identity, notarization and a clean-install
qualification on this board.

The CI-built technical-preview artifact is published here:

https://github.com/adrgu372/ROM3-j613/releases/tag/installer-preview-0.1.1

It is restricted to `apple,j613`. The `.pkg` is deliberately unsigned and the
application is ad-hoc signed. It has not completed a clean install, cold boot
or Recovery exercise, so it remains a prerelease test build.

