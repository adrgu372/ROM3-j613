# ROM3-j613 installer catalog

This directory publishes a signed schema-5 catalog for one board only:

```text
apple,j613
```

It is a ROM3 testing catalog, not a catalog for the upstream Aurora installer
binary. An installer application must bundle the ROM3 trust root and use the
ROM3 release descriptor. Catalogs signed by the Aurora trust root and ROM3
catalogs are intentionally not interchangeable.

Files:

```text
catalog.json
catalog.json.sig
catalog.signed.json
trust-root.ed25519.pub
release.json
catalog-inputs.json
```

The raw Ed25519 trust root fingerprint is:

```text
sha256:2b7e847f34019f26eb9fc0dbd675611446357078f3057434be9491ba97c4404c
```

The catalog pins package snapshot `stable-20261128.1`, source filesystem release
`image-20261128.1`, native installer payload release `image-20261128.2`,
kernel `7.3.0.aurora1-46`, and the tested ROM3 KDE package set.

Native installer payload:

```text
sha256:d6c2f56feff16cf1e50f23b26c26fc05665af7a12920c3a16277700cc1332aa1
```

Source filesystem archive:

```text
sha256:3abdeb4aa2486b18dede3ee3d2758e82a0a5c96e673d9a4ab719ead162f75386
```

The catalog is deliberately `testing`: a clean install, first boot and recovery
cycle on a disposable J613 installation still must be qualified before this
catalog is promoted to stable.
