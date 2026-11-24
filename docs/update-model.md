# Update model

ROM3 does not claim that an unrestricted `pacman -Syu` is safe. Arch Linux ARM
is rolling, while ROM3 qualifies a specific hardware stack.

The supported user-facing update command is:

```bash
sudo rom3-j613-update --apply
```

Check the proposed transaction first:

```bash
sudo rom3-j613-update --check
```

## Policy

Packages listed in `stack/quarantine.packages` may move only when:

1. the source patch series applies to the new version;
2. packages build reproducibly;
3. the complete proposed package set passes dependency checks;
4. a Stage 2 candidate is generated separately;
5. a cold boot verifies display, GPU, render node and audio;
6. the new combination is signed and published as a new snapshot.

## Client flow

```text
sudo rom3-j613-update --check
  -> show the proposed transaction and fail on unqualified changes

sudo rom3-j613-update --apply
  -> refresh package databases
  -> compute proposed transaction
  -> compare quarantine with verified-stack.json
  -> stop if an unqualified sensitive package would move
  -> take a read-only Btrfs snapshot
  -> back up boot.bin and m1n1 configuration
  -> install the qualified package set
  -> generate Stage 2 candidate
  -> require cold-boot validation
```

`--apply` invokes `pacman -Syu` with a temporary pacman configuration. It
removes from `IgnorePkg` only packages explicitly approved by the active signed
override manifest; a normal update without an override keeps the ROM3 stack
pinned. This lets ordinary packages move while the kernel, display, GPU and
audio stack remain an exact tested set.

Do not replace either command with an unrestricted `pacman -Syu`. A direct
upgrade can update dependencies around the protected packages without the
ROM3 preflight, backup, signature-approved exception list and post-update
package check.

After a kernel update, reboot and verify the running hardware stack:

```bash
sudo /usr/share/rom3-j613/verify-live-system.sh
```

The Btrfs snapshot and ESP backup paths are printed by `--apply` before the
transaction starts. Keep them until the new kernel has booted and passed the
live checks.

Ordinary packages can still follow Arch Linux ARM, but a transaction that
crosses an unqualified compatibility boundary must fail closed.

## Repository channels

The initial design has:

- `stable`: fully hardware-qualified J613 package set;
- `testing`: candidate snapshots not yet cold-boot qualified.

Only `stable` should be configured for normal users.

The root filesystem must be Btrfs. A failed snapshot aborts the update.

When `/swap/swapfile` is active in the root subvolume, `--apply` stops it for
the snapshot, recreates it as a new independent swapfile and enables it again.
This avoids both the Btrfs snapshot refusal and leaving a 16 GiB machine
without disk swap until an old snapshot is deleted.

