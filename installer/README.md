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

The verified image payload is published at:

https://github.com/adrgu372/ROM3-j613/releases/tag/image-20261122.5

The release splits the filesystem archive below GitHub's per-asset size limit.
Its signed `SHA256SUMS` and `reassemble-image-payload.sh` reconstruct the exact
archive covered by the Sigstore provenance attestation.

