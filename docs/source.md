# Corresponding source

Binary releases are accompanied by the exact sources used to build the
ROM3-specific packages.

## Source bundles

- `linux-rom3-<pkgver>-source.tar.zst` contains the pinned upstream Linux
  archive, the ROM3 kernel recipe, configuration, DTB ABI and every patch used
  for the kernel and headers packages.
- `rom3-<pkgver>-<pkgrel>-source.tar.zst` contains the Aura-derived bootloader at the source tag
  selected by the package recipe, with the ROM3 J613 card-idle-mask patch
  applied, plus the ROM3 recipe and qualification file.
- `rom3-j613-source-<commit>.tar.gz` contains the complete ROM3 Git tree used
  for the repository metadata, update guard, keyring, meta-package, release
  package and build scripts.

`SOURCE-SHA256SUMS` authenticates the bundles and has a detached signature
from the ROM3 package-signing key:

```text
FA80FF234BCDF36211649321EB9845C8BAA89A4A
```

## Licenses

- The Linux kernel and headers are GPL-2.0-only.
- Aura is distributed under its upstream MIT/GPL-2.0 terms.
- ROM3 source is distributed under GPL-2.0; see `LICENSE` in the ROM3 source
  archive.

The exact upstream commits and package versions are recorded in the kernel
and Aura bundles and in `rom3-package-builds.json`.

## Upstream-only packages

ROM3-named downstream variants and packages copied unchanged from Aurora
Silicon and Arch Linux ARM retain their upstream licenses. Their exact
versions are listed in `rom3-package-builds.json`; corresponding source is
available from:

- Aurora packages:
  <https://github.com/aurora-silicon/alarm-aurora/tree/main/packages>
- Arch Linux ARM package recipes:
  <https://github.com/archlinuxarm/PKGBUILDs>
- Arch Linux package sources:
  <https://gitlab.archlinux.org/archlinux/packaging/packages>

Each binary package's `.BUILDINFO` also records its `pkgbuild_sha256sum`, build
environment and exact installed dependency set.
