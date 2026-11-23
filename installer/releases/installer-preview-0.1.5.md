# ROM3-j613 Installer 0.1.5 technical preview

This build fixes the `unavailable("ROM3-j613 · KDE Plasma")` error in the
`0.1.4` installer.

## Root cause

The app resolves its signed release through:

```text
Contents/Resources/Release/Profiles/arch-kde
```

The `0.1.4` packaging retained only the legacy root `Release` files and omitted
that profile directory. The configuration loader therefore treated the sole
visible distribution as unavailable before disk planning began.

## Fixed

- stage `release.json`, the trust root, catalog and catalog signature under
  `Release/Profiles/arch-kde` before packaging;
- fail the local build if any of those profile files is missing;
- verify the same profile files in CI before uploading the installer;
- preserve the `image-20261123.2` native payload and the automatic ROM3
  package-signing trust re-establishment introduced in `0.1.4`.

## Included

- one visible operating-system choice: `ROM3-j613` with KDE Plasma;
- catalog restricted to `apple,j613`;
- native payload and `os_list` metadata from `image-20261123.2`;
- verified `arch-kde` filesystem image from `stable-20261122.9`;
- strict ad-hoc application signing and unsigned developer package;
- portable SHA-256 checksums.

The application and package are not Developer ID signed or notarized. Use this
build only for controlled testing on a backed-up J613 installation.

## Verification

Built by
[workflow run 45182068314](https://github.com/adrgu372/ROM3-j613/actions/runs/45182068314)
on the macOS 26 arm64 runner with Xcode 26.2. CI verified the embedded
`Release/Profiles/arch-kde` files before packaging, the application passed
strict deep signature verification, and the package was confirmed unsigned.

```text
44faf4562776d3dd42386ca3782609d9eb5217238dd9dc594028359bfa812b71  ROM3-j613-Installer-0.1.5.pkg
05170e6b945924fcb04b1467f2851c9f0c5d346ce95b872d4f2cc765d4a69573  ROM3-j613-Installer-0.1.5.app.zip
```
