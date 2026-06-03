#!/usr/bin/env bash
# Antigravity Linux Installer
# Installs/updates Google Antigravity 2.0 and, optionally, Antigravity IDE on Debian/Ubuntu.
# It resolves the latest official Google tarballs from https://antigravity.google/download.
set -euo pipefail

ORIGINAL_ARGS=("$@")
PROJECT_NAME="antigravity-linux"
DOWNLOAD_PAGE="https://antigravity.google/download"
CLI_INSTALLER="https://antigravity.google/cli/install.sh"
INSTALL_DESKTOP=1
INSTALL_IDE=0
INSTALL_CLI=0
INSTALL_NAUTILUS=1
INSTALL_DEPS=1
DO_UNINSTALL=0
DO_STATUS=0
DO_PRINT_DOWNLOADS=0
FORCE=0
YES=0
INSTALLER_URL="${ANTIGRAVITY_LINUX_INSTALLER_URL:-}"

log() { printf '%s\n' "$*"; }
warn() { printf 'WARN: %s\n' "$*" >&2; }
err() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || err "Required command not found: $1"; }

usage() {
  cat <<'USAGE'
Antigravity Linux Installer

Usage:
  install.sh [install|update] [options]
  install.sh --status
  install.sh --print-downloads
  install.sh --uninstall

Default:
  Installs or updates Antigravity 2.0 desktop app system-wide.

Options:
  --desktop              Install/update Antigravity 2.0 desktop app only (default)
  --ide                  Install/update Antigravity IDE only
  --all                  Install/update Antigravity 2.0 desktop app + Antigravity IDE
  --cli                  Also run Google's official Antigravity CLI installer
  --no-nautilus          Skip GNOME Files/Nautilus context-menu helper
  --no-apt               Do not install apt dependencies automatically
  --force                Reinstall even when the recorded version matches
  --install-url URL      Store URL used by the antigravity-linux update command
  --status               Show installed helper-managed apps and versions
  --print-downloads      Print the resolved official Google tarball URLs
  --uninstall            Remove helper-managed Antigravity desktop/IDE files
  -y, --yes              Non-interactive; assume yes where possible
  -h, --help             Show this help

Recommended GitHub Pages one-liner:
  INSTALLER_URL="https://YOUR_GITHUB_USERNAME.github.io/antigravity-linux/install.sh"; \
  curl -fsSL "$INSTALLER_URL" | sudo -E env ANTIGRAVITY_LINUX_INSTALLER_URL="$INSTALLER_URL" bash -s -- --all

Update after install:
  sudo antigravity-linux update --all
USAGE
}

while [ $# -gt 0 ]; do
  case "$1" in
    install|update) ;;
    --desktop) INSTALL_DESKTOP=1; INSTALL_IDE=0 ;;
    --ide) INSTALL_DESKTOP=0; INSTALL_IDE=1 ;;
    --all) INSTALL_DESKTOP=1; INSTALL_IDE=1 ;;
    --cli) INSTALL_CLI=1 ;;
    --no-nautilus) INSTALL_NAUTILUS=0 ;;
    --no-apt) INSTALL_DEPS=0 ;;
    --force) FORCE=1 ;;
    --install-url)
      shift
      [ $# -gt 0 ] || err "--install-url needs a URL"
      INSTALLER_URL="$1"
      ;;
    --status) DO_STATUS=1 ;;
    --print-downloads) DO_PRINT_DOWNLOADS=1 ;;
    --uninstall) DO_UNINSTALL=1 ;;
    -y|--yes) YES=1 ;;
    -h|--help) usage; exit 0 ;;
    *) err "Unknown option: $1" ;;
  esac
  shift
done

if [ "$(uname -s)" != "Linux" ]; then
  err "This installer is for Linux only."
fi

case "$(uname -m)" in
  x86_64|amd64) AG_PLATFORM="linux-x64"; DESKTOP_TOP="Antigravity-x64" ;;
  aarch64|arm64) AG_PLATFORM="linux-arm"; DESKTOP_TOP="Antigravity-arm64" ;;
  *) err "Unsupported CPU architecture: $(uname -m). Google currently provides x64 and ARM64 Linux builds." ;;
esac

require_root_or_reexec() {
  if [ "$(id -u)" -eq 0 ]; then
    return 0
  fi
  if command -v sudo >/dev/null 2>&1 && [ -n "${BASH_SOURCE[0]:-}" ] && [ -r "${BASH_SOURCE[0]}" ] && [ "${BASH_SOURCE[0]}" != "bash" ] && [ "${BASH_SOURCE[0]}" != "sh" ]; then
    exec sudo -E env "ANTIGRAVITY_LINUX_INSTALLER_URL=$INSTALLER_URL" bash "${BASH_SOURCE[0]}" "${ORIGINAL_ARGS[@]}"
  fi
  err "System-wide install needs root. Use: curl -fsSL <installer-url> | sudo -E env ANTIGRAVITY_LINUX_INSTALLER_URL=<installer-url> bash"
}

install_deps_debian() {
  [ "$INSTALL_DEPS" -eq 1 ] || return 0
  if command -v apt-get >/dev/null 2>&1; then
    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    local packages=(ca-certificates curl tar python3 desktop-file-utils xdg-utils)
    if [ "$INSTALL_NAUTILUS" -eq 1 ] && [ "$INSTALL_IDE" -eq 1 ]; then
      packages+=(python3-nautilus)
    fi
    apt-get install -y "${packages[@]}"
  else
    for c in curl tar python3; do need "$c"; done
  fi
}

resolve_main_bundle() {
  local tmpdir="$1"
  local html="$tmpdir/download.html"
  local js="$tmpdir/download.js"
  curl -fsSL --compressed --retry 3 -o "$html" "$DOWNLOAD_PAGE"
  local main_js_url
  main_js_url=$(python3 - "$html" "$DOWNLOAD_PAGE" <<'PY'
import re, sys
from pathlib import Path
from urllib.parse import urljoin
html = Path(sys.argv[1]).read_text(errors='replace')
page = sys.argv[2]
# Prefer the application bundle that contains the download data.
matches = re.findall(r'(?:src|href)=["\']([^"\']*main-[^"\']+\.js)["\']', html)
if not matches:
    matches = re.findall(r'(?:src|href)=["\']([^"\']+\.js)["\']', html)
if not matches:
    raise SystemExit('Could not find JavaScript bundle on the official Antigravity download page')
print(urljoin(page, matches[-1]))
PY
)
  curl -fsSL --compressed --retry 3 -o "$js" "$main_js_url"
  printf '%s\n' "$js"
}

resolve_download_from_bundle() {
  local js="$1"
  local product="$2"
  python3 - "$js" "$AG_PLATFORM" "$product" <<'PY'
import html, re, sys
from pathlib import Path
from urllib.parse import unquote
bundle = html.unescape(Path(sys.argv[1]).read_text(errors='replace'))
platform = sys.argv[2]
product = sys.argv[3]

# Normalize escaped slashes sometimes found in JS string literals.
text = bundle.replace('\\/', '/')

def fail(msg):
    raise SystemExit(msg)

def version_from_url(url):
    decoded = unquote(url)
    # Known current layouts include antigravity-hub/<version>/ and stable/<version>/.
    for pattern in (r'/antigravity-hub/([^/]+)/', r'/stable/([^/]+)/', r'/(\d+\.\d+\.\d+(?:-[^/]+)?)/'):
        m = re.search(pattern, decoded)
        if m:
            return m.group(1).split('-', 1)[0]
    return 'unknown'

if product == 'desktop':
    marker = 'id:"antigravity-2"'
    next_marker = 'id:"antigravity-cli"'
    filename_patterns = [r'Antigravity\.tar\.gz']
    label = 'Antigravity 2.0'
elif product == 'ide':
    marker = 'id:"antigravity-ide"'
    next_marker = 'id:"antigravity-sdk"'
    filename_patterns = [r'Antigravity%20IDE\.tar\.gz', r'Antigravity\+IDE\.tar\.gz', r'Antigravity IDE\.tar\.gz']
    label = 'Antigravity IDE'
else:
    fail(f'Unknown product: {product}')

sections = []
start = text.find(marker)
if start != -1:
    end = text.find(next_marker, start)
    sections.append(text[start:end if end != -1 else None])
sections.append(text)

for section in sections:
    for filename_re in filename_patterns:
        pattern = r'https?://[^"\'\s<>)]*/' + re.escape(platform) + r'/' + filename_re
        matches = re.findall(pattern, section)
        if matches:
            url = matches[-1]
            print(version_from_url(url), url)
            sys.exit(0)

fail(f'Could not find official {label} tarball for {platform} in Google download bundle')
PY
}

resolve_desktop_download() { resolve_download_from_bundle "$1" desktop; }
resolve_ide_download() { resolve_download_from_bundle "$1" ide; }

asar_extract_icon_png() {
  local asar="$1"
  local out="$2"
  python3 - "$asar" "$out" <<'PY'
import json, struct, sys
from pathlib import Path
asar = Path(sys.argv[1])
out = Path(sys.argv[2])
with asar.open('rb') as f:
    f.read(4)
    header_size = struct.unpack('<I', f.read(4))[0]
    f.read(4)
    json_size = struct.unpack('<I', f.read(4))[0]
    header = json.loads(f.read(json_size).decode())
icon = header.get('files', {}).get('icon.png')
if not icon:
    raise SystemExit('icon.png not found in app.asar')
with asar.open('rb') as f:
    f.seek(8 + header_size + int(icon['offset']))
    out.write_bytes(f.read(int(icon['size'])))
PY
}

safe_replace_dir() {
  local newdir="$1"
  local target="$2"
  rm -rf "${target}.previous"
  if [ -d "$target" ]; then
    mv "$target" "${target}.previous"
  fi
  mv "$newdir" "$target"
}

fix_chrome_sandbox() {
  local sandbox="$1"
  if [ -f "$sandbox" ]; then
    chown root:root "$sandbox"
    chmod 4755 "$sandbox"
  fi
}

refresh_desktop_caches() {
  if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database /usr/share/applications >/dev/null 2>&1 || true
  fi
  if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -q /usr/share/icons/hicolor >/dev/null 2>&1 || true
  fi
}

installed_version() {
  local file="$1"
  cat "$file" 2>/dev/null || true
}

install_desktop_app() {
  local tmpdir="$1"
  local js="$2"
  local version url
  read -r version url < <(resolve_desktop_download "$js")
  local root="/opt/antigravity"
  local target="$root/$DESKTOP_TOP/antigravity"
  local version_file="$root/.antigravity-linux-version"
  if [ "$FORCE" -eq 0 ] && [ -x "$target" ] && [ "$(installed_version "$version_file")" = "$version" ]; then
    log "Antigravity 2.0 $version is already installed."
    return
  fi

  log "Downloading Antigravity 2.0 $version for $AG_PLATFORM from Google..."
  local archive="$tmpdir/Antigravity.tar.gz"
  curl -fsSL --retry 3 -o "$archive" "$url"
  tar -tzf "$archive" > "$tmpdir/desktop-list.txt"
  local top_dir
  top_dir=$(sed -n '1{s#/.*##;p;q}' "$tmpdir/desktop-list.txt")
  [ "$top_dir" = "$DESKTOP_TOP" ] || err "Unexpected Antigravity archive layout: $top_dir"
  tar -xzf "$archive" -C "$tmpdir"
  [ -x "$tmpdir/$top_dir/antigravity" ] || err "Antigravity launcher not found inside tarball."

  local icon_staged="$tmpdir/antigravity.png"
  if [ -f "$tmpdir/$top_dir/resources/app.asar" ]; then
    asar_extract_icon_png "$tmpdir/$top_dir/resources/app.asar" "$icon_staged" || warn "Could not extract desktop icon; continuing."
  fi

  rm -rf "${root}.new"
  mkdir -p "${root}.new"
  cp -a "$tmpdir/$top_dir" "${root}.new/"
  printf '%s\n' "$version" > "${root}.new/.antigravity-linux-version"
  printf '%s\n' "$url" > "${root}.new/.antigravity-linux-source-url"
  fix_chrome_sandbox "${root}.new/$top_dir/chrome-sandbox"
  safe_replace_dir "${root}.new" "$root"

  ln -sfn "$root/$top_dir/antigravity" /usr/local/bin/antigravity
  mkdir -p /usr/share/icons/hicolor/512x512/apps /usr/share/applications
  if [ -f "$icon_staged" ]; then
    install -m 0644 "$icon_staged" /usr/share/icons/hicolor/512x512/apps/antigravity.png
  fi
  cat > /usr/share/applications/antigravity.desktop <<DESKTOP
[Desktop Entry]
Name=Antigravity
Comment=Google Antigravity 2.0 agent platform
Exec=/usr/local/bin/antigravity %U
Icon=antigravity
Terminal=false
Type=Application
Categories=Development;IDE;
StartupNotify=true
StartupWMClass=Antigravity
DESKTOP
  refresh_desktop_caches
  log "Installed Antigravity 2.0 $version at $root/$top_dir"
}

install_ide_app() {
  local tmpdir="$1"
  local js="$2"
  local version url
  read -r version url < <(resolve_ide_download "$js")
  local root="/opt/antigravity-ide"
  local install_dir="Antigravity-IDE"
  local version_file="$root/.antigravity-linux-version"
  if [ "$FORCE" -eq 0 ] && [ -x "$root/$install_dir/antigravity-ide" ] && [ "$(installed_version "$version_file")" = "$version" ]; then
    log "Antigravity IDE $version is already installed."
    return
  fi

  log "Downloading Antigravity IDE $version for $AG_PLATFORM from Google..."
  local archive="$tmpdir/Antigravity-IDE.tar.gz"
  curl -fsSL --retry 3 -o "$archive" "$url"
  tar -tzf "$archive" > "$tmpdir/ide-list.txt"
  local top_dir
  top_dir=$(sed -n '1{s#/.*##;p;q}' "$tmpdir/ide-list.txt")
  [ "$top_dir" = "Antigravity IDE" ] || err "Unexpected Antigravity IDE archive layout: $top_dir"
  tar -xzf "$archive" -C "$tmpdir"
  [ -x "$tmpdir/$top_dir/antigravity-ide" ] || err "Antigravity IDE launcher not found inside tarball."

  rm -rf "${root}.new"
  mkdir -p "${root}.new/$install_dir"
  cp -a "$tmpdir/$top_dir/." "${root}.new/$install_dir/"
  printf '%s\n' "$version" > "${root}.new/.antigravity-linux-version"
  printf '%s\n' "$url" > "${root}.new/.antigravity-linux-source-url"
  fix_chrome_sandbox "${root}.new/$install_dir/chrome-sandbox"
  safe_replace_dir "${root}.new" "$root"

  ln -sfn "$root/$install_dir/antigravity-ide" /usr/local/bin/antigravity-ide
  mkdir -p /usr/share/icons/hicolor/512x512/apps /usr/share/applications
  local icon_source="$root/$install_dir/resources/app/resources/linux/code.png"
  if [ -f "$icon_source" ]; then
    install -m 0644 "$icon_source" /usr/share/icons/hicolor/512x512/apps/antigravity-ide.png
  fi
  cat > /usr/share/applications/antigravity-ide.desktop <<DESKTOP
[Desktop Entry]
Name=Antigravity IDE
Comment=Google Antigravity IDE
Exec=/usr/local/bin/antigravity-ide %F
Icon=antigravity-ide
Terminal=false
Type=Application
Categories=Development;IDE;
MimeType=inode/directory;text/plain;application/x-code-workspace;application/x-antigravity-workspace;x-scheme-handler/antigravity-ide;
StartupNotify=true
StartupWMClass=antigravity-ide
DESKTOP
  refresh_desktop_caches
  log "Installed Antigravity IDE $version at $root/$install_dir"
}

install_nautilus_extension() {
  [ "$INSTALL_NAUTILUS" -eq 1 ] || return 0
  [ "$INSTALL_IDE" -eq 1 ] || return 0
  if ! command -v nautilus >/dev/null 2>&1; then
    return 0
  fi
  if ! python3 - <<'PY' >/dev/null 2>&1
try:
    import gi
    gi.require_version('Nautilus', '4.0')
except Exception:
    raise SystemExit(1)
PY
  then
    warn "Skipping Nautilus extension because Python Nautilus bindings are unavailable."
    return 0
  fi
  mkdir -p /usr/share/nautilus-python/extensions
  cat > /usr/share/nautilus-python/extensions/open-in-antigravity-ide.py <<'PY'
import subprocess
from urllib.parse import unquote, urlparse
from gi.repository import Nautilus, GObject

class OpenInAntigravityIDE(GObject.GObject, Nautilus.MenuProvider):
    def _path(self, file_info):
        uri = file_info.get_uri()
        parsed = urlparse(uri)
        if parsed.scheme != 'file':
            return None
        return unquote(parsed.path)

    def get_file_items(self, files):
        if not files or len(files) != 1:
            return []
        path = self._path(files[0])
        if not path:
            return []
        item = Nautilus.MenuItem(
            name='OpenInAntigravityIDE::open',
            label='Open in Antigravity IDE',
            tip='Open this folder or file in Antigravity IDE'
        )
        item.connect('activate', lambda _item: subprocess.Popen(['antigravity-ide', path]))
        return [item]

    def get_background_items(self, folder):
        path = self._path(folder)
        if not path:
            return []
        item = Nautilus.MenuItem(
            name='OpenInAntigravityIDE::open_background',
            label='Open Folder in Antigravity IDE',
            tip='Open the current folder in Antigravity IDE'
        )
        item.connect('activate', lambda _item: subprocess.Popen(['antigravity-ide', path]))
        return [item]
PY
  log "Installed Nautilus context-menu helper. Restart Files/Nautilus to see it."
}

install_manager_command() {
  local installer_url="$INSTALLER_URL"
  cat > /usr/local/bin/antigravity-linux <<SH
#!/usr/bin/env bash
set -euo pipefail
SCRIPT_URL="$installer_url"
if [ -z "\$SCRIPT_URL" ]; then
  echo "No installer URL was stored." >&2
  echo "Reinstall with ANTIGRAVITY_LINUX_INSTALLER_URL set, or run install.sh locally." >&2
  exit 1
fi
if [ "\$(id -u)" -eq 0 ]; then
  curl -fsSL "\$SCRIPT_URL" | env ANTIGRAVITY_LINUX_INSTALLER_URL="\$SCRIPT_URL" bash -s -- "\$@"
else
  curl -fsSL "\$SCRIPT_URL" | sudo -E env ANTIGRAVITY_LINUX_INSTALLER_URL="\$SCRIPT_URL" bash -s -- "\$@"
fi
SH
  chmod +x /usr/local/bin/antigravity-linux
  cat > /usr/local/bin/update-antigravity <<'SH'
#!/usr/bin/env bash
exec antigravity-linux update --desktop "$@"
SH
  chmod +x /usr/local/bin/update-antigravity
  cat > /usr/local/bin/update-antigravity-ide <<'SH'
#!/usr/bin/env bash
exec antigravity-linux update --ide "$@"
SH
  chmod +x /usr/local/bin/update-antigravity-ide
}

print_status() {
  log "Antigravity Linux status"
  if [ -x /usr/local/bin/antigravity ]; then
    log "- Antigravity 2.0: installed ($(installed_version /opt/antigravity/.antigravity-linux-version))"
    log "  Command: /usr/local/bin/antigravity"
  else
    log "- Antigravity 2.0: not installed by this helper"
  fi
  if [ -x /usr/local/bin/antigravity-ide ]; then
    log "- Antigravity IDE: installed ($(installed_version /opt/antigravity-ide/.antigravity-linux-version))"
    log "  Command: /usr/local/bin/antigravity-ide"
  else
    log "- Antigravity IDE: not installed by this helper"
  fi
  if [ -x /usr/local/bin/antigravity-linux ]; then
    log "- Update helper: installed"
  else
    log "- Update helper: not installed"
  fi
}

print_downloads() {
  need curl
  need python3
  local tmp_parent="${TMPDIR:-/tmp}"
  local tmpdir
  tmpdir=$(mktemp -d "$tmp_parent/$PROJECT_NAME.XXXXXX")
  local js
  js=$(resolve_main_bundle "$tmpdir")
  if [ "$INSTALL_DESKTOP" -eq 1 ]; then
    local version url
    read -r version url < <(resolve_desktop_download "$js")
    log "Antigravity 2.0 $version: $url"
  fi
  if [ "$INSTALL_IDE" -eq 1 ]; then
    local version url
    read -r version url < <(resolve_ide_download "$js")
    log "Antigravity IDE $version: $url"
  fi
  rm -rf "$tmpdir"
}

uninstall_all() {
  require_root_or_reexec
  rm -rf /opt/antigravity /opt/antigravity.new /opt/antigravity.previous /opt/antigravity-ide /opt/antigravity-ide.new /opt/antigravity-ide.previous
  rm -f /usr/local/bin/antigravity /usr/local/bin/antigravity-ide /usr/local/bin/update-antigravity /usr/local/bin/update-antigravity-ide /usr/local/bin/antigravity-linux
  rm -f /usr/share/applications/antigravity.desktop /usr/share/applications/antigravity-ide.desktop
  rm -f /usr/share/icons/hicolor/512x512/apps/antigravity.png /usr/share/icons/hicolor/512x512/apps/antigravity-ide.png
  rm -f /usr/share/nautilus-python/extensions/open-in-antigravity-ide.py
  refresh_desktop_caches
  log "Removed helper-managed Antigravity files. User settings under home directories were left untouched."
}

main() {
  if [ "$DO_STATUS" -eq 1 ]; then
    print_status
    exit 0
  fi
  if [ "$DO_PRINT_DOWNLOADS" -eq 1 ]; then
    print_downloads
    exit 0
  fi
  if [ "$DO_UNINSTALL" -eq 1 ]; then
    uninstall_all
    exit 0
  fi

  require_root_or_reexec
  install_deps_debian
  local tmp_parent="${TMPDIR:-/var/tmp}"
  mkdir -p "$tmp_parent"
  local tmpdir
  tmpdir=$(mktemp -d "$tmp_parent/$PROJECT_NAME.XXXXXX")
  trap 'rm -rf "$tmpdir"' EXIT
  local js
  js=$(resolve_main_bundle "$tmpdir")
  [ "$INSTALL_DESKTOP" -eq 1 ] && install_desktop_app "$tmpdir" "$js"
  [ "$INSTALL_IDE" -eq 1 ] && install_ide_app "$tmpdir" "$js"
  install_nautilus_extension
  if [ "$INSTALL_CLI" -eq 1 ]; then
    log "Running Google's official Antigravity CLI installer for the non-root user..."
    if [ -n "${SUDO_USER:-}" ] && [ "${SUDO_USER:-}" != "root" ]; then
      sudo -u "$SUDO_USER" -H bash -lc "curl -fsSL '$CLI_INSTALLER' | bash"
    else
      curl -fsSL "$CLI_INSTALLER" | bash
    fi
  fi
  install_manager_command
  log "Done. Launch from the app menu or run: antigravity"
  if [ "$INSTALL_IDE" -eq 1 ]; then
    log "IDE command: antigravity-ide"
    log "Folder open integration: use your file manager's Open With menu, or Nautilus context menu after restarting Files."
  fi
  if [ -n "$INSTALLER_URL" ]; then
    log "Update helper installed: sudo antigravity-linux update --all"
  else
    log "Update helper installed without a stored URL. Re-run this local script for updates or reinstall from a published URL."
  fi
}

main "$@"
