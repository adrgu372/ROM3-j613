# ROM3 package namespace

ROM3-owned package identifiers use the ROM3 name. Upstream repository URLs,
source paths and upstream-derived version strings can still contain
`aurora`/`aura`; those are provenance, not package names.

| Package role | ROM3 name | Legacy alias |
|---|---|---|
| Bootloader | `rom3` | `aura` |
| Kernel | `linux-rom3` | `linux-aurora` |
| Kernel headers | `linux-rom3-headers` | `linux-aurora-headers` |
| 4K userpages | `rom3-userpages` | `aurora-userpages` |
| Audio profiles | `rom3-audio` | `aurora-audio` |
| U-Boot | `uboot-rom3` | `uboot-aurora` |
| Mesa | `mesa-rom3` | `mesa-aurora` |
| Vulkan | `vulkan-rom3` | `vulkan-aurora` |
| ALSA UCM | `alsa-ucm-conf-rom3` | `alsa-ucm-conf-aurora` |
| ALSA utilities | `alsa-utils-rom3` | `alsa-utils-aurora` |
| Speaker profiles | `speakersafetyd-rom3-profiles` | `speakersafetyd-aurora-profiles` |

Core stack replacements declare their direct old name in `provides`,
`conflicts` and `replaces`. This lets `pacman -U` migrate an installed ROM3
system without leaving duplicate file owners or breaking upstream packages
that still depend on an Aurora-named capability.

The package-migration meta covers the remaining platform packages, including `rom3-boot`,
`rom3-firmware`, `rom3-firstboot`, `rom3-keyring`, SEP/Touch ID helpers,
distro artwork, KWin/Mutter/GNOME variants, NetworkManager/IWD variants,
`fprintd-rom3`, `libfprint-rom3` and `upower-rom3`. Their complete legacy
alias set is maintained by `rom3-j613-package-migration`.

`rom3-j613-meta` depends only on ROM3 package names and exact tested versions.
`rom3-j613-guard` quarantines both the ROM3 names and their legacy aliases so
an upstream repository cannot silently reintroduce either variant.

Imported recipes currently cover the kernel, bootloader, audio stack, U-Boot,
Mesa/Vulkan, ALSA packages and speaker profiles. `rom3-j613-guard` also
provides `rom3-j613-override`, which authenticates a signed external package
feed and keeps its version exceptions separate from the stable quarantine
list.

Generated binaries are excluded from Git. The signed binary snapshot mirrors
every exact package required by the meta-package, including packages normally
sourced from Arch Linux ARM; this keeps installer payloads reproducible.

