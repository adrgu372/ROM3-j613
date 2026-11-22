# Security

- Sign package archives and repository databases.
- Keep signing keys outside this repository.
- Publish immutable snapshot releases and retain their checksums.
- Reject unsigned package installation.
- Store Stage 2 candidates separately until verified.
- Keep boot-image recovery independent from package updates.
- Never commit machine-specific secrets, LUKS keys, Secure Boot keys or Apple
  firmware data extracted from a user's Mac.

Report packaging or boot-chain security issues privately to the repository
owner before publishing exploitation details.

