#!/usr/bin/env python3
"""Teach the legacy Stage 2 splitter about trailing ROM3 config variables."""

from pathlib import Path
import sys


def patch(text: str) -> str:
    replacements = (
        ("import gzip\n", "import zlib\n"),
        (
            "    gzip.decompress(trailer)\n",
            "    zlib.decompress(trailer, 16 + zlib.MAX_WBITS)\n",
        ),
    )
    for old, new in replacements:
        if text.count(old) != 1:
            raise ValueError(f"expected exactly one occurrence of {old.strip()!r}")
        text = text.replace(old, new)
    return text


def main() -> int:
    if len(sys.argv) != 2:
        raise SystemExit(f"usage: {Path(sys.argv[0]).name} PREPARE_STAGE2_PY")
    path = Path(sys.argv[1])
    original = path.read_text()
    updated = patch(original)
    if updated == original:
        raise ValueError("Stage 2 splitter did not change")
    path.write_text(updated)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
