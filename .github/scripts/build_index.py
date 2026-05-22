#!/usr/bin/env python3
"""
Rebuild index.json from all packages/*/package.json files.
Run from the repo root: python3 .github/scripts/build_index.py
"""

import json
from pathlib import Path

packages_dir = Path("packages")
index = {}

for pkg_file in sorted(packages_dir.glob("*/package.json")):
    try:
        with open(pkg_file) as f:
            pkg = json.load(f)
    except (json.JSONDecodeError, OSError):
        continue

    name = pkg.get("name")
    if not name:
        continue

    # Find the latest version (simple descending sort)
    versions = pkg.get("versions", {})
    latest = sorted(versions.keys(), reverse=True)[0] if versions else None

    index[name] = {
        "title":       pkg.get("title", ""),
        "description": pkg.get("description", ""),
        "author":      pkg.get("author", ""),
        "type":        pkg.get("type", ""),
        "license":     pkg.get("license", ""),
        "repository":  pkg.get("repository", ""),
        "latest":      latest,
        "versions":    sorted(versions.keys(), reverse=True),
    }

with open("index.json", "w") as f:
    json.dump({"packages": index}, f, indent=2)
    f.write("\n")

print(f"index.json written with {len(index)} package(s).")
