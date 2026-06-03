# Antigravity Easy Installer

One-command Linux installer/updater for **Google Antigravity 2.0** and **Antigravity IDE** using Google's official tarball downloads.

This project does **not** mirror, modify, or redistribute Google Antigravity. The installer resolves the latest official Google tarball from `https://antigravity.google/download` at install/update time, then adds Linux desktop integration around it.

> Unofficial community helper. Not affiliated with, endorsed by, or supported by Google.

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
  - `sudo antigravity-easy update --all`
- Adds folder opening integration for IDE:
  - file manager `Open With` support through `.desktop` MIME entries
  - optional GNOME Files/Nautilus right-click menu helper
- Preserves the Electron/Chromium sandbox permission model instead of launching with `--no-sandbox` by default.

## Quick install from GitHub Pages

After you publish this repository with GitHub Pages, replace `YOUR_GITHUB_USERNAME` below:

```bash
INSTALLER_URL="https://YOUR_GITHUB_USERNAME.github.io/antigravity-easy/install.sh"
curl -fsSL "$INSTALLER_URL" | sudo -E env ANTIGRAVITY_EASY_INSTALLER_URL="$INSTALLER_URL" bash -s -- --all
```

Install only Antigravity 2.0 desktop app:

```bash
INSTALLER_URL="https://YOUR_GITHUB_USERNAME.github.io/antigravity-easy/install.sh"
curl -fsSL "$INSTALLER_URL" | sudo -E env ANTIGRAVITY_EASY_INSTALLER_URL="$INSTALLER_URL" bash -s --
```

Install only Antigravity IDE:

```bash
INSTALLER_URL="https://YOUR_GITHUB_USERNAME.github.io/antigravity-easy/install.sh"
curl -fsSL "$INSTALLER_URL" | sudo -E env ANTIGRAVITY_EASY_INSTALLER_URL="$INSTALLER_URL" bash -s -- --ide
```

## Quick install from raw GitHub

If you do not want to use GitHub Pages yet:

```bash
INSTALLER_URL="https://raw.githubusercontent.com/YOUR_GITHUB_USERNAME/antigravity-easy/main/install.sh"
curl -fsSL "$INSTALLER_URL" | sudo -E env ANTIGRAVITY_EASY_INSTALLER_URL="$INSTALLER_URL" bash -s -- --all
```

## Update

Once installed from a published URL:

```bash
sudo antigravity-easy update --all
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

```bash
antigravity-easy --status
```

Or from a local checkout:

```bash
bash install.sh --status
```

## Uninstall

```bash
sudo antigravity-easy --uninstall
```

Or from a local checkout:

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
--status           Show installed helper-managed apps and versions
--print-downloads  Print resolved official Google tarball URLs
--uninstall        Remove helper-managed installation
```

## What it installs

| Component | Path |
|---|---|
| Antigravity 2.0 | `/opt/antigravity` |
| Antigravity IDE | `/opt/antigravity-ide` |
| CLI launchers | `/usr/local/bin/antigravity`, `/usr/local/bin/antigravity-ide` |
| Update helper | `/usr/local/bin/antigravity-easy` |
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

1. Create a public GitHub repository named `antigravity-easy`.
2. Push this project to the `main` branch.
3. Open **Settings → Pages**.
4. Set **Build and deployment → Source** to **GitHub Actions**.
5. Run or wait for the **Deploy GitHub Pages** workflow.
6. Your installer will be available at:

```text
https://YOUR_GITHUB_USERNAME.github.io/antigravity-easy/install.sh
```

## Repository commands

```bash
git init
git add .
git commit -m "Initial Antigravity Easy Installer"
git branch -M main
git remote add origin https://github.com/YOUR_GITHUB_USERNAME/antigravity-easy.git
git push -u origin main
```

Or with GitHub CLI:

```bash
gh repo create antigravity-easy --public --source=. --remote=origin --push
```

## Development

Run local checks:

```bash
bash scripts/check.sh
```

Sync the GitHub Pages copy of the installer:

```bash
bash scripts/sync-site.sh
```

## Security notes

This installer uses `sudo` because it installs system-wide files under `/opt`, `/usr/local/bin`, `/usr/share/applications`, and `/usr/share/icons`.

For safer review before running:

```bash
curl -fsSL "https://YOUR_GITHUB_USERNAME.github.io/antigravity-easy/install.sh" -o install.sh
less install.sh
sudo bash install.sh --all
```

## License

MIT. See [LICENSE](LICENSE).
