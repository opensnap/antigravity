# Antigravity — Arch Linux AUR Packaging

Full suite package: Desktop 2.0 + IDE + CLI for Arch Linux/Manjaro/Artix.

## Quick Install (Recommended)

### From AUR (when published)
```bash
# Using yay
yay -S antigravity

# Using paru
paru -S antigravity
```

### From GitHub Release (tarball)
```bash
# Download tarball from https://github.com/sandikodev/antigravity/releases
tar -xzf antigravity-*-x86_64.tar.gz
cd antigravity-*/
sudo cp -a Antigravity-* /opt/antigravity/
sudo cp -a Antigravity-IDE /opt/antigravity-ide/
sudo install -Dm755 agy /usr/bin/agy
```

## What's Included

| Component | Version | Location |
|---|---|---|
| Antigravity 2.0 Desktop | 2.8.1 | `/opt/antigravity/Antigravity-x64/` |
| Antigravity IDE | 2.8.1 | `/opt/antigravity-ide/Antigravity-IDE/` |
| Antigravity CLI (`agy`) | 1.1.14 | `/usr/bin/agy` |

## Build from Source

### Prerequisites
```bash
sudo pacman -S base-devel
```

### Build Locally
```bash
cd packaging/arch
makepkg -si
```

### Submit to AUR
```bash
# 1. Create AUR repo
git clone ssh://aur@aur.archlinux.org/antigravity.git

# 2. Copy files
cp PKGBUILD .SRCINFO antigravity.install antigravity-cli.sh antigravity.desktop antigravity-ide.desktop antigravity-cli.desktop antigravity-cli-terminal.desktop antigravity/

# 3. Update checksums
updpkgsums

# 4. Generate .SRCINFO
makepkg --printsrcinfo > .SRCINFO

# 5. Push
cd antigravity
git add .
git commit -m "Update to ${VERSION}"
git push
```

## Uninstall

```bash
sudo pacman -R antigravity
```

## Structure

```
packaging/arch/
├── PKGBUILD                       # Build script (x86_64 + aarch64)
├── .SRCINFO                       # Metadata for AUR
├── antigravity.install            # Install hooks
├── antigravity-cli.sh             # Shell profile
├── antigravity.desktop            # Desktop 2.0 entry
├── antigravity-ide.desktop        # IDE entry
├── antigravity-cli.desktop        # CLI entry (alacritty)
├── antigravity-cli-terminal.desktop  # CLI entry (xterm)
└── README.md                      # This file
```

## Notes

- All binaries are downloaded from Google's official source
- Desktop launcher uses `alacritty` as the default terminal
- Package provides Desktop, IDE, and CLI in one install
- `conflicts=('antigravity-cli' 'antigravity-cli-bin')` to prevent duplication
