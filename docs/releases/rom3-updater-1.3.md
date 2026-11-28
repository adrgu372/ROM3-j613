# ROM3 Updater 1.3

Standalone updater bundle for systems already running ROM3-j613. This release
does not require rebuilding or reinstalling the image.

## Included

- `rom3-j613-control 1-3` — modern graphical Control Center;
- `rom3-j613-guard 1-13` — update guard, storage preflight and override checks;
- `rom3-j613-meta 1-14` — matching exact package-set metadata;
- `rom3-j613-release 1-10` — repository pointing at `stable-20261128.1`;
- `rom3-j613-keyring 1-3` — repository trust keyring.

## Improvements

- sidebar with Updates, System and Activity pages;
- persistent light and dark appearance;
- card-based layout and themed dialogs;
- fully non-interactive safe updates;
- specific errors for insufficient disk space and invalid swapfiles;
- safe atomic swapfile replacement around Btrfs snapshots;
- rejection of obsolete overrides that still contain Aurora package names;
- all previous update, verification and automation actions preserved.

## Install

Download `install.sh`, then run:

```bash
chmod +x install.sh
sudo bash install.sh
```

The installer downloads the signed package set, verifies `SHA256SUMS` with the
ROM3 project key and installs the packages with pacman.

## Source

The matching source is attached as `rom3-updater-1.3-source.tar.zst`. It contains
the complete Control Center and guard package recipes used for this release.
