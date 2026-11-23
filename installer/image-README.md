# ROM3-j613 KDE image payload

This release contains an `arch-kde` filesystem payload for the Aurora Installer
metadata layout `alarm-btrfs-v1`. It is built only for `apple,j613`.

The payload uses the package snapshot `stable-20261122.9`, including:

- `linux-aurora 7.3.0.aurora1-43` with corrected J613 speaker-sense sampling;
- `speakersafetyd 2.0.1-1.2` with probe-rate recovery;
- automatic ROM3 keyring restoration after first boot;
- the signed external override-feed guard;
- the verified PipeWire, WirePlumber, Aura, Mesa and KWin stack;
- ROM3 repository, meta and update-guard packages.

GitHub limits a release asset to 2 GiB, so the 4.92 GiB filesystem archive is
stored as five 1 GiB parts. `SHA256SUMS` is signed by the ROM3-j613 project key.

Download and verify the helper:

```bash
tag=image-20261123.1
base=https://github.com/adrgu372/ROM3-j613/releases/download/$tag
mkdir -p "rom3-j613-$tag"
cd "rom3-j613-$tag"
curl -fLO "$base/reassemble-image-payload.sh"
curl -fLO "$base/SHA256SUMS"
curl -fLO "$base/SHA256SUMS.sig"
gpg --verify SHA256SUMS.sig SHA256SUMS
bash ./reassemble-image-payload.sh
cd ..
```

The reassembly verifies every chunk and requires the original archive digest:

```text
sha256:6cb9e140fc904d033d807680c07cc1e065e5344d7ec543819bed9100b710b6d8
```

Installer inputs:

```text
rom3-j613-image-20261123.1/arch-kde-filesystems.tar.zst
rom3-j613-image-20261123.1/arch-kde-image.json
```

The filesystem archive also carries GitHub build provenance. For offline
verification, use the included `arch-kde-filesystems.tar.zst.attestation.jsonl`.
