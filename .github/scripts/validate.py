#!/usr/bin/env python3
"""
Validate all package.json files in the packages/ directory.
Run from the repo root: python3 .github/scripts/validate.py
"""

import json
import sys
import urllib.request
import urllib.error
from pathlib import Path

REQUIRED_TOP_LEVEL = {"name", "title", "description", "author", "license", "repository", "type", "versions"}
REQUIRED_VERSION   = {"source", "checksum"}
VALID_TYPES        = {"lcs", "lcb"}

errors = []

packages_dir = Path("packages")
if not packages_dir.exists():
    print("No packages/ directory found — nothing to validate.")
    sys.exit(0)

pkg_files = sorted(packages_dir.glob("*/package.json"))
if not pkg_files:
    print("No package.json files found — nothing to validate.")
    sys.exit(0)

for pkg_file in pkg_files:
    pkg_dir  = pkg_file.parent.name
    print(f"Validating {pkg_dir} ...")

    # --- Parse JSON ----------------------------------------------------------
    try:
        with open(pkg_file) as f:
            pkg = json.load(f)
    except json.JSONDecodeError as e:
        errors.append(f"{pkg_dir}: invalid JSON — {e}")
        continue

    # --- Required top-level fields -------------------------------------------
    missing = REQUIRED_TOP_LEVEL - set(pkg.keys())
    if missing:
        errors.append(f"{pkg_dir}: missing required fields: {', '.join(sorted(missing))}")

    # --- name must match directory --------------------------------------------
    if pkg.get("name") != pkg_dir:
        errors.append(
            f"{pkg_dir}: 'name' field ({pkg.get('name')!r}) must match the directory name"
        )

    # --- type must be known --------------------------------------------------
    if pkg.get("type") not in VALID_TYPES:
        errors.append(
            f"{pkg_dir}: 'type' must be one of {sorted(VALID_TYPES)}, got {pkg.get('type')!r}"
        )

    # --- versions ------------------------------------------------------------
    versions = pkg.get("versions")
    if not isinstance(versions, dict) or not versions:
        errors.append(f"{pkg_dir}: 'versions' must be a non-empty object")
        continue

    for version, vdata in versions.items():
        prefix = f"{pkg_dir} v{version}"

        if not isinstance(vdata, dict):
            errors.append(f"{prefix}: version entry must be an object")
            continue

        missing_v = REQUIRED_VERSION - set(vdata.keys())
        if missing_v:
            errors.append(
                f"{prefix}: missing required version fields: {', '.join(sorted(missing_v))}"
            )
            continue

        # --- source URL must be reachable ------------------------------------
        source = vdata["source"]
        try:
            req = urllib.request.Request(source, method="HEAD")
            with urllib.request.urlopen(req, timeout=15) as resp:
                if resp.status != 200:
                    errors.append(f"{prefix}: source URL returned HTTP {resp.status}: {source}")
                else:
                    print(f"  ✓ {version} — source URL reachable")
        except urllib.error.HTTPError as e:
            errors.append(f"{prefix}: source URL HTTP error {e.code}: {source}")
        except Exception as e:
            errors.append(f"{prefix}: source URL unreachable: {source} ({e})")

        # --- checksum must not be a placeholder ------------------------------
        checksum = vdata.get("checksum", "")
        if not checksum or checksum.startswith("sha256:placeholder"):
            errors.append(f"{prefix}: 'checksum' must be a real sha256 value, not a placeholder")

if errors:
    print(f"\n{'─' * 60}")
    print(f"Validation failed — {len(errors)} error(s):\n")
    for err in errors:
        print(f"  ✗ {err}")
    sys.exit(1)
else:
    print(f"\n{'─' * 60}")
    print(f"All {len(pkg_files)} package(s) valid.")
