# Existing-system bootstrap result

Date: 2026-11-22

The signed ROM3 feed was attached to the working J613 installation without
performing a system upgrade.

## Installed management packages

```text
rom3-j613-keyring 1-1
rom3-j613-meta 1-1
rom3-j613-guard 1-1
rom3-j613-release 1-1
```

## Package verification

`rom3-j613-check` matched all 14 exact-version entries in
`verified-stack.json`.

## Hardware verification

```text
Kernel:           7.3.0-1-42-ARCH
GPU:              card0 + renderD128
Display:          card1-eDP-1 connected
OpenGL:           Apple M3 (G15G C0)
speakersafetyd:   active
```

No negative IV-sense panic was present in the current boot.

## Update guard

`sudo rom3-j613-update --check` refused the current pending transaction before
installing anything.

Blocked packages:

```text
aurora-audio
kwin
speakersafetyd
speakersafetyd-aurora-profiles
```

This demonstrates that the compatibility boundary is active on the installed
system.

