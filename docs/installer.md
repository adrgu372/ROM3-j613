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

## Image build

`scripts/build-rom3-image.sh` checks out the exact upstream `alarm-aurora`
commit, applies
`patches/0001-build-image-add-rom3-overlay.patch`, authenticates the ROM3 key
inside the image, and installs the signed `rom3-j613-release` package set.

It intentionally supports only `arch-kde` and requires a native aarch64 host.

## Later work

ROM3 branding, a dedicated profile identifier or installer UI changes should
wait until a clean install from the standard `arch-kde` path is qualified.

## Published payload

The first verified `arch-kde` payload is published at
`image-20261122.5`. It was built from `stable-20261122.5`, includes the
J613 MCA speaker-sense and `speakersafetyd` probe-rate fixes, and has Sigstore
provenance for the filesystem archive.

GitHub's per-file release limit requires the 4.92 GiB archive to be split into
five parts. The release includes signed checksums and
`reassemble-image-payload.sh`; installer integration must verify the reassembled
archive's SHA-256 before exposing it to the installer.

