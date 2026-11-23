# ROM3-j613 Installer 0.1.3 technical preview

This build incorporates the installer fixes that completed a J613 installation,
entered the native Recovery handoff, and booted the installed ROM3-j613 system.

## Fixed

- Recovery template, launcher, marker and account setup now use the compiled
  `ROM3-j613 Installer.app` identity instead of the upstream Aurora name.
- The Partitions screen no longer hides a usable free extent merely because
  the welcome inspection still carries the engine's larger generic payload
  metadata. The authenticated ROM3 payload is inspected again before planning.
- The installer can be built with Command Line Tools by avoiding SwiftUI's
  Xcode-only `@Entry` macro and Bash 3.2's empty-array expansion failure.
- The `arch-kde` release profile is staged explicitly in the installed app.

## Included

- one visible operating-system choice: `ROM3-j613` with KDE Plasma
- catalog restricted to `apple,j613`
- native payload and `os_list` metadata from `image-20261122.6`
- verified `arch-kde` filesystem image from `stable-20261122.5`
- strict ad-hoc application signing and unsigned developer package
- portable SHA-256 checksums

The application passes strict deep signature verification. The package is
deliberately unsigned.

## Validation

Validated on MacBook Air M3 `Mac15,12` (`apple,j613`) with macOS 26.7.2:

- installation from the free extent completed;
- APFS, EFI, boot and Linux root partitions were created;
- the Recovery template and `.IAPhysicalMedia` marker passed verification;
- the native Recovery handoff was blessed and reached `awaiting_recovery`;
- Recovery completed setup and the installed ROM3-j613 system booted.

## Manual repository-key import

After the first boot, the ROM3-j613 package-signing key must be imported and
locally trusted manually before using the ROM3 package repository:

```bash
sudo pacman-key --populate rom3-j613
sudo pacman-key --lsign-key FA80FF234BCDF36211649321EB9845C8BAA89A4A
```

If `--populate` cannot find the packaged keyring, import the installed public
key explicitly and repeat the local-sign step:

```bash
sudo pacman-key --add /usr/share/pacman/keyrings/rom3-j613.asc
sudo pacman-key --lsign-key FA80FF234BCDF36211649321EB9845C8BAA89A4A
```

Verify the fingerprint before continuing:

```bash
sudo pacman-key --finger FA80FF234BCDF36211649321EB9845C8BAA89A4A
sudo pacman -Sy
```

Expected key:

```text
FA80FF234BCDF36211649321EB9845C8BAA89A4A
ROM3-j613 package signing <packages@rom3-j613.invalid>
```

Do not use `--skippgpcheck` or install packages when the signature or
fingerprint does not verify.

## Not yet production-qualified

- Apple Developer ID signing and notarization
- Gatekeeper behavior on a downloaded copy
- rollback and repeated cold-boot recovery exercises

Use this build only for controlled testing on a backed-up J613 installation.

## Verification

Built by
[workflow run 45144716504](https://github.com/adrgu372/ROM3-j613/actions/runs/45144716504)
on the macOS 26 arm64 runner with Xcode 26.2. The application passed strict
deep signature verification, and CI confirmed that the package is unsigned.

```text
77d6f5a97cd0c159d31b4ac8e971e97c8a05c1afe09944e34d63ca07eeccaeca  ROM3-j613-Installer-0.1.3.pkg
288481429a77e2396f4d4a0489d40a7e78162d6343a128f1481c44fb7f5d2fec  ROM3-j613-Installer-0.1.3.app.zip
```
