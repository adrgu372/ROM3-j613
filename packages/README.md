# ROM3 package variants

The initial stable channel keeps the upstream names:

```text
linux-aurora
linux-aurora-headers
aura
```

They are locked to exact versions by:

```text
rom3-j613-meta
rom3-j613-guard
```

Keeping the original names for the first release avoids an unnecessary
`pkgbase`, initramfs preset and boot-entry migration. A later release may
introduce replacement variants such as:

```text
linux-rom3-j613
aura-rom3-j613
kwin-rom3-j613
```

Those variants must declare both compatibility and conflict:

```ini
provides=('linux-aurora=7.3.0.aurora1-42')
conflicts=('linux-aurora')
replaces=('linux-aurora')
```

The current `rom3-j613-meta` package requires exact versions of every
quarantined package. A transaction that would move one of them to an
unqualified version cannot satisfy the meta-package dependency.

Imported recipes currently cover:

- `linux-aurora`
- `aura`
- `aurora-audio` pinned to the last verified legacy-stack release
- `rom3-j613-meta`
- `rom3-j613-guard`
- `rom3-j613-release`
- `rom3-j613-keyring`, with a boot-time service that re-establishes local trust
  after Aurora initializes or repairs the machine-local pacman master key

Generated binaries are excluded from Git.

The signed binary snapshot mirrors every exact package required by the
meta-package, including packages normally sourced from Arch Linux ARM. This is
what makes the installer payload reproducible.

