#!/usr/bin/env python3
"""
Rebuild index.json and generated READMEs from all packages/*/package.json files.
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

    versions = pkg.get("versions", {})
    sorted_versions = sorted(versions.keys(), reverse=True)
    latest = sorted_versions[0] if sorted_versions else None

    index[name] = {
        "title":       pkg.get("title", ""),
        "description": pkg.get("description", ""),
        "author":      pkg.get("author", ""),
        "type":        pkg.get("type", ""),
        "license":     pkg.get("license", ""),
        "repository":  pkg.get("repository", ""),
        "latest":      latest,
        "versions":    sorted_versions,
    }

    # Write a README.md into each package folder so GitHub renders it
    _type_label = {"lcs": "Script Library", "lcb": "LCB Extension"}.get(pkg.get("type", ""), pkg.get("type", ""))
    _versions_table = "\n".join(
        f"| `{v}` | {versions[v].get('source', '')} |"
        for v in sorted_versions
    )

    readme = f"""\
# {pkg.get("title", name)}

**Package:** `{name}`
**Type:** {_type_label}
**Author:** {pkg.get("author", "")}
**License:** {pkg.get("license", "")}
**Repository:** {pkg.get("repository", "")}

{pkg.get("description", "")}

## Installation

```
hxtpmInstall "{name}"
```

## Versions

| Version | Source |
|---------|--------|
{_versions_table}
"""
    readme_path = pkg_file.parent / "README.md"
    readme_path.write_text(readme)

# Write index.json
with open("index.json", "w") as f:
    json.dump({"packages": index}, f, indent=2)
    f.write("\n")

# Update the packages table in the main README
if index:
    rows = "\n".join(
        f"| [`{name}`](packages/{name}) | {info['title']} | {info['type'].upper()} | `{info['latest']}` | {info['description'][:80] + '…' if len(info['description']) > 80 else info['description']} |"
        for name, info in sorted(index.items())
    )
    table = f"""\
## Available packages

| Package | Title | Type | Latest | Description |
|---------|-------|------|--------|-------------|
{rows}
"""
else:
    table = "## Available packages\n\nNo packages yet.\n"

main_readme = Path("README.md").read_text()

# Replace everything from the ## Available packages header to end of file,
# or append it if the section doesn't exist yet
marker = "## Available packages"
if marker in main_readme:
    main_readme = main_readme[:main_readme.index(marker)] + table
else:
    main_readme = main_readme.rstrip() + "\n\n" + table

Path("README.md").write_text(main_readme)

print(f"index.json written with {len(index)} package(s).")
print(f"README.md files written for {len(index)} package(s).")
