# Antigravity — Research & Contribution

**Researcher:** sandikodev
**Initialization date:** 2026-08-19
**Status:** Active — complete documentation, packaging prototypes ready

---

## Table of Contents

- [1. About Antigravity](#1-about-antigravity)
- [2. Installation on Research-01](#2-installation-on-research-01)
- [3. Repository Issues](#3-repository-issues)
- [4. Pull Requests — Full Status](#4-pull-requests--full-status)
- [5. Analysis & Contribution Recommendations](#5-analysis--contribution-recommendations)
- [6. Packaging Prototypes](#6-packaging-prototypes)
- [7. Desktop Launchers](#7-desktop-launchers)
- [8. Work Plan](#8-work-plan)
- [9. References](#9-references)

---

## 1. About Antigravity

### What is Antigravity?

Antigravity is Google's AI agent platform. It consists of 3 components:

| Component | Description | Current Version |
|---|---|---|
| **Antigravity 2.0** | Desktop app (Electron-based) | 2.8.1 |
| **Antigravity IDE** | Code editor integrated with AI agent | 2.5.5 |
| **Antigravity CLI (`agy`)** | Command-line interface for AI agent | 1.1.14 |

### Distribution

Google only provides:
- **Desktop + IDE:** Tarball download from `https://antigravity.google/download`
- **CLI:** Install script from `https://antigravity.google/cli/install.sh` → binary `agy`

**Not yet available:**
- ❌ Official package for Debian/Ubuntu (`.deb`)
- ❌ Official package for Arch Linux (AUR)
- ❌ Official package for Fedora/RHEL (`.rpm`)
- ❌ Official package for BSD

### Community Repository

| Repository | URL | Status |
|---|---|---|
| `opensnap/antigravity` | `https://github.com/opensnap/antigravity` | Community installer for Desktop + IDE |
| Google Official | `https://antigravity.google` | Official binary source |

---

## 2. Installation on Research-01

### Hardware & OS

| Item | Detail |
|---|---|
| Hostname | Research-01 |
| OS | Ubuntu 26.04 LTS (Resolute Raccoon) |
| Kernel | Linux 7.0.0-14-generic (x86_64) |
| Desktop | GNOME (Wayland) |
| CPU | Intel Core i7-6700K @ 4.00GHz |
| RAM | 32 GB DDR4 |
| GPU | NVIDIA GTX 980 Ti (Maxwell, 6GB) |

### What is Already Installed

| Component | Version | Location | Install Method |
|---|---|---|---|
| Antigravity CLI (`agy`) | 1.1.14 | `/usr/bin/agy` | `.deb` package |
| Antigravity Desktop 2.0 | 2.8.1 | `/opt/antigravity/Antigravity-x64/` | PR #4 installer |
| Antigravity IDE | 2.5.5 | `/opt/antigravity-ide/Antigravity-IDE/` | PR #4 installer |

### Installation Verification

```bash
# Check CLI
agy --version
# Output: 1.1.14

# Check Desktop + IDE (not installed)
antigravity-linux --status

# Install Desktop + IDE (from PR #4 clone)
sudo bash /tmp/antigravity/install.sh --all
```

### Update Commands

```bash
# CLI — auto-update via Google
agy  # checks for updates on start

# Desktop + IDE — via community installer
sudo antigravity-linux update --all
```

---

## 3. Repository Issues

### Issue #1 — Ubuntu 26.04 issue (OPEN)

**URL:** `https://github.com/opensnap/antigravity/issues/1`
**Reporter:** Mike20242
**Date:** 2026-07-25
**Labels:** (none)
**Assignees:** (none)

#### Description

```
Tried running the install command on latest Ubuntu version (Resolute Raccoon)
and it shows these errors:
Could not find official Antigravity 2.0 tarball for linux-x64 in Google download bundle
bash: line 1: tmpdir: unbound variable
How do I fix it?
```

#### 2 Bugs Reported

**Bug 1: Download URL Resolution Fails**
- Message: `Could not find official Antigravity 2.0 tarball for linux-x64 in Google download bundle`
- Cause: The `install.sh` script searches for a JavaScript file `main-*.js` on Google's download page, then scrapes the tarball URL from inside that JS bundle.
- Reality: Google has rebuilt the download page using the **Astro framework**. Download links are now static HTML `<a href>` elements, no longer inside JS bundles.
- Impact: The script cannot find download URLs at all.

**Bug 2: Bash `set -u` Error**
- Message: `bash: line 1: tmpdir: unbound variable`
- Cause: The script uses `set -euo pipefail` (including `-u` / nounset). In `main()`, the variable `tmpdir` is declared as `local` then used in `trap 'rm -rf "$tmpdir"' EXIT`.
- Problem: In some bash versions (including Ubuntu 26.04), local variables may already be undefined when the trap fires, causing it to fail with `unbound variable`.
- Impact: The script crashes before doing anything.

#### Issue Comments

| # | Author | Date | Content | Reactions |
|---|---|---|---|---|
| 1 | thuandt | 2026-07-25 | "same issue here in opensuse tumbleweed, looks like download pages changed and it can't extract download URL" | — |
| 2 | eallion | 2026-07-26 | "same" | 👍 1 |
| 3 | Believemenot | 2026-07-27 | "Ubuntu 24.04.4 LTS same" | — |
| 4 | napo67 | 2026-07-30 | "The problem is that the script tries to look for the files in the .js. The js has changed and the script does not work anymore. The correct place to look for the tarballs is the actual page source." | 👍 2 |
| 5 | simon-berry | 2026-08-08 | Same errors, "Same issues with Mint 22.3" | — |
| 6 | tazztone | 2026-08-13 | Shared fork that already has the fix: `github.com/tazztone/scripts/tree/main/sh/antigravity2` — tested working on Ubuntu 26.04 | — |

#### Impact

This bug affects all Debian/Ubuntu-based distros:
- ✅ Ubuntu 26.04 (Resolute Raccoon)
- ✅ Ubuntu 24.04.4 LTS
- ✅ Mint 22.3
- ✅ openSUSE Tumbleweed

#### Current Status

- Issue is still **OPEN**
- 3 open PRs attempting to fix this bug
- No review from maintainer (`opensnap`) yet
- No merge yet

---

## 4. Pull Requests — Full Status

### PR #2 — `fix: ubuntu 26.04 tmpdir: unbound variable`

| Field | Value |
|---|---|
| URL | `https://github.com/opensnap/antigravity/pull/2` |
| Author | eallion (Charles Chin) |
| Branch | `fix` → `main` |
| Created | 2026-07-26 |
| State | OPEN |
| Mergeable | MERGEABLE |
| Reviews | 0 |
| Comments | 1 |
| Reactions | 👍 2 |

#### Description

```
close: #1
```

#### Changes (Diff)

**File: `install.sh` + `docs/install.sh`**

1. **Fix `tmpdir` unbound variable:**
```bash
# Before:
trap 'rm -rf "$tmpdir"' EXIT
# After:
trap 'rm -rf "${tmpdir:-}"' EXIT

# Before (in print_downloads):
rm -rf "$tmpdir"
# After:
rm -rf "${tmpdir:-}"
```

2. **Rewrite `resolve_main_bundle()` — scan all JS files:**
```python
# Before: only search for main-*.js
matches = re.findall(r'(?:src|href)=["\']([^"\']*main-[^"\']+\.js)["\']', html)

# After: scan all .js files, download all, concatenate
matches = re.findall(r'(?:src|href)=["\']([^"\']+\.js)["\']', html)
for m in matches[:10]:
    full_url = urljoin(page, m)
    res = subprocess.run(["curl", ...], capture_output=True, text=True)
    if res.stdout:
        with (tmpdir / "bundle.txt").open("a", ...) as f:
            f.write("\n" + res.stdout)
```

3. **Remove `-E` from sudo calls:**
```bash
# Before:
exec sudo -E env "ANTIGRAVITY_LINUX_INSTALLER_URL=$INSTALLER_URL" bash ...
# After:
exec sudo env "ANTIGRAVITY_LINUX_INSTALLER_URL=$INSTALLER_URL" bash ...
```

4. **Rename variable:**
```bash
# Before: local js="$tmpdir/download.js"
# After: local bundle="$tmpdir/bundle.txt"
```

#### Comments

| Author | Date | Content | Reactions |
|---|---|---|---|
| hanklong99 | 2026-07-31 | "worked on my end! Thanks a lot!" | 👍 2 |

#### Evaluation

**Pros:**
- `tmpdir` fix is simple and correct
- Already tested on Ubuntu 26.04

**Cons:**
- Still scrapes JS files (even though Google has moved to static HTML)
- Downloads 10 JS files every install = slow and fragile
- No fallback mechanism

---

### PR #3 — `fixed download scraping for Astro frontend, added manual link fallback and self-update for script`

| Field | Value |
|---|---|
| URL | `https://github.com/opensnap/antigravity/pull/3` |
| Author | BhashkarGupta (BHASHKAR) |
| Branch | `main` → `main` |
| Created | 2026-08-13 |
| State | OPEN |
| Mergeable | MERGEABLE |
| Reviews | 0 |
| Comments | 0 |
| Reactions | — |

#### Description

```
Now ide and antigravity download link resolves correctly.
Tested on Ubuntu/Kubuntu 26.04
```

#### Changes (Diff)

1. **Add Astro + Next.js patterns for JS file discovery:**
```python
js_urls = re.findall(r'(?:src|href)=["\']([^"\']+\.js(?:\?[^"\']*)?)["\']', html)
js_urls += re.findall(r'["\']([^"\']+\/_astro\/[^"\']+\.js)["\']', html)
js_urls += re.findall(r'["\']([^"\']+\/_next\/static\/[^"\']+\.js)["\']', html)
```

2. **Manual URL fallback:**
```bash
prompt_manual_url() {
  # Opens browser to download page
  # Asks user to paste URL manually
  # Parses version from URL
}
```

3. **Self-update mechanism:**
```bash
INSTALLER_VERSION="1.1.0"
SKIP_SELF_UPDATE=0
# Flag: --no-self-update
```

4. **Environment variable overrides:**
```bash
# Override URL directly via env var
if [ "$product" = "ide" ] && [ -n "${ANTIGRAVITY_IDE_URL:-}" ]; then ...
if [ "$product" = "desktop" ] && [ -n "${ANTIGRAVITY_DESKTOP_URL:-}" ]; then ...
```

5. **User-Agent header:**
```bash
curl -fsSL -L -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64)" ...
```

#### Evaluation

**Pros:**
- Most comprehensive — many additional features
- Manual fallback very useful when auto-resolve fails
- Self-update mechanism good for long-term maintenance

**Cons:**
- Codebase becomes more complex
- Still scrapes JS files (even though HTML parsing is possible directly)
- `urllib.request` in Python (not `curl`) = additional dependency
- Does not fix `tmpdir` trap (still uses `local tmpdir` + `trap 'rm -rf "$tmpdir"'`)

---

### PR #4 — `fix: resolve downloads from static download page HTML`

| Field | Value |
|---|---|
| URL | `https://github.com/opensnap/antigravity/pull/4` |
| Author | ArezG |
| Branch | `fix/download-page-html` → `main` |
| Created | 2026-08-15 |
| State | OPEN |
| Mergeable | MERGEABLE |
| Reviews | 0 |
| Comments | 0 |
| Reactions | — |

#### Description

```
## Summary

- The official download page (https://antigravity.google/download) was rebuilt
  with Astro: download links are now static HTML <a href> elements instead of
  a main-*.js bundle. The installer scraped the JS bundle for
  id:"antigravity-2" markers, so update/install fails with "Could not find
  official Antigravity 2.0 tarball for linux-x64 in Google download bundle".

- Parse the download page HTML directly, scoped by product section id
  (antigravity-2, antigravity-cli, antigravity-ide, antigravity-sdk), and
  match the platform-specific tarball href (<platform>/Antigravity.tar.gz,
  <platform>/Antigravity%20IDE.tar.gz). Version detection is unchanged.

- Also fix the EXIT trap in main that referenced the local tmpdir variable:
  locals are destroyed before the trap runs, so under set -u every abort
  printed "tmpdir: variable sin asignar". Use a global TMP_WORK cleaned by
  a dedicated cleanup trap.
```

#### Changes (Diff)

1. **Remove JS bundle scraping entirely:**
```bash
# Before:
resolve_main_bundle() {
  # Download HTML → find main-*.js → download JS → return JS path
}

# After:
resolve_download_page() {
  local tmpdir="$1"
  local html="$tmpdir/download.html"
  curl -fsSL --compressed --retry 3 -o "$html" "$DOWNLOAD_PAGE"
  printf '%s\n' "$html"  # return HTML path directly
}
```

2. **Parse HTML directly by section ID:**
```python
# Before: search for marker in JS bundle
marker = 'id:"antigravity-2"'

# After: search for section ID in HTML
section_id = 'antigravity-2'
start = page.find(f'id="{section_id}"')
end = page.find(f'id="{next_section_id}"', start)
section = page[start:end if end != -1 else None]

# Find href in section
urls = re.findall(r'href=["\'](https?://[^"\'\s<>)]*)["\']', section)
```

3. **Fix trap with global variable:**
```bash
# Before:
local tmpdir
tmpdir=$(mktemp -d ...)
trap 'rm -rf "$tmpdir"' EXIT

# After:
TMP_WORK=""
cleanup() { [ -z "${TMP_WORK:-}" ] || rm -rf "$TMP_WORK"; return 0; }
trap cleanup EXIT
# ... later:
TMP_WORK=$(mktemp -d ...)
```

4. **Rename functions:**
```bash
resolve_main_bundle()      → resolve_download_page()
resolve_download_from_bundle() → resolve_download_from_page()
js parameter               → page parameter
```

#### Test Results

```
- bash install.sh --print-downloads resolves Antigravity 2.0 2.8.1
  (storage.googleapis.com/antigravity-public/antigravity-hub/...)
- bash install.sh --print-downloads --ide resolves Antigravity IDE 2.5.5
  (edgedl.me.gvt1.com .../stable/...)
- Real update --desktop run on Debian 13 (trixie) installed 2.8.1 successfully
- Exit status 0 after successful resolution (no tmpdir trap noise)
```

#### Evaluation

**Pros:**
- **Correct approach** — Google has moved to static HTML, no need to scrape JS anymore
- Cleanest code, easiest to understand
- Fixes trap correctly (global variable + dedicated cleanup function)
- Tested on Debian 13

**Cons:**
- No manual fallback (if Google changes page structure again, fails completely)
- No self-update mechanism

---

### Comparison of 3 PRs

| Aspect | PR #2 (eallion) | PR #3 (BhashkarGupta) | PR #4 (ArezG) |
|---|---|---|---|
| Fix tmpdir trap | ✅ `${tmpdir:-}` | ❌ Not fixed yet | ✅ Global `TMP_WORK` + cleanup() |
| Fix download resolver | Scan all JS | Scan JS + Astro/Next patterns | **Parse HTML directly** |
| Manual fallback | ❌ | ✅ | ❌ |
| Self-update | ❌ | ✅ | ❌ |
| User-Agent header | ❌ | ✅ | ❌ |
| Env var override | ❌ | ✅ | ❌ |
| Code cleanliness | Medium | Complex | **Cleanest** |
| Tested | Ubuntu 26.04 | Ubuntu/Kubuntu 26.04 | Debian 13 |
| Reviews | 0 | 0 | 0 |
| Merge conflicts | Likely (queue) | Likely (queue) | Likely (queue) |

#### Recommendation

**For merge:** PR #4 is the best fit because its approach is the most correct and cleanest.

**For complement:** PR #3 has valuable additional features (manual fallback, self-update). Can be split into separate PRs after PR #4 merges.

**PR #2:** Superseded by PR #4. Can be closed if PR #4 merges.

---

## 5. Analysis & Contribution Recommendations

### Existing Gaps

Google does not provide official packages for Linux distros:
- ❌ No `.deb` package for Debian/Ubuntu
- ❌ No PKGBUILD for Arch Linux AUR
- ❌ No `.rpm` package for Fedora/RHEL
- ❌ No Nix/Fresh/package others

### What sandikodev Has Contributed

#### ✅ Priority 1: Review & Test PR #4 — COMPLETE

- Tested PR #4 on Research-01 (Ubuntu 26.04 LTS)
- Desktop 2.0 v2.8.1 + IDE v2.5.5 installed successfully
- Posted review + test report on PR #4

#### ✅ Priority 2: APT Package (`.deb`) — COMPLETE

- Created `packaging/debian/` with DEBIAN/control, postinst/prerm/postrm
- `build-deb.sh` — multi-arch (amd64/arm64), auto-version, retry logic
- Built and tested `.deb` on Research-01
- Installed via `dpkg -i`, verified working

#### ✅ Priority 3: AUR Package (`PKGBUILD`) — COMPLETE

- Created `packaging/arch/` with PKGBUILD, .SRCINFO, install hooks
- Supports x86_64 + aarch64
- Desktop entries + shell profile included

#### ✅ Priority 4: Open Issue + Submit PR — COMPLETE

- Issue #5: "Proposal: Official .deb + AUR packages"
- PR #6: 15 files, 1035 lines (packaging + desktop entries + docs)
- Branch: `feat/packaging-cli`

#### ✅ Priority 5: Production Readiness — COMPLETE

- `build-deb.sh` hardened for production (multi-arch, error handling, retry)
- `PKGBUILD` with backup array, optdepends, both architectures
- GitHub Actions workflow for automated builds on tag push
- Test suite: 299 tests, 0 failures, portable (auto-detects host)

### Remaining Gaps

- ❌ No `.rpm` package for Fedora/RHEL (lower priority)
- ❌ No Nix/Fresh/package others (lower priority)

**Why:** Ubuntu/Debian is the most popular distro. A `.deb` package makes installation via `apt install` easy.

**What needs to be created:**
- `DEBIAN/control` — package metadata
- `DEBIAN/postinst` — post-install script (setup PATH, icon cache)
- `DEBIAN/prerm` — pre-remove script (cleanup)
- Desktop entry files
- Icon files

#### Priority 3: Prototype AUR Package (`PKGBUILD`)

**Why:** Arch Linux community is active on AUR. An AUR package makes installation via `yay -S antigravity-cli` easy.

**What needs to be created:**
- `PKGBUILD` — build script
- `.SRCINFO` — metadata for AUR
- Desktop entry files

#### Priority 4: Open New Issue

**Title:** `Proposal: Official .deb + AUR packages for antigravity CLI`

**Body:**
```
Google provides the Antigravity CLI via a curl-pipe-bash installer, but there
are no native packages for Linux distributions. This creates friction for:

1. Enterprise environments that prohibit curl | bash patterns
2. Systems with package managers that prefer native packages
3. Reproducible installations across teams

I'd like to propose adding:

1. A `.deb` package for Debian/Ubuntu (can be hosted on GitHub Releases)
2. An AUR PKGBUILD for Arch Linux

I have working prototypes ready for review. Would the maintainers be open to
accepting packaging contributions?
```

---

## 6. Packaging Prototypes

### 6.1 Debian Package (`.deb`) — Full Suite

See: `packaging/debian/`

**Package:** `antigravity` (Desktop 2.0 + IDE + CLI)

**Structure:**
```
packaging/debian/
├── DEBIAN/
│   ├── control          # Package metadata (all 3 components)
│   ├── postinst         # Post-install (chrome-sandbox, icons, desktop db)
│   ├── prerm            # Pre-remove
│   └── postrm           # Post-remove
├── usr/
│   └── share/
│       ├── applications/
│       │   ├── antigravity.desktop       # Desktop 2.0
│       │   ├── antigravity-ide.desktop   # IDE
│       │   └── antigravity-cli.desktop   # CLI
│       └── doc/antigravity/
│           └── antigravity-cli.sh
├── build-deb.sh         # Build script (downloads all 3 from Google)
└── README.md
```

**Quick Install:**
```bash
# Download from https://github.com/sandikodev/antigravity/releases
sudo dpkg -i antigravity_*_amd64.deb
sudo apt-get install -f
```

**Build locally:**
```bash
cd packaging/debian
bash build-deb.sh          # Full build
bash build-deb.sh --fast   # Fast build (strips Electron bloat)
```

**Cross-Distro Test Results:**

| Distro | Result |
|---|---|
| Ubuntu 24.04 (Noble) | FULL PASS |
| Ubuntu 22.04 (Jammy) | FULL PASS |
| Debian 12 (Bookworm) | FULL PASS |
| Debian 13 (Trixie) | FULL PASS |
| Linux Mint 22 | FULL PASS |
| Fedora 40 | Structure VALID (RPM-based) |

See: `packaging/debian/DISTRO-TEST-REPORT.md`

### 6.2 Arch Linux Package (`PKGBUILD`) — Full Suite

See: `packaging/arch/`

**Package:** `antigravity` (Desktop 2.0 + IDE + CLI)

**Structure:**
```
packaging/arch/
├── PKGBUILD                       # Build script (x86_64 + aarch64)
├── .SRCINFO                       # Metadata for AUR
├── antigravity.install            # Install hooks
├── antigravity-cli.sh             # Shell profile (/etc/profile.d/)
├── antigravity.desktop            # Desktop 2.0 entry
├── antigravity-ide.desktop        # IDE entry
├── antigravity-cli.desktop        # CLI entry (alacritty)
├── antigravity-cli-terminal.desktop  # CLI entry (xterm)
└── README.md
```

**Quick Install:**
```bash
# From AUR (when published)
yay -S antigravity

# From tarball
tar -xzf antigravity-*-x86_64.tar.gz
cd antigravity-*/
sudo cp -a Antigravity-* /opt/antigravity/
sudo cp -a Antigravity-IDE /opt/antigravity-ide/
sudo install -Dm755 agy /usr/bin/agy
```

### 6.3 GitHub Actions (Automated Builds)

See: `.github/workflows/release.yml`

Triggered on `v*` tag push. Builds:
- `.deb` packages (amd64 + arm64)
- Tarballs (x86_64 + aarch64)
- Creates GitHub Release with all artifacts

---

## 7. Desktop Launchers

See: `launchers/`

### Files Needed

| File | Purpose |
|---|---|
| `antigravity-cli.desktop` | Desktop entry for all DEs |
| `antigravity-cli-terminal.desktop` | Alternate entry (open in terminal) |
| `antigravity-cli.xml` | MIME type definition (optional) |

### Desktop Entry Standard

Desktop entries follow the freedesktop.org Desktop Entry Specification:
- https://specifications.freedesktop.org/desktop-entry-spec/latest/

**Format:**
```ini
[Desktop Entry]
Type=Application
Name=Antigravity CLI
GenericName=AI Agent CLI
Comment=Google Antigravity AI agent command-line interface
Exec=alacritty -e agy %F
Icon=antigravity-cli
Terminal=false
Categories=Development;IDE;Utility;
MimeType=text/plain;
Keywords=ai;agent;cli;google;antigravity;
StartupNotify=true
Actions=NewWindow;

[Desktop Action NewWindow]
Name=New Window
Exec=alacritty -e agy
```

### Desktop Environment Compatibility

| DE | `.desktop` Support | Notes |
|---|---|---|
| GNOME | ✅ | Full support, app grid + search |
| KDE Plasma | ✅ | Full support, Kickoff menu |
| XFCE | ✅ | Full support |
| Cinnamon | ✅ | Full support |
| MATE | ✅ | Full support |
| Budgie | ✅ | Full support |
| LXQt | ✅ | Full support |
| Pantheon (elementary) | ✅ | Full support |
| Sway / i3 / dwm | ⚠️ | Requires launcher (rofi, wofi, dmenu) |
| FreeBSD | ✅ | Via pkg + .desktop files |

---

## 8. Work Plan

### Phase 1: Review & Test ✅ COMPLETE

- [x] Fork repo `opensnap/antigravity` → `sandikodev/antigravity`
- [x] Test PR #4 on Research-01 — Desktop 2.8.1 + IDE 2.5.5 installed
- [x] Write review comment on PR #4
- [x] Post test report on PR #4

### Phase 2: Desktop Launchers ✅ COMPLETE

- [x] Create `antigravity-cli.desktop` (7 DE variants)
- [x] Create `install-launcher.sh` with `--install`, `--uninstall`, `--status`
- [x] Test on GNOME (Research-01)
- [x] Documentation for other DEs (GNOME, KDE, XFCE, Sway, i3, FreeBSD)

### Phase 3: Packaging Prototypes ✅ COMPLETE

- [x] Create `debian/control` + postinst/prerm/postrm
- [x] Create `PKGBUILD` for AUR (x86_64 + aarch64)
- [x] Test build `.deb` on Research-01
- [x] 299 tests, 0 failures

### Phase 4: Submit Contribution ✅ COMPLETE

- [x] Open Issue #5: "Proposal: Official .deb + AUR packages"
- [x] Submit PR #6: 15 files, 1035 lines (packaging + desktop entries + docs)
- [x] Branch `feat/packaging-cli` pushed to origin

### Phase 5: Production Readiness ✅ COMPLETE

- [x] `build-deb.sh` — multi-arch (amd64/arm64), auto-version, retry logic, color output
- [x] `build-deb.sh --fast` mode — strips Electron bloat (locales, debug, swiftshader)
- [x] `build-deb.sh` — builds in `/tmp` to avoid SSHFS timeouts
- [x] `PKGBUILD` — both architectures, backup array, optdepends
- [x] GitHub Actions workflow (`.github/workflows/release.yml`) — auto-build on tag push
- [x] Packaging READMEs with download from GitHub Releases
- [x] Test suite: 284 tests, 0 failures, portable (auto-detects host)
- [x] GitHub Release v2.8.1 — .deb uploaded (341MB)

### Phase 6: Cross-Distro Testing ✅ COMPLETE

- [x] Docker CE 29.7.2 installed on Research-01
- [x] Ubuntu 24.04 — FULL PASS (CLI, Desktop, IDE, entries, icons, symlinks)
- [x] Ubuntu 22.04 — FULL PASS
- [x] Debian 12 (Bookworm) — FULL PASS
- [x] Debian 13 (Trixie) — FULL PASS
- [x] Linux Mint 22 — FULL PASS
- [x] Fedora 40 — Package structure VALID (RPM-based, no dpkg)
- [x] Binary compatibility: glibc >= 2.28 satisfied by all tested distros
- [x] Test report: `packaging/debian/DISTRO-TEST-REPORT.md`

### Phase 7: Awaiting Review

- [ ] Maintainer review of PR #4 (install script fix)
- [ ] Maintainer review of PR #6 (packaging contribution)
- [ ] Merge into upstream
- [ ] Publish AUR package

---

## 9. References

### Official Documentation

| Resource | URL |
|---|---|
| Antigravity Download | `https://antigravity.google/download` |
| Antigravity CLI Install | `https://antigravity.google/cli/install.sh` |
| opensnap/antigravity | `https://github.com/opensnap/antigravity` |
| sandikodev/antigravity (fork) | `https://github.com/sandikodev/antigravity` |
| Issue #1 | `https://github.com/opensnap/antigravity/issues/1` |
| Issue #5 (packaging proposal) | `https://github.com/opensnap/antigravity/issues/5` |
| PR #2 | `https://github.com/opensnap/antigravity/pull/2` |
| PR #3 | `https://github.com/opensnap/antigravity/pull/3` |
| PR #4 (tested) | `https://github.com/opensnap/antigravity/pull/4` |
| PR #6 (packaging) | `https://github.com/opensnap/antigravity/pull/6` |
| GitHub Releases | `https://github.com/sandikodev/antigravity/releases` |

### Specifications

| Specification | URL |
|---|---|
| freedesktop.org Desktop Entry | `https://specifications.freedesktop.org/desktop-entry-spec/latest/` |
| Debian Policy Manual | `https://www.debian.org/doc/debian-policy/` |
| Arch PKGBUILD | `https://wiki.archlinux.org/title/PKGBUILD` |
| AUR Submitting Packages | `https://wiki.archlinux.org/title/AUR_submission_guidelines` |

### Download URLs (Current)

| Product | Platform | URL |
|---|---|---|
| Desktop 2.8.1 | linux-x64 | `https://storage.googleapis.com/antigravity-public/antigravity-hub/2.8.1-6512087774658560/linux-x64/Antigravity.tar.gz` |
| Desktop 2.8.1 | linux-arm | `https://storage.googleapis.com/antigravity-public/antigravity-hub/2.8.1-6512087774658560/linux-arm/Antigravity.tar.gz` |
| IDE 2.5.5 | linux-x64 | `https://edgedl.me.gvt1.com/edgedl/release2/j0qc3/antigravity/stable/2.5.5-4923483625488384/linux-x64/Antigravity%20IDE.tar.gz` |
| IDE 2.5.5 | linux-arm | `https://edgedl.me.gvt1.com/edgedl/release2/j0qc3/antigravity/stable/2.5.5-4923483625488384/linux-arm/Antigravity%20IDE.tar.gz` |

---

*Last updated: 2026-08-19*
*Researcher: sandikodev*
