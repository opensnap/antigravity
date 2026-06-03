# Contributing

Thanks for helping improve Antigravity Easy Installer.

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
antigravity-easy --status
sudo antigravity-easy update --all
sudo bash install.sh --uninstall
```
