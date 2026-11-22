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

## Production snapshot

```text
Tag: stable-20261122.2
Fingerprint: FA80FF234BCDF36211649321EB9845C8BAA89A4A
UID: ROM3-j613 package signing <packages@rom3-j613.invalid>
Repository database SHA-256: c05a8cd4a6b9a7e950d12474344d0da152d2bed2d699cf4a7603f1dc4a5dce50
```

The release serves the package database, signature, files database and all
package artifacts through:

```text
https://github.com/adrgu372/ROM3-j613/releases/latest/download
```

The second snapshot bundles all 25 direct sensitive dependencies of
`rom3-j613-meta`, including KWin, PipeWire, WirePlumber and the complete audio
protection stack. A fresh image therefore does not have to take those packages
from a moving `core` or `extra` repository.

