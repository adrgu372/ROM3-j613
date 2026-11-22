<p align="center">
  <img src="assets/rom3-j613.jpg" alt="ROM3-j613 Linux Distribution" width="420">
</p>

<h1 align="center">ROM3-j613</h1>

<p align="center">
  A tested, hardware-specific Linux distribution layer for the Apple MacBook Air
  13-inch M3 (<code>apple,j613</code>).
</p>

> [!IMPORTANT]
> ROM3-j613 is currently a bring-up distribution, not a general-purpose M3
> distribution. Only `apple,j613` is tested. Other M3 Macs are not supported.

ROM3-j613 is a downstream Arch Linux ARM and Aurora Silicon integration. It
does not replace Linux, Mesa, Aura or the Arch package ecosystem. It packages
the known-good combination for one board so a system update cannot silently
replace components responsible for display, GPU or speaker-safety regressions.

## Verified state

```text
Board:           apple,j613
Hardware:        MacBook Air 13-inch M3
Kernel:          7.3.0-1-42-ARCH
Aurora kernel:   linux-aurora 7.3.0.aurora1-42
Bootloader:      aura 1.0.0b14.1-3
U-Boot:          uboot-aurora 2026.07.aurora11-1
Display:         2560x1600 internal panel
GPU:             Apple M3 G15G
Render node:     /dev/dri/renderD128
OpenGL:          Apple M3 (G15G C0)
Audio:           speakersafetyd active
Stage 2 SHA-256: db2c95327e89fb70a636a8767efb8379bbf281596f52b9f6793c97db8eaeda09
```

The verified diagnostics, package set and recovery procedures currently live
in
[`adrgu372/aurora-m3-j613-fixes`](https://github.com/adrgu372/aurora-m3-j613-fixes).

## Why this project exists

An ordinary `pacman -Syu` can replace the bootloader, compositor, graphics
stack or audio stack with versions that have not been tested together on
`J613`. On this machine, such a partial upgrade previously caused:

- no usable internal display;
- GPU initialization failure;
- KWin without a working render device;
- speaker-safety lock and complete loss of audio.

ROM3-j613 turns the tested package combination into an explicit compatibility
contract. Sensitive packages remain in a signed ROM3 repository and ordinary
Arch updates are allowed only around that tested core.

## Architecture

```text
Arch Linux ARM rolling base
          |
Aurora Silicon hardware stack
          |
ROM3-j613 compatibility overlay
  - patched kernel
  - patched Aura
  - tested Mesa/Vulkan
  - tested KWin/audio set when required
          |
ROM3 update guard and recovery tools
          |
ROM3 Installer catalog and payload
```

## Repository layout

| Path | Purpose |
|---|---|
| `stack/verified-stack.json` | Machine-readable tested package set |
| `stack/quarantine.packages` | Packages that may not drift without qualification |
| `packages/` | ROM3 package recipes and variants |
| `pacman/` | Client repository configuration example |
| `configs/` | Pacman client, mirrorlist and local service configuration |
| `repo/` | Local binary repository workspace; generated files are not committed |
| `docs/` | Architecture, update policy, support matrix and installer plan |
| `scripts/` | Live verification, stack checking and repository tooling |
| `assets/` | Project branding |

## Current milestone

The project starts with the already verified `J613` stack and a fail-closed
update policy. The tested kernel and Aura recipes, exact-version meta-package,
update guard and initial local test packages now exist.

The signed package feed is public:

https://github.com/adrgu372/ROM3-j613/releases/tag/stable-20261122.5

The snapshot contains all 27 direct sensitive dependencies of the meta-package.
Its J613 kernel samples speaker V/I sense on the corrected MCA clock edge and
ships the matching `speakersafetyd` probe-rate fix. Five PipeWire restarts,
44.1 kHz and 48 kHz playback, GPU acceleration and the J613 panel were verified
on the reference laptop.
There is no ROM3 installer payload yet.

See [ROADMAP.md](ROADMAP.md).

## Safety

- Do not remove packages from quarantine without cold-boot validation.
- Do not publish unsigned packages or repository databases.
- Do not replace the active Stage 2 image without a verified backup.
- Do not treat build success as hardware qualification.
- Do not add another Mac model based only on a shared SoC name.

For a working `J613` installation, [docs/bootstrap.md](docs/bootstrap.md)
attaches the signed ROM3 feed without upgrading the system.

