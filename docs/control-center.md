# ROM3-j613 Control Center

`rom3-j613-control` is the graphical frontend for an installed J613 system.
It presents the current kernel, ROM3 bootloader, Apple firmware and protected package set,
and provides three update paths.

## Safe updates

`Check safe updates` and `Apply safe updates` run:

```text
rom3-j613-update --check-safe
rom3-j613-update --apply-safe
```

These modes never load or apply an override manifest. Every package in
`quarantine.packages` stays at its installed version while ordinary Arch and
ordinary Arch packages can move. A Btrfs snapshot and boot backup are created before
an apply transaction.

## Signed ROM3 releases

`Check ROM3 release` and `Install ROM3 release` invoke the fixed helper
`rom3-j613-github-update`. The helper:

1. queries the public releases of `adrgu372/ROM3-j613`;
2. selects the newest complete `override-YYYYMMDD.N` release;
3. requires the manifest, pacman database and signatures;
4. authenticates them with the fixed ROM3 fingerprint;
5. configures that immutable feed;
6. uses `rom3-j613-update --check-approved` or `--apply-approved`.

The approved mode admits only exact protected versions listed in the signed
override. Other protected packages remain pinned. Ordinary packages may also
move through the normal update transaction.

The GUI never executes arbitrary shell text as root. Privileged operations use
fixed `pkexec` argument vectors.

## Storage errors

Apply operations run a storage preflight before configuring a feed or changing
packages. The updater requires enough free space to create the rollback
snapshot and then recreate the active swapfile with a 1 GiB reserve. An empty,
truncated or inactive swapfile also aborts the update before changes are made.

The helper returns exit status `75` for insufficient space and `74` for an
unsafe swapfile. The Control Center maps these statuses to specific dialogs
instead of a generic operation failure.

## Automatic updates

The optional systemd timer runs daily and is disabled by default:

```text
rom3-j613-github-update.timer
```

Turning on `Install new signed ROM3 releases automatically` writes:

```text
/etc/rom3-j613/auto-update.conf

AUTO_UPDATE=1
```

and enables the timer. Automatic mode uses the same signed discovery and
approved-update path. It does not automatically reboot.

If `/etc/default/update-m1n1` disables Stage 2 updates and a transaction
changes boot-critical packages, the helper prints a warning. A tested Stage 2
candidate is still required before the next reboot.
