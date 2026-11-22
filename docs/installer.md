# Installer strategy

The upstream Aurora Installer already supports `Aurora Alarm` and an `arch-kde`
profile containing `apple,j613`. Its security model is based on signed support
catalogs and signed payloads.

ROM3 should initially reuse the existing `arch-kde` profile identifier and
publish a catalog that admits only `apple,j613`. The installer UI does not need
to know about ROM3-specific patches.

## Required delivery pieces

- ROM3 trust root;
- signed schema-5 catalog;
- signed Arch ARM KDE payload built from the verified ROM3 stack;
- ROM3 package repository configuration;
- ROM3 update guard and verification scripts;
- Stage 2 and rollback evidence.

The installer payload and package repository must be assembled from the same
`verified-stack.json`. Publishing them independently would allow a fresh image
and an updated system to diverge.

## Later work

ROM3 branding, a dedicated profile identifier or installer UI changes should
wait until a clean install from the standard `arch-kde` path is qualified.

