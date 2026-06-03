# Antigravity Linux Installer

```
 █████╗ ███╗   ██╗████████╗██╗ ██████╗ ██████╗  █████╗ ██╗   ██╗██╗████████╗██╗   ██╗
██╔══██╗████╗  ██║╚══██╔══╝██║██╔════╝ ██╔══██╗██╔══██╗██║   ██║██║╚══██╔══╝╚██╗ ██╔╝
███████║██╔██╗ ██║   ██║   ██║██║  ███╗██████╔╝███████║██║   ██║██║   ██║    ╚████╔╝
██╔══██║██║╚██╗██║   ██║   ██║██║   ██║██╔══██╗██╔══██║╚██╗ ██╔╝██║   ██║     ╚██╔╝
██║  ██║██║ ╚████║   ██║   ██║╚██████╔╝██║  ██║██║  ██║ ╚████╔╝ ██║   ██║      ██║
╚═╝  ╚═╝╚═╝  ╚═══╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝  ╚═══╝  ╚═╝   ╚═╝      ╚═╝

                   ██╗     ██╗███╗   ██╗██╗   ██╗██╗  ██╗
                   ██║     ██║████╗  ██║██║   ██║╚██╗██╔╝
                   ██║     ██║██╔██╗ ██║██║   ██║ ╚███╔╝
                   ██║     ██║██║╚██╗██║██║   ██║ ██╔██╗
                   ███████╗██║██║ ╚████║╚██████╔╝██╔╝ ██╗
                   ╚══════╝╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝  ╚═╝
```

> **This is a community helper. Not affiliated with, endorsed by, or supported by Google.**

One-command Linux installer/updater for **Google Antigravity 2.0** and **Antigravity IDE** using Google's official tarball downloads.

This project does **not** mirror, modify, or redistribute Google Antigravity. The installer resolves the latest official Google tarball from [https://antigravity.google/download](https://antigravity.google/download) at install/update time, then adds Linux desktop integration around it.


## Features

- Installs the latest official Antigravity 2.0 Linux tarball.
- Optionally installs Antigravity IDE.
- Supports x86_64 and ARM64 Linux builds when Google provides them.
- Installs app menu launchers.
- Installs icons when available from the tarball.
- Adds command-line launchers:
  - `antigravity`
  - `antigravity-ide`
- Adds update helper:
  - `sudo antigravity-linux update --all`
- Adds folder opening integration for IDE:
  - file manager `Open With` support through `.desktop` MIME entries
  - optional GNOME Files/Nautilus right-click menu helper
- Preserves the Electron/Chromium sandbox permission model instead of launching with `--no-sandbox` by default.

## Minimum Requirements
> `glibc >= 2.28, glibcxx >= 3.4.25 (e.g. Ubuntu 20. Debian 10, Fedora 36, RHEL 8)`

## Quick install from GitHub Pages

Install Antigravity 2.0 and the IDE:

```bash
INSTALLER_URL="https://opensnap.github.io/antigravity/install.sh"
curl -fsSL "$INSTALLER_URL" | sudo -E env ANTIGRAVITY_LINUX_INSTALLER_URL="$INSTALLER_URL" bash -s -- --all
```

Install only Antigravity 2.0 desktop app:

```bash
INSTALLER_URL="https://opensnap.github.io/antigravity/install.sh"
curl -fsSL "$INSTALLER_URL" | sudo -E env ANTIGRAVITY_LINUX_INSTALLER_URL="$INSTALLER_URL" bash -s --
```

Install only Antigravity IDE:

```bash
INSTALLER_URL="https://opensnap.github.io/antigravity/install.sh"
curl -fsSL "$INSTALLER_URL" | sudo -E env ANTIGRAVITY_LINUX_INSTALLER_URL="$INSTALLER_URL" bash -s -- --ide
```

## Quick install from raw GitHub

```bash
INSTALLER_URL="https://raw.githubusercontent.com/opensnap/antigravity/main/install.sh"
curl -fsSL "$INSTALLER_URL" | sudo -E env ANTIGRAVITY_LINUX_INSTALLER_URL="$INSTALLER_URL" bash -s -- --all
```

## Update

Once installed from a published URL:

```bash
sudo antigravity-linux update --all
```

Desktop app only:

```bash
sudo update-antigravity
```

IDE only:

```bash
sudo update-antigravity-ide
```

## Status

When installed from a published URL:

```bash
antigravity-linux --status
```

For local-checkout installs without a stored installer URL, use the local script:

```bash
bash install.sh --status
```

## Uninstall

When installed from a published URL:

```bash
sudo antigravity-linux --uninstall
```

For local-checkout installs without a stored installer URL, use the local script:

```bash
sudo bash install.sh --uninstall
```

The uninstall removes helper-managed files from `/opt`, `/usr/local/bin`, `/usr/share/applications`, `/usr/share/icons`, and the Nautilus extension path. It does not delete user settings in home directories.

## Options

```text
--desktop          Install/update Antigravity 2.0 desktop app only
--ide              Install/update Antigravity IDE only
--all              Install/update desktop app + IDE
--cli              Also run Google's official Antigravity CLI installer
--no-nautilus      Skip GNOME Files/Nautilus context-menu helper
--no-apt           Do not install apt dependencies automatically
--force            Reinstall even when the recorded version matches
--install-url URL  Store URL used by the antigravity-linux update command
--status           Show installed helper-managed apps and versions
--print-downloads  Print resolved official Google tarball URLs
--uninstall        Remove helper-managed installation
-y, --yes          Non-interactive; assume yes where possible
```

## What it installs

| Component | Path |
|---|---|
| Antigravity 2.0 | `/opt/antigravity` |
| Antigravity IDE | `/opt/antigravity-ide` |
| CLI launchers | `/usr/local/bin/antigravity`, `/usr/local/bin/antigravity-ide` |
| Update helper | `/usr/local/bin/antigravity-linux` |
| App launchers | `/usr/share/applications/antigravity*.desktop` |
| Icons | `/usr/share/icons/hicolor/512x512/apps/` |
| Nautilus extension | `/usr/share/nautilus-python/extensions/open-in-antigravity-ide.py` |

## Supported systems

Designed for Debian/Ubuntu-based distributions with `apt-get`.

The script can also run on other Linux distributions if the required tools already exist:

- `bash`
- `curl`
- `tar`
- `python3`
- `desktop-file-utils`
- `xdg-utils`

GNOME Files/Nautilus integration additionally needs `python3-nautilus`.

## GitHub Pages setup

This repository includes a GitHub Actions workflow at `.github/workflows/pages.yml` that deploys the `docs/` directory to GitHub Pages.

1. Use this repository, `opensnap/antigravity`, or fork it under your own account.
2. Push your changes to the `main` branch.
3. Open **Settings → Pages**.
4. Set **Build and deployment → Source** to **GitHub Actions**.
5. Run or wait for the **Deploy GitHub Pages** workflow.
6. Your installer will be available at:

```text
https://opensnap.github.io/antigravity/install.sh
```

## Local development

Clone the repository:

```bash
git clone https://github.com/opensnap/antigravity.git
cd antigravity
```

Run local checks:

```bash
bash scripts/check.sh
```

Sync the GitHub Pages copy of the installer:

```bash
bash scripts/sync-site.sh
```

Install from the local checkout:

```bash
sudo bash install.sh --all
```

## Security notes

This installer uses `sudo` because it installs system-wide files under `/opt`, `/usr/local/bin`, `/usr/share/applications`, and `/usr/share/icons`.

For safer review before running:

```bash
curl -fsSL "https://opensnap.github.io/antigravity/install.sh" -o install.sh
less install.sh
sudo bash install.sh --all
```

## Contributing

Contributions are welcome! Please open an issue or submit a pull request.

> Read the [contributing guidelines](CONTRIBUTING.md) for more information.

The easiest way to contribute is to check whether this works smoothly on your OS and if any issues arise, [open an issue](https://github.com/opensnap/antigravity/issues/new), describe the problem, your system details, and screenshots (if possible).

### Currently Confirmed OSes

- Ubuntu 24 (LTS)

## License

MIT. See [LICENSE](LICENSE).
