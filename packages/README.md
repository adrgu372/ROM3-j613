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
- `rom3-j613-meta`
- `rom3-j613-guard`

Generated binaries are excluded from Git.

