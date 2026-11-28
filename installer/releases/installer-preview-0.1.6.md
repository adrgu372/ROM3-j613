# ROM3-j613 Installer 0.1.6 technical preview

This installer targets package snapshot `stable-20261128.1` and the matching
KDE filesystem image `image-20261128.1`.

## Included

- native installer payload `image-20261128.2`, rebuilt specifically for
  `apple,j613`;
- `linux-rom3 7.3.0.aurora1-46`, including the trackpad haptic resume retry;
- `rom3-j613-control 1-3` with the redesigned Control Center;
- `rom3-j613-guard 1-13` with storage and swap update preflights;
- ROM3 package ownership throughout the runtime image;
- iio ambient-light colour-temperature support;
- the tested Mesa, Vulkan, KWin, PipeWire, WirePlumber and speaker-safety stack;
- strict ad-hoc application signing and unsigned developer package;
- portable SHA-256 checksums.

The schema-5 catalog remains signed by the existing ROM3 Ed25519 trust root.
No trust-root rotation is required.

## Validation

The filesystem archive, native payload parts, signed catalog and remote catalog
endpoints were verified before the installer build. The installer publishes
only after the macOS CI build, embedded-profile check, deep code-signature
verification and unsigned-package check pass.

## Not yet production-qualified

- Apple Developer ID signing and notarization
- Gatekeeper behavior on a downloaded copy
- clean-install, repeated cold-boot and Recovery exercises for this exact image

Use this build only for controlled testing on a backed-up J613 installation.
