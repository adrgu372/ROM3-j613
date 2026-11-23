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

ROM3-built images install `rom3-j613-keyring`, whose service imports and
locally trusts the exported public key after Aurora creates or repairs the
machine-local pacman master key. The client configuration is:

```ini
[rom3-j613]
SigLevel = Required DatabaseOptional
Server = https://HOST/rom3-j613/$arch
```

Unsigned package installation must remain disabled.

For an existing non-ROM3 installation, use `scripts/bootstrap-client.sh`; it
performs the same key import and configures the repository without upgrading
the kernel or any other package.

An external GitHub release can carry replacement kernels or other sensitive
packages as a signed override repository. The base repository stays enabled,
only exact versions named by the signed override manifest are admitted, and
all other quarantine entries remain blocked. See
[override-feed.md](override-feed.md).

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

