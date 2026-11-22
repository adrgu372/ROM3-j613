# ROM3 catalog trust root

`catalog-signing.ed25519.pub` is the 32-byte raw Ed25519 public key used to
verify ROM3 schema-5 installer catalogs.

Fingerprint:

```text
sha256:2b7e847f34019f26eb9fc0dbd675611446357078f3057434be9491ba97c4404c
```

The private key is stored outside the Git tree at:

```text
/home/adi/.config/rom3-j613/catalog-signing/catalog-signing.ed25519.pem
```

It must never be committed or copied into an installer payload. Changing this
key requires a new installer trust root and invalidates every previously built
ROM3 installer that does not already trust the replacement.
