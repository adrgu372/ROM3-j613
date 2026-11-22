#!/usr/bin/env python3
"""Build and sign the J613-only ROM3 schema-5 support catalog."""

from __future__ import annotations

import argparse
import base64
import datetime
import hashlib
import json
import re
import subprocess
import sys
import tempfile
from pathlib import Path

REVISION = re.compile(r"^[0-9a-f]{40}$")
EVIDENCE = re.compile(r"^[0-9a-z.-]{1,128}$")
PART = re.compile(r"\.part\.(\d{2})$")
READ_BLOCK = 8 * 1024 * 1024
REQUIRED = {
    "schema_version",
    "distribution",
    "channel",
    "installation_profile",
    "payload_name",
    "metadata_name",
    "evidence_revision",
    "asahi_installer_tag",
    "asahi_installer_revision",
    "asahi_installer_data_revision",
    "downstream_revision",
    "device_identifiers",
}


def digest(path: Path) -> str:
    value = hashlib.sha256()
    with path.open("rb") as stream:
        while block := stream.read(READ_BLOCK):
            value.update(block)
    return value.hexdigest()


def regular_file(path: Path) -> Path:
    if not path.is_file() or path.is_symlink():
        raise SystemExit(f"unsafe or missing asset: {path}")
    return path


def artifact(path: Path, base_url: str) -> dict:
    return {
        "sourceURL": f"{base_url}/{path.name}",
        "fileName": path.name,
        "sizeBytes": path.stat().st_size,
    }


def payload_parts(payload: Path) -> list[Path]:
    parts = sorted(
        path
        for path in payload.parent.iterdir()
        if path.name.startswith(payload.name + ".part.")
        and PART.search(path.name)
    )
    if not 2 <= len(parts) <= 16:
        raise SystemExit(f"payload needs 2..16 parts, found {len(parts)}")
    for index, part in enumerate(parts):
        regular_file(part)
        expected = f"{payload.name}.part.{index:02d}"
        if part.name != expected:
            raise SystemExit(f"expected payload part {expected}, found {part.name}")
    return parts


def load_inputs(path: Path) -> dict:
    data = json.loads(regular_file(path).read_text())
    if not isinstance(data, dict) or set(data) != REQUIRED:
        raise SystemExit("catalog inputs have missing or unknown keys")
    if data["schema_version"] != 1:
        raise SystemExit("catalog inputs schema_version must be 1")
    if data["distribution"] != "ROM3-j613":
        raise SystemExit("catalog distribution must be ROM3-j613")
    if data["channel"] != "testing":
        raise SystemExit("an unqualified ROM3 catalog must use testing")
    if data["installation_profile"] != "arch-kde":
        raise SystemExit("catalog installation profile must be arch-kde")
    if data["device_identifiers"] != ["apple,j613"]:
        raise SystemExit("ROM3 catalog must enable only apple,j613")
    if not re.fullmatch(r"v[0-9]+\.[0-9]+\.[0-9]+", data["asahi_installer_tag"]):
        raise SystemExit("invalid asahi installer tag")
    for key in (
        "asahi_installer_revision",
        "asahi_installer_data_revision",
        "downstream_revision",
    ):
        if not REVISION.fullmatch(data[key]):
            raise SystemExit(f"{key} must be a 40-character lowercase revision")
    if not EVIDENCE.fullmatch(data["evidence_revision"]):
        raise SystemExit("invalid evidence revision")
    for key in ("payload_name", "metadata_name"):
        if Path(data[key]).name != data[key]:
            raise SystemExit(f"{key} must be a plain file name")
    return data


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--inputs", required=True, type=Path)
    parser.add_argument("--assets-dir", required=True, type=Path)
    parser.add_argument("--base-url", required=True)
    parser.add_argument("--output-dir", required=True, type=Path)
    parser.add_argument("--signing-key", type=Path)
    parser.add_argument("--now")
    args = parser.parse_args()

    if not args.base_url.startswith("https://") or args.base_url.endswith("/"):
        raise SystemExit("--base-url must be an HTTPS URL without a trailing slash")
    inputs = load_inputs(args.inputs)
    assets = args.assets_dir
    payload = regular_file(assets / inputs["payload_name"])
    metadata = regular_file(assets / inputs["metadata_name"])
    parts = payload_parts(payload)

    part_records = []
    whole = hashlib.sha256()
    declared = 0
    for part in parts:
        part_digest = hashlib.sha256()
        size = 0
        with part.open("rb") as stream:
            while block := stream.read(READ_BLOCK):
                whole.update(block)
                part_digest.update(block)
                size += len(block)
        if size == 0:
            raise SystemExit(f"empty payload part: {part.name}")
        declared += size
        record = artifact(part, args.base_url)
        record["sha256"] = f"sha256:{part_digest.hexdigest()}"
        part_records.append(record)

    payload_digest = digest(payload)
    if declared != payload.stat().st_size or whole.hexdigest() != payload_digest:
        raise SystemExit("payload parts do not reconstruct the complete payload")

    if args.now:
        issued = datetime.datetime.strptime(args.now, "%Y-%m-%dT%H:%M:%SZ").replace(
            tzinfo=datetime.timezone.utc
        )
    else:
        issued = datetime.datetime.now(datetime.timezone.utc).replace(microsecond=0)

    payload_artifact = artifact(payload, args.base_url)
    payload_artifact["parts"] = part_records
    model = {
        "deviceIdentifier": "apple,j613",
        "status": "enabled",
        "installationProfile": "arch-kde",
        "asahiInstallerTag": inputs["asahi_installer_tag"],
        "asahiInstallerRevision": inputs["asahi_installer_revision"],
        "asahiInstallerDataRevision": inputs["asahi_installer_data_revision"],
        "downstreamRevision": inputs["downstream_revision"],
        "metadataDigest": f"sha256:{digest(metadata)}",
        "payloadDigest": f"sha256:{payload_digest}",
        "evidenceRevision": inputs["evidence_revision"],
        "metadataArtifact": artifact(metadata, args.base_url),
        "payloadArtifact": payload_artifact,
    }
    catalog = {
        "schemaVersion": 5,
        "channel": "testing",
        "sequence": int(issued.timestamp()),
        "issuedAt": issued.strftime("%Y-%m-%dT%H:%M:%SZ"),
        "models": [model],
    }

    output = args.output_dir
    output.mkdir(parents=True, exist_ok=True)
    catalog_path = output / "catalog.json"
    catalog_bytes = (json.dumps(catalog, indent=2) + "\n").encode()
    catalog_path.write_bytes(catalog_bytes)

    if args.signing_key:
        signing_key = regular_file(args.signing_key)
        signature_path = output / "catalog.json.sig"
        envelope_path = output / "catalog.signed.json"
        with tempfile.TemporaryDirectory(prefix="rom3-catalog-sign-") as temp:
            public_pem = Path(temp) / "public.pem"
            subprocess.run(
                ["openssl", "pkey", "-in", signing_key, "-pubout", "-out", public_pem],
                check=True,
            )
            subprocess.run(
                [
                    "openssl",
                    "pkeyutl",
                    "-sign",
                    "-rawin",
                    "-inkey",
                    signing_key,
                    "-in",
                    catalog_path,
                    "-out",
                    signature_path,
                ],
                check=True,
            )
            subprocess.run(
                [
                    "openssl",
                    "pkeyutl",
                    "-verify",
                    "-pubin",
                    "-inkey",
                    public_pem,
                    "-rawin",
                    "-in",
                    catalog_path,
                    "-sigfile",
                    signature_path,
                ],
                check=True,
                stdout=subprocess.DEVNULL,
            )
        envelope = {
            "schema_version": 1,
            "catalog": base64.b64encode(catalog_bytes).decode(),
            "signature": base64.b64encode(signature_path.read_bytes()).decode(),
        }
        envelope_path.write_text(json.dumps(envelope, separators=(",", ":")) + "\n")

    print(f"catalog={catalog_path}")
    print(f"catalog_sha256={hashlib.sha256(catalog_bytes).hexdigest()}")
    print(f"sequence={catalog['sequence']}")
    print(f"payload_digest=sha256:{payload_digest}")
    print(f"payload_parts={len(parts)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
