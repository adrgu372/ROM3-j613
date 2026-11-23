# ROM3-j613 Installer 0.1.3 technical preview

This build incorporates the installer fixes that completed a J613 installation,
entered the native Recovery handoff, and booted the installed ROM3-j613 system.

## Fixed

- Recovery template, launcher, marker and account setup now use the compiled
  `ROM3-j613 Installer.app` identity instead of the upstream Aurora name.
- The Partitions screen no longer hides a usable free extent merely because
  the welcome inspection still carries the engine's larger generic payload
  metadata. The authenticated ROM3 payload is inspected again before planning.
- The installer can be built with Command Line Tools by avoiding SwiftUI's
  Xcode-only `@Entry` macro and Bash 3.2's empty-array expansion failure.
- The `arch-kde` release profile is staged explicitly in the installed app.

## Included

- one visible operating-system choice: `ROM3-j613` with KDE Plasma
- catalog restricted to `apple,j613`
- native payload and `os_list` metadata from `image-20261122.6`
- verified `arch-kde` filesystem image from `stable-20261122.5`
- strict ad-hoc application signing and unsigned developer package
- portable SHA-256 checksums

The application passes strict deep signature verification. The package is
deliberately unsigned.

## Validation

Validated on MacBook Air M3 `Mac15,12` (`apple,j613`) with macOS 26.7.2:

- installation from the free extent completed;
- APFS, EFI, boot and Linux root partitions were created;
- the Recovery template and `.IAPhysicalMedia` marker passed verification;
- the native Recovery handoff was blessed and reached `awaiting_recovery`;
- Recovery completed setup and the installed ROM3-j613 system booted.

## Not yet production-qualified

- Apple Developer ID signing and notarization
- Gatekeeper behavior on a downloaded copy
- rollback and repeated cold-boot recovery exercises

Use this build only for controlled testing on a backed-up J613 installation.
