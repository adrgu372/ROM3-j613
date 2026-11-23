# Existing-system bootstrap

ROM3 can be attached to a working `J613` installation without replacing the
kernel or performing a full update.

Run as root:

```bash
cd /home/adi/ROM3-j613
./scripts/bootstrap-client.sh
```

The script:

1. downloads the pinned public key;
2. verifies its fingerprint;
3. imports and locally signs it with `pacman-key`;
4. installs the `[rom3-j613]` pacman configuration;
5. backs up and updates `/etc/pacman.conf` once;
6. refreshes package metadata;
7. installs `rom3-j613-release`, which pulls the exact meta and guard packages;
8. verifies the installed package set.

The two pacman configuration files are created before the repository can be
used, then adopted by `rom3-j613-release`. The package install therefore uses
an overwrite exception limited to those exact ROM3 paths.

It deliberately does not run `pacman -Syu`.

Expected signing fingerprint:

```text
FA80FF234BCDF36211649321EB9845C8BAA89A4A
ROM3-j613 package signing <packages@rom3-j613.invalid>
```

After bootstrap, inspect pending changes with:

```bash
sudo rom3-j613-update --check
```

Apply a reviewed update with:

```bash
sudo rom3-j613-update --apply
```

Do not substitute an unrestricted `pacman -Syu`; the update guard preserves
the tested kernel, display, GPU and audio stack. See
[update-model.md](update-model.md).

