# Operating-system identity

The installed distribution identifies itself as `ROM3`. `J613` remains the
hardware variant rather than the distribution name.

The identity is owned by `rom3-j613-release` and installed by
`/usr/libexec/rom3-j613/set-os-identity`:

```text
NAME="ROM3"
PRETTY_NAME="ROM3"
ID=rom3
ID_LIKE=arch
VARIANT="J613"
VARIANT_ID="j613"
```

The helper writes both `/etc/os-release` and `/usr/lib/os-release`, plus
`/etc/lsb-release` and `/etc/issue`. A pacman hook reapplies the identity after
a `filesystem` or base release upgrade.

Verify the live system with:

```bash
hostnamectl
cat /etc/os-release
```

KDE reads `/etc/xdg/kcm-about-distrorc`; it displays `ROM3` and the ROM3
penguin emblem. The bootloader and Plymouth splash use the same emblem.
