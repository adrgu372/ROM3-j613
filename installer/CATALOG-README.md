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

The catalog pins package snapshot `stable-20261122.5`, source filesystem release
`image-20261122.5`, native installer payload release `image-20261122.6`,
kernel `7.3.0.aurora1-43`, and `speakersafetyd 2.0.1-1.2`.

Native installer payload:

```text
sha256:9bd87e6f77fe55a0e624b2fb7175a2f9b1ac24658761773733e2edfefab04c4a
```

Source filesystem archive:

```text
sha256:0f01a50a55c3e48bd4fecfe45883b7f4e28e90328b88bf6a90a847e2a7951f68
```

The catalog is deliberately `testing`: a clean install, first boot and recovery
cycle on a disposable J613 installation still must be qualified before this
catalog is promoted to stable.
