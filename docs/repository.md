# Signed package repository

## Threat model

The repository is not only an update cache. It is the compatibility boundary
for packages that can prevent boot, display or audio.

## Signing

1. Create the signing key with `scripts/create-signing-key.sh`.
2. Keep the GNUPGHOME outside this Git repository.
3. Export only the public key with `scripts/export-public-key.sh`.
4. Sign every package and both pacman databases.
5. Publish immutable snapshots.

Example:

```bash
export ROM3_GPG_KEY=<signing-key-fingerprint>
./scripts/create-signing-key.sh
./scripts/export-public-key.sh
./scripts/publish-snapshot.sh stable-20261122.1
```

The secret key directory must never be committed or uploaded.

## Client trust

Users import the exported public key into `pacman-key` and configure:

```ini
[rom3-j613]
SigLevel = Required DatabaseOptional
Server = https://HOST/rom3-j613/$arch
```

Unsigned package installation must remain disabled.

## Immutable releases

Never mutate an existing snapshot in place. A new tested stack gets a new tag.
The `stable` channel should point to one complete signed snapshot and promotion
must be atomic.

The bootstrap transport is GitHub Releases:

```text
https://github.com/adrgu372/ROM3-j613/releases/latest/download
```

Each release carries the signed repository databases and every package in that
snapshot. Git tracks metadata, recipes and tooling only. The mirrorlist can
later move to object storage without changing package identities.

