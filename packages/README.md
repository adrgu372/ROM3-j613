# ROM3 package variants

The final names are intentionally distinct from the official Aurora packages:

```text
linux-rom3-j613
linux-rom3-j613-headers
aura-rom3-j613
kwin-rom3-j613
rom3-j613-meta
rom3-j613-keyring
rom3-j613-release
```

Replacement variants should declare both compatibility and conflict:

```ini
provides=('linux-aurora=7.3.0.aurora1-42')
conflicts=('linux-aurora')
replaces=('linux-aurora')
```

This prevents an official repository update from silently replacing a tested
ROM3 package.

No package recipes are published in this initial scaffold. They will be
imported from the verified source repository only after the signed repository
workflow is in place.

