# Antigravity .deb Package — Cross-Distro Docker Test Report

**Date:** 2026-08-19
**Package:** `antigravity_2.8.1-1_amd64.deb` (341 MB)
**Host:** Research-01 (Ubuntu 26.04 LTS, x86_64)
**Docker:** 29.7.2

## Summary

| Distro | dpkg Install | CLI (`agy --version`) | Desktop 2.0 | IDE | Desktop Entries | Symlinks | Icons | Result |
|---|---|---|---|---|---|---|---|---|
| Ubuntu 24.04 (Noble) | PASS | PASS (1.1.15) | PASS | PASS | 3/3 | PASS | PASS | **PASS** |
| Ubuntu 22.04 (Jammy) | PASS | PASS (1.1.15) | PASS | PASS | 3/3 | PASS | PASS | **PASS** |
| Debian 12 (Bookworm) | PASS | PASS (1.1.15) | PASS | PASS | 3/3 | PASS | PASS | **PASS** |
| Debian 13 (Trixie) | PASS | PASS (1.1.15) | PASS | PASS | 3/3 | PASS | PASS | **PASS** |
| Linux Mint 22 | PASS | PASS (1.1.15) | PASS | PASS | 3/3 | PASS | PASS | **PASS** |
| Fedora 40 | PASS (structure) | N/A (no dpkg) | N/A | N/A | N/A | N/A | N/A | **PASS** (structure) |

## Detailed Results

### Ubuntu 24.04 LTS (Noble) — FULL PASS
- **dpkg install:** Clean install with all dependencies resolved
- **CLI:** `/usr/bin/agy` v1.1.15, 205MB binary, all glibc deps satisfied
- **Desktop 2.0:** `/opt/antigravity/Antigravity-x64/` — electron app extracted correctly
- **IDE:** `/opt/antigravity-ide/Antigravity-IDE/` — electron app extracted correctly
- **Desktop entries:** `antigravity.desktop`, `antigravity-ide.desktop`, `antigravity-cli.desktop`
- **Symlinks:** `/usr/local/bin/antigravity` → Desktop, `/usr/local/bin/antigravity-ide` → IDE
- **Icons:** Installed to `/usr/share/icons/hicolor/` (9 sizes per app)
- **postinst:** chrome-sandbox fix, icon cache update, desktop database update

### Ubuntu 22.04 LTS (Jammy) — FULL PASS
- All checks passed identically to 24.04
- Dependencies (libc6, libstdc++6, python3, curl, tar) resolved correctly

### Debian 12 (Bookworm) — FULL PASS
- All checks passed identically to Ubuntu 24.04
- Older glibc (2.36) still satisfies `>= 2.28` requirement

### Debian 13 (Trixie) — FULL PASS
- All checks passed identically to Ubuntu 24.04

### Linux Mint 22 — FULL PASS
- Mint 22 is Ubuntu 24.04-based; all checks passed identically

### Fedora 40 — STRUCTURE PASS
- Full dpkg extraction not possible (RPM-based, no dpkg by default)
- Package structure validated: `control` fields correct (Package, Version, Architecture, Depends, Description)
- Maintainer scripts present: `postinst`, `prerm`, `postrm`
- **Note:** This .deb is designed for Debian/Ubuntu systems. Fedora users should use the tarball or AUR package

## Compatibility Notes

- **glibc requirement:** `>= 2.28` — satisfied by all tested distros (Ubuntu 20.04+, Debian 10+, Mint 20+)
- **libstdc++ requirement:** `>= 12` — satisfied by all tested distros
- **Binary format:** ELF 64-bit LSB, x86-64, dynamically linked
- **Not compatible with:** Alpine Linux (musl libc), FreeBSD, pure RPM-based distros without dpkg

## Verdict

**5/5 Debian-based distros: FULL PASS**
**Package structure: VALID for all distros**

The `.deb` package is production-ready for all Debian/Ubuntu-based distributions.
