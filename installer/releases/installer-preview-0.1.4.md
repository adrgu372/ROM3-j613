# ROM3-j613 Installer 0.1.4 technical preview

This build installs the `image-20261123.2` native payload built from
`stable-20261122.9`.

## Fixed

- ROM3 package-signing trust is re-established automatically after Aurora
  creates the machine-local pacman master key; no manual `pacman-key` import is
  required after first boot.
- The keyring owner-trust file now uses the canonical `fingerprint:4:` format.
- `rom3-j613-guard 1-6` can authenticate replacement package sets from an
  external signed GitHub release repository without weakening pacman signature
  checks or opening the rest of the quarantine list.

## Included

- one visible operating-system choice: `ROM3-j613` with KDE Plasma;
- catalog restricted to `apple,j613`;
- native payload and `os_list` metadata from `image-20261123.2`;
- verified `arch-kde` filesystem image from `stable-20261122.9`;
- strict ad-hoc application signing and unsigned developer package;
- portable SHA-256 checksums.

## Validation

The image build completed all ROM3 package, keyring, quiescence, initramfs,
Stage 2 and filesystem checks. The native payload and its schema-5 catalog were
built and verified in CI. The installer application passed strict deep
signature verification and the package was confirmed unsigned.

Built by
[workflow run 45177976100](https://github.com/adrgu372/ROM3-j613/actions/runs/45177976100)
on the macOS 26 arm64 runner with Xcode 26.2.

```text
3815671efe4c56083fed0e14c15d60f58a3ee39b7ee9bd465a236bcfd660922b  ROM3-j613-Installer-0.1.4.pkg
26988dd21e78cb6d57947047ea6544df59dbe62dd2730507333345ec7e8011d8  ROM3-j613-Installer-0.1.4.app.zip
```

## Not yet production-qualified

- Apple Developer ID signing and notarization
- Gatekeeper behavior on a downloaded copy
- clean-install, repeated cold-boot and Recovery exercises

Use this build only for controlled testing on a backed-up J613 installation.
