# Repository pipeline validation

Date: 2026-11-22

An ephemeral signing key was created under `/tmp`, used to exercise the full
package signing and `repo-add` pipeline, and then destroyed. It is not a
production trust root.

## Packages exercised

```text
linux-aurora 7.3.0.aurora1-42
linux-aurora-headers 7.3.0.aurora1-42
aura 1.0.0b14.1-3
rom3-j613-meta 1-1
rom3-j613-guard 1-1
rom3-j613-release 1-1
```

## Checks passed

- every package received a detached signature;
- `repo-add --include-sigs` indexed every package;
- `rom3-j613.db.tar.zst` and `rom3-j613.files.tar.zst` were generated;
- both databases received detached signatures;
- every package and database signature verified;
- the snapshot `SHA256SUMS` verified for packages, signatures and databases;
- the generated package names appeared in the database.

## Production status

The production signing key has not been created or published. The test snapshot
must not be served as a ROM3 stable repository.

## Keyring package validation

A second ephemeral key was used to generate the `rom3-j613-keyring` package.
The package built and contained:

```text
/usr/share/pacman/keyrings/rom3-j613.asc
/usr/share/pacman/keyrings/rom3-j613.gpg
/usr/share/pacman/keyrings/rom3-j613-trusted
/usr/share/pacman/keyrings/rom3-j613-revoked
```

The test exposed and fixed `makepkg` treating an ASCII-armored `.asc` source as
a detached signature. Public key sources now use the `.pub` extension while
the installed keyring remains ASCII-armored.

The keyring test key was destroyed after validation.

