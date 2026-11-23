# ROM3-j613 Installer 0.1.1 technical preview

This build replaces the initial installer preview that still exposed the
upstream Aurora distributions and pointed at the raw filesystem image instead
of a native installer payload.

## Included

- a single visible operating-system choice: `ROM3-j613` with KDE Plasma
- a catalog restricted to `apple,j613`
- native installer metadata and the split native payload from
  `image-20261122.6`
- the verified `arch-kde` filesystem image built from `stable-20261122.5`
- the ROM3 catalog trust root and signed testing-channel catalog
- strict ad-hoc application signing and the unsigned developer package
- portable SHA-256 checksums signed by the ROM3-j613 project key

The application passed strict deep signature verification in CI. The package
is deliberately unsigned, and CI verifies `Status: no signature`.

## Not yet qualified

- Apple Developer ID signing and notarization
- Gatekeeper behavior on a downloaded copy
- clean installation on J613 with Recovery and macOS preserved
- first boot, cold boot, rollback and recovery exercises

Use this build only for controlled testing on a backed-up J613 installation.
Keep macOS and Recovery available.

## Verification

Built by
[workflow run 45126718304](https://github.com/adrgu372/ROM3-j613/actions/runs/45126718304)
on the macOS 26 arm64 runner with Xcode 26.2.

```text
16331c4a0bae390bdf0f2d4a9864921be75d3e8e0250b90e09f3d420a3b19d51  ROM3-j613-Installer-0.1.1.pkg
14a230c10812c4efcab430720ed53f099e38d7b1fd2051675df59720f1349aa6  ROM3-j613-Installer-0.1.1.app.zip
```
