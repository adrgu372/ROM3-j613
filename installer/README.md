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

