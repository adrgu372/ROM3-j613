# ROM3-j613 Installer 0.1.0 technical preview

This is an ad-hoc developer build for the MacBook Air 13-inch M3
(`apple,j613`) only. It is not a production installer.

## Included

- `ROM3-J613 Installer` rebranded from the pinned Aurora Installer revision
  `a0b34140669f69e3a777c70480e60244a470d50f`
- ROM3 catalog trust root and the signed `testing` channel catalog
- an installer model manifest restricted to `apple,j613`
- the verified `arch-kde` payload from `image-20261122.5`
- a strict ad-hoc code signature on the application and nested components
- a macOS developer `.pkg` that installs the app and its helper
- `SHA256SUMS` signed by the ROM3-j613 project package key

The application passed strict deep signature verification in CI. The package
is deliberately unsigned, and CI verifies that `pkgutil` reports
`Status: no signature`.

## Not yet qualified

- Apple Developer ID signing and notarization
- Gatekeeper behavior on a downloaded copy
- clean installation on a J613 with Recovery and macOS preserved
- first boot, cold boot, rollback and recovery exercises

Use this build only for controlled testing on a backed-up J613 installation.
Keep macOS and Recovery available. Do not deploy it as a public production
installer.

## Verification

Built by
[workflow run 45034424646](https://github.com/adrgu372/ROM3-j613/actions/runs/45034424646)
on the macOS 26 arm64 runner with Xcode 26.2.

```text
fde885920ecd110179c6133d23460d9d1e9ffe015e0770dc93f9bf6099419ef8  rom3-installer-output/ROM3-j613-Installer-0.1.0.pkg
36d6ae48325f49c90de59474b9229d1549ace0c6f752bb6fbaa28455ef597b5f  ROM3-j613-Installer-0.1.0.app.zip
```

Package checksum signing key fingerprint:

```text
FA80FF234BCDF36211649321EB9845C8BAA89A4A
```

The signed package repository and image payload remain published at
[`stable-20261122.5`](https://github.com/adrgu372/ROM3-j613/releases/tag/stable-20261122.5)
and
[`image-20261122.5`](https://github.com/adrgu372/ROM3-j613/releases/tag/image-20261122.5).
