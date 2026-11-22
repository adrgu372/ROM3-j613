#!/usr/bin/env python3
"""Validate the signed J613-only ROM3 schema-5 catalog."""

from __future__ import annotations

import argparse
import base64
import json
import subprocess
import tempfile
from pathlib import Path

ED25519_SPKI_PREFIX = bytes.fromhex("302a300506032b6570032100")
EXPECTED_PAYLOAD = "sha256:0f01a50a55c3e48bd4fecfe45883b7f4e28e90328b88bf6a90a847e2a7951f68"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--catalog", required=True, type=Path)
    parser.add_argument("--envelope", required=True, type=Path)
    parser.add_argument("--public-key", required=True, type=Path)
    args = parser.parse_args()

    envelope = json.loads(args.envelope.read_text())
    if set(envelope) != {"schema_version", "catalog", "signature"}:
        raise SystemExit("catalog envelope has unexpected fields")
    if envelope["schema_version"] != 1:
        raise SystemExit("catalog envelope schema must be 1")

    catalog_bytes = base64.b64decode(envelope["catalog"], validate=True)
    signature = base64.b64decode(envelope["signature"], validate=True)
    if catalog_bytes != args.catalog.read_bytes():
        raise SystemExit("enveloped catalog differs from catalog.json")
    if len(signature) != 64:
        raise SystemExit("Ed25519 signature must be 64 bytes")

    public_key = args.public_key.read_bytes()
    if len(public_key) != 32:
        raise SystemExit("Ed25519 public key must be 32 bytes")
    with tempfile.TemporaryDirectory(prefix="rom3-catalog-verify-") as temp:
        public_der = Path(temp) / "public.der"
        signature_file = Path(temp) / "signature"
        public_der.write_bytes(ED25519_SPKI_PREFIX + public_key)
        signature_file.write_bytes(signature)
        subprocess.run(
            [
                "openssl",
                "pkeyutl",
                "-verify",
                "-pubin",
                "-inkey",
                public_der,
                "-rawin",
                "-in",
                args.catalog,
                "-sigfile",
                signature_file,
            ],
            check=True,
            stdout=subprocess.DEVNULL,
        )

    catalog = json.loads(catalog_bytes)
    if catalog.get("schemaVersion") != 5:
        raise SystemExit("catalog schemaVersion must be 5")
    if catalog.get("channel") != "testing":
        raise SystemExit("unqualified ROM3 catalog must use testing")
    if not isinstance(catalog.get("sequence"), int) or catalog["sequence"] <= 0:
        raise SystemExit("catalog sequence must be positive")
    models = catalog.get("models")
    if not isinstance(models, list) or len(models) != 1:
        raise SystemExit("ROM3 catalog must contain exactly one model")
    model = models[0]
    if model.get("deviceIdentifier") != "apple,j613":
        raise SystemExit("ROM3 catalog must enable only apple,j613")
    if model.get("status") != "enabled":
        raise SystemExit("J613 model must be enabled")
    if model.get("installationProfile") != "arch-kde":
        raise SystemExit("J613 model must use arch-kde")
    if model.get("payloadDigest") != EXPECTED_PAYLOAD:
        raise SystemExit("catalog payload digest does not match the verified image")
    for field in (
        "engineVersion",
        "engineDigest",
        "engineArtifact",
        "repairManifestDigest",
        "repairManifestArtifact",
    ):
        if field in model:
            raise SystemExit(f"schema-5 catalog must not contain {field}")
    parts = model.get("payloadArtifact", {}).get("parts")
    if not isinstance(parts, list) or not 2 <= len(parts) <= 16:
        raise SystemExit("catalog payload must contain 2..16 parts")
    if sum(part.get("sizeBytes", 0) for part in parts) != model["payloadArtifact"].get(
        "sizeBytes"
    ):
        raise SystemExit("catalog payload part sizes do not match the whole payload")

    print("ROM3-j613 signed schema-5 catalog is valid.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
