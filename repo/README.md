# Binary repository workspace

This directory is a local build/publish workspace. Package archives and signed
database files are intentionally ignored by Git.

Expected layout:

```text
repo/
├── aarch64/
│   ├── rom3-j613.db.tar.zst
│   ├── rom3-j613.files.tar.zst
│   ├── linux-rom3-j613-....pkg.tar.zst
│   ├── aura-rom3-j613-....pkg.tar.zst
│   └── *.sig
└── keys/
    └── rom3-j613-signing-key.asc
```

Private signing keys must never be committed here. Normal releases must use an
offline or protected signer and publish immutable snapshots.

Published snapshot:

```text
stable-20261122.2
```

It contains the complete direct dependency set for `rom3-j613-meta`.

