# ROM3-j613 Installer 0.1.2 technical preview

This build keeps the corrected ROM3-only operating-system selection and native
payload from `image-20261122.6`, and isolates its local state from earlier
developer installers.

Version 0.1.0 and 0.1.1 shared the same Application Support workspace. A stale
pending job, accepted catalog, or partially downloaded artifact from either
version could therefore survive into the next run. Version 0.1.2 uses a
ROM3-specific workspace and starts with clean installer state.

## Included

- one visible operating-system choice: `ROM3-j613` with KDE Plasma
- catalog restricted to `apple,j613`
- native payload and `os_list` metadata from `image-20261122.6`
- verified `arch-kde` filesystem image from `stable-20261122.5`
- strict ad-hoc application signing and unsigned developer package
- SHA-256 checksums signed by the ROM3-j613 project key

The application passed strict deep signature verification in CI. The package
is deliberately unsigned.

## Not yet qualified

- Apple Developer ID signing and notarization
- Gatekeeper behavior on a downloaded copy
- clean installation on J613 with Recovery and macOS preserved
- first boot, cold boot, rollback and recovery exercises

Use this build only for controlled testing on a backed-up J613 installation.
