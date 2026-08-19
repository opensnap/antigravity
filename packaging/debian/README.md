# Antigravity — Debian/Ubuntu Packaging

Full suite `.deb` package: Desktop 2.0 + IDE + CLI for Ubuntu/Debian.

## Quick Install (Recommended)

Download the latest `.deb` from [GitHub Releases](https://github.com/sandikodev/antigravity/releases):

```bash
# amd64 (Intel/AMD)
sudo dpkg -i antigravity_*_amd64.deb
sudo apt-get install -f

# arm64 (ARM/Raspberry Pi)
sudo dpkg -i antigravity_*_arm64.deb
sudo apt-get install -f
```

## What's Included

| Component | Version | Location |
|---|---|---|
| Antigravity 2.0 Desktop | 2.8.1 | `/opt/antigravity/Antigravity-x64/` |
| Antigravity IDE | 2.8.1 | `/opt/antigravity-ide/Antigravity-IDE/` |
| Antigravity CLI (`agy`) | 1.1.14 | `/usr/bin/agy` |

## After Install

```bash
# Launch from app menu or command line
antigravity          # Desktop 2.0
antigravity-ide      # IDE
agy                  # CLI

# Update
sudo antigravity-linux update --all

# Uninstall
sudo dpkg -r antigravity
```

## Build from Source

### Prerequisites
```bash
sudo apt install dpkg-dev curl tar
```

### Build
```bash
cd packaging/debian

# Build for your architecture (auto-detected)
bash build-deb.sh 2.8.1 1.1.14

# Or use defaults
bash build-deb.sh
```

### Output
```
packaging/debian/build/antigravity_2.8.1-1_amd64.deb
```

## Structure

```
packaging/debian/
├── DEBIAN/
│   ├── control          # Package metadata
│   ├── postinst         # Post-install (chrome-sandbox, icons, desktop db)
│   ├── prerm            # Pre-remove
│   └── postrm           # Post-remove
├── usr/
│   ├── share/applications/
│   │   ├── antigravity.desktop       # Desktop 2.0
│   │   ├── antigravity-ide.desktop   # IDE
│   │   └── antigravity-cli.desktop   # CLI
│   └── doc/antigravity/
│       └── antigravity-cli.sh        # Shell profile
├── build-deb.sh         # Build script
└── README.md            # This file
```

## Notes

- Binaries are downloaded from Google's official source
- Chrome-sandbox permissions are set automatically (Electron requirement)
- Nautilus "Open in IDE" extension included
- Desktop entries follow freedesktop.org specification
- Post-install updates icon cache and desktop database automatically
