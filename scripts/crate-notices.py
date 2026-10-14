#!/usr/bin/env python3
"""Record resolved Rust dependencies and preserve their shipped license texts."""
import argparse
import json
import subprocess
import urllib.request
import urllib.parse
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument("manifest", type=Path)
parser.add_argument("output", type=Path)
parser.add_argument("--fetch-missing", action="store_true",
                    help="Fetch root notices from upstream at each crate's recorded Git revision")
args = parser.parse_args()
metadata = json.loads(subprocess.check_output([
    "cargo", "metadata", "--locked", "--format-version=1", "--filter-platform",
    "x86_64-unknown-linux-gnu", "--manifest-path", str(args.manifest)
]))
resolved = {node["id"] for node in metadata["resolve"]["nodes"]}
records, texts, missing = [], [], []
upstream_cache = {}
for package in sorted(metadata["packages"], key=lambda p: (p["name"], p["version"])):
    if package["id"] not in resolved or package["source"] is None:
        continue
    root = Path(package["manifest_path"]).parent
    candidates = []
    for path in root.iterdir():
        name = path.name.lower()
        if path.is_file() and name.startswith(("license", "licence", "copying", "copyright", "unlicense")):
            candidates.append(path)
        elif path.is_dir() and name == "licenses":
            candidates.extend(p for p in path.rglob("*") if p.is_file())
    if package.get("license_file"):
        path = root / package["license_file"]
        if path.is_file():
            candidates.append(path)
    candidates = sorted(set(candidates))
    record = {key: package.get(key) for key in ("name", "version", "license", "repository", "source")}
    record["notice_files"] = [str(p.relative_to(root)) for p in candidates]
    records.append(record)
    if not candidates:
        fetched = []
        vcs_file = root / ".cargo_vcs_info.json"
        repo = urllib.parse.urlparse(package.get("repository") or "")
        if args.fetch_missing and repo.hostname == "github.com" and vcs_file.is_file():
            owner_name = "/".join(repo.path.strip("/").split("/")[:2]).removesuffix(".git")
            revision = json.loads(vcs_file.read_text())["git"]["sha1"]
            key = (owner_name, revision)
            if key not in upstream_cache:
                url = f"https://api.github.com/repos/{owner_name}/git/trees/{revision}?recursive=1"
                req = urllib.request.Request(url, headers={"User-Agent": "Hanabira-OS-notice-audit"})
                tree = json.load(urllib.request.urlopen(req, timeout=30))["tree"]
                upstream_cache[key] = [item["path"] for item in tree
                    if item["type"] == "blob" and "/" not in item["path"]
                    and item["path"].lower().startswith(("license", "licence", "copying", "copyright", "unlicense"))]
            for path in upstream_cache[key]:
                url = f"https://raw.githubusercontent.com/{owner_name}/{revision}/{path}"
                req = urllib.request.Request(url, headers={"User-Agent": "Hanabira-OS-notice-audit"})
                content = urllib.request.urlopen(req, timeout=30).read().decode("utf-8")
                fetched.append(url)
                texts.append(f'\n=== {package["name"]} {package["version"]} / upstream {path} ===\n'
                             + f"Source: {url}\n" + content)
            record["upstream_notice_urls"] = fetched
        if not fetched:
            missing.append(f'{package["name"]} {package["version"]}')
    for path in candidates:
        texts.append(f'\n=== {package["name"]} {package["version"]} / {path.relative_to(root)} ===\n'
                     + path.read_text(encoding="utf-8", errors="replace"))
args.output.mkdir(parents=True, exist_ok=True)
(args.output / "manifest.json").write_text(json.dumps({"target": "x86_64-unknown-linux-gnu",
    "packages": records, "missing_notice_texts": missing}, indent=2) + "\n")
(args.output / "LICENSES.txt").write_text("Hanabira compositor resolved crate notices.\n"
    "Each dependency retains its own license. Inventory is not a source archive.\n" + "\n".join(texts))
print(f"Recorded {len(records)} dependencies; {len(missing)} without shipped notice text")
if missing:
    print("Review required: " + ", ".join(missing))
