# hxtpm — HyperXTalk Package Registry

This repository is the official package registry for HyperXTalk. It contains an index of community and first-party packages that can be installed via the built-in package manager.

---

## Package types

| Type  | Description |
|-------|-------------|
| `lcs` | Script library (`.livecodescript`) — installed to the user libraries folder and loaded immediately |
| `lce` | LiveCode extension (`.lce` zip) — pre-compiled extension package installed to the user extensions folder via the IDE extension manager, loaded without an IDE restart |

---

## Package format

Each package lives in its own directory under `packages/`, named after the package itself:

```
packages/
  com.example.library.myutils/
    package.json
```

### package.json schema

```json
{
  "name": "com.example.library.myutils",
  "title": "My Utils",
  "description": "A short description of what the package does.",
  "author": "Your Name or Organisation",
  "license": "mit",
  "repository": "https://github.com/example/myutils",
  "type": "lcs",
  "versions": {
    "1.0.0": {
      "source": "https://raw.githubusercontent.com/example/myutils/refs/tags/v1.0.0/myutils.livecodescript",
      "checksum": "sha256:abc123...",
      "min_engine": "10.0.0"
    }
  }
}
```

#### Field reference

| Field | Required | Description |
|-------|----------|-------------|
| `name` | ✓ | Reverse-DNS package identifier. Must match the directory name. |
| `title` | ✓ | Human-readable name. |
| `description` | ✓ | One or two sentences describing what the package does. |
| `author` | ✓ | Your name or organisation. |
| `license` | ✓ | SPDX license identifier (e.g. `mit`, `gpl-3.0`, `apache-2.0`). |
| `repository` | ✓ | URL of the package's source repository. |
| `type` | ✓ | `lcs` or `lce`. |
| `versions` | ✓ | Object mapping version strings to version entries (see below). |

#### Version entry fields

| Field | Required | Description |
|-------|----------|-------------|
| `source` | ✓ | Direct URL to the installable file. For `lcs`, a URL to the `.livecodescript` file. For `lce`, a URL to the pre-compiled `.lce` zip package. |
| `checksum` | ✓ | SHA-256 checksum of the file at `source`, formatted as `sha256:<hex>`. |
| `min_engine` | | Minimum HyperXTalk engine version required. |

---

## Publishing a package

1. **Tag a release** in your package's repository so the source file is available at a stable, versioned URL.

2. **Compute the checksum** of the source file:
   ```sh
   curl -sL <source-url> | shasum -a 256
   ```

3. **Fork this repository** and add your package:
   ```
   packages/com.example.library.myutils/package.json
   ```

4. **Open a pull request.** The validation workflow will automatically check that your `package.json` is well-formed and the source URL is reachable. A maintainer will review and merge.

---

## Naming conventions

Package names follow reverse-DNS notation:

- Community packages: use your own domain or GitHub username, e.g. `com.example.library.foo` or `io.github.username.foo`

Libraries and widgets that ship built into HyperXTalk are not listed here — they are always available without installation.

## Available packages

| Package | Title | Type | Latest | Description |
|---------|-------|------|--------|-------------|
| [`com.hyperxtalk.library.test`](packages/com.hyperxtalk.library.test) | hxtpm Test Library | LCS | `1.0.0` | Minimal test library for verifying the hxtpm package manager install pipeline. C… |
| [`com.hyperxtalk.macosfingerprint`](packages/com.hyperxtalk.macosfingerprint) | macOS Fingerprint Authentication | LCE | `1.0.0` | Native LCE library providing Touch ID and passcode authentication on macOS via t… |
| [`com.hyperxtalk.spriteengine`](packages/com.hyperxtalk.spriteengine) | Sprite Engine | MULTI | `1.0.0` |  |
| [`community.ferruslogic.plugin.devguides`](packages/community.ferruslogic.plugin.devguides) | DevGuides | LCP | `1.0.7` | LiveCode IDE plugin that shows smart alignment guides and pixel distances while … |
| [`org.openxtalk.library.fsevents`](packages/org.openxtalk.library.fsevents) | macOS FSEvents | LCE | `1.0.0` | Native LCE library wrapping the macOS FSEvents API to provide real-time filesyst… |
