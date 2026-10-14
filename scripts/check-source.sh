#!/usr/bin/env bash
set -euo pipefail

project_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$project_dir"

bash -n scripts/*.sh
sh -n auto/config

python3 - <<'PY'
import json
import re
import struct
from pathlib import Path

root = Path.cwd()
version = (root / "VERSION").read_text(encoding="utf-8").strip()
if not re.fullmatch(r"\d+\.\d+\.\d+(?:-[0-9A-Za-z][0-9A-Za-z.-]*)?", version):
    raise SystemExit(f"Invalid VERSION: {version!r}")

for path in (root / "config/includes.chroot").rglob("metadata.json"):
    json.loads(path.read_text(encoding="utf-8"))

for path in (root / "config/includes.chroot").rglob("*.png"):
    with path.open("rb") as handle:
        header = handle.read(24)
    if len(header) != 24 or header[:8] != b"\x89PNG\r\n\x1a\n" or header[12:16] != b"IHDR":
        raise SystemExit(f"Invalid PNG header: {path}")
    width, height = struct.unpack(">II", header[16:24])
    if width == 0 or height == 0:
        raise SystemExit(f"Invalid PNG dimensions: {path}")

for path in (root / "config/package-lists").glob("*.list.chroot"):
    seen = set()
    for lineno, raw in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        if not re.fullmatch(r"[a-z0-9][a-z0-9+.-]*", line):
            raise SystemExit(f"Invalid package entry {path}:{lineno}: {line!r}")
        if line in seen:
            raise SystemExit(f"Duplicate package entry {path}:{lineno}: {line}")
        seen.add(line)

required = ["LICENSE", "ASSETS.md", "CONTRIBUTING.md", "docs/RELEASE.md"]
for name in required:
    if not (root / name).is_file():
        raise SystemExit(f"Missing project file: {name}")

print(f"Source checks passed for Hanabira OS {version}")
PY
