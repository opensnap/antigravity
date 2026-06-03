# Contributing

Thanks for helping improve Antigravity Linux Installer.

## Easy way

The easiest way to contribute is to checking if this smoothy works on your OS and if any issues arise, [open an issue](https://github.com/opensnap/antigravity/issues/new), describe the problem, your system details, and screenshots (if possible).

## Development workflow

1. Fork the repository.
2. Create a feature branch.
3. Edit `install.sh`.
4. Run:

```bash
bash scripts/sync-site.sh
bash scripts/check.sh
```

5. Open a pull request.

## Rules of thumb

- Do not mirror or redistribute Google Antigravity binaries.
- Do not hard-code a third-party tarball URL.
- Keep installs reversible through `--uninstall`.
- Prefer standard Linux integration points: `.desktop` files, MIME entries, icon themes, and file-manager extensions.
- Avoid `--no-sandbox` launchers unless there is a documented, user-selected troubleshooting flag.

## Testing checklist

Please test on at least one fresh VM before opening a release PR:

- Ubuntu LTS x86_64
- Debian stable x86_64
- ARM64 if you touched architecture logic

Recommended commands:

```bash
sudo bash install.sh --all --force
antigravity-linux --status
sudo antigravity-linux update --all
sudo bash install.sh --uninstall
```
