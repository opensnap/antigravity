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
CLEANUP_TMPDIR=""

cleanup() {
  if [ -n "${CLEANUP_TMPDIR:-}" ] && [ -d "${CLEANUP_TMPDIR:-}" ]; then
    rm -rf "${CLEANUP_TMPDIR}"
  fi
}
trap cleanup EXIT

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
    local packages=(ca-certificates curl tar python3 desktop-file-utils xdg-utils)
    if [ "$INSTALL_NAUTILUS" -eq 1 ] && [ "$INSTALL_IDE" -eq 1 ]; then
      packages+=(python3-nautilus)
    fi
    local missing=()
    for pkg in "${packages[@]}"; do
      if ! (command -v dpkg >/dev/null 2>&1 && dpkg -s "$pkg" >/dev/null 2>&1); then
        missing+=("$pkg")
      fi
    done
    if [ ${#missing[@]} -gt 0 ]; then
      export DEBIAN_FRONTEND=noninteractive
      log "Installing missing dependencies via apt: ${missing[*]}..."
      apt-get update
      apt-get install -y "${missing[@]}"
    fi
  else
    for c in curl tar python3; do need "$c"; done
  fi
}

resolve_download() {
  local product="$1"
  local target="${2:-}"
  local html_path=""
  if [ -n "$target" ]; then
    if [ -d "$target" ]; then
      html_path="$target/download.html"
      if [ ! -f "$html_path" ]; then
        curl -fsSL --compressed --retry 3 -o "$html_path" "$DOWNLOAD_PAGE" 2>/dev/null || true
      fi
    elif [ -f "$target" ]; then
      html_path="$target"
    fi
  fi

  python3 - "$AG_PLATFORM" "$product" "$html_path" "$DOWNLOAD_PAGE" <<'PY'
import html, json, re, sys, urllib.request
from pathlib import Path
from urllib.parse import unquote, urljoin

platform = sys.argv[1]
product = sys.argv[2]
html_path = sys.argv[3] if len(sys.argv) > 3 else ""
download_page = sys.argv[4] if len(sys.argv) > 4 else "https://antigravity.google/download"

if product == 'desktop':
    label = 'Antigravity 2.0'
elif product == 'ide':
    label = 'Antigravity IDE'
else:
    sys.stderr.write(f"Unknown product: {product}\n")
    sys.exit(1)

def version_from_url(url):
    decoded = unquote(url)
    for pattern in (r'/antigravity-hub/([^/]+)/', r'/stable/([^/]+)/', r'/(\d+\.\d+\.\d+(?:-[^/]+)?)/'):
        m = re.search(pattern, decoded)
        if m:
            return m.group(1).split('-', 1)[0]
    return 'unknown'

# Tier 1: Query Google's official auto-updater releases API
api_url = (
    'https://antigravity-hub-auto-updater-974169037036.us-central1.run.app/releases'
    if product == 'desktop'
    else 'https://antigravity-ide-auto-updater-974169037036.us-central1.run.app/releases'
)
try:
    req = urllib.request.Request(api_url, headers={'User-Agent': 'Mozilla/5.0'})
    with urllib.request.urlopen(req, timeout=8) as resp:
        data = json.loads(resp.read().decode('utf-8'))
    releases = data if isinstance(data, list) else data.get('versions', []) if isinstance(data, dict) else []
    if releases and isinstance(releases[0], dict):
        latest = releases[0]
        ver = str(latest.get('version', '')).strip()
        exec_id = str(latest.get('execution_id', '')).strip()
        if ver and exec_id:
            if product == 'desktop':
                url = f"https://storage.googleapis.com/antigravity-public/antigravity-hub/{ver}-{exec_id}/{platform}/Antigravity.tar.gz"
            else:
                url = f"https://edgedl.me.gvt1.com/edgedl/release2/j0qc3/antigravity/stable/{ver}-{exec_id}/{platform}/Antigravity%20IDE.tar.gz"
            print(f"{ver} {url}")
            sys.exit(0)
except Exception:
    pass

# Tier 2: Check HTML content from download.html or fetch download page
html_content = ""
if html_path and Path(html_path).is_file():
    html_content = Path(html_path).read_text(errors='replace')
if not html_content:
    try:
        req = urllib.request.Request(download_page, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req, timeout=10) as resp:
            html_content = resp.read().decode('utf-8', errors='replace')
    except Exception:
        pass

def search_text(text):
    text_clean = html.unescape(text).replace(r'\/', '/')
    if product == 'desktop':
        filename_patterns = [r'Antigravity\.tar\.gz']
        markers = [('data-module-name="download_hub"', None), ('id:"antigravity-2"', 'id:"antigravity-cli"'), ('antigravity-hub', None)]
    else:
        filename_patterns = [r'Antigravity%20IDE\.tar\.gz', r'Antigravity\+IDE\.tar\.gz', r'Antigravity IDE\.tar\.gz']
        markers = [('data-module-name="download_ide"', None), ('id:"antigravity-ide"', 'id:"antigravity-sdk"'), ('antigravity/stable', None)]

    sections = []
    for start_m, end_m in markers:
        start = text_clean.find(start_m)
        if start != -1:
            end = text_clean.find(end_m, start) if end_m else -1
            sections.append(text_clean[start:end if end != -1 else None])
    sections.append(text_clean)

    for section in sections:
        for fp in filename_patterns:
            pattern = r'https?://[^"\'\s<>)]*/' + re.escape(platform) + r'/' + fp
            matches = re.findall(pattern, section)
            if matches:
                url = matches[-1]
                return version_from_url(url), url
    return None

if html_content:
    res = search_text(html_content)
    if res:
        print(f"{res[0]} {res[1]}")
        sys.exit(0)

    # Tier 3: Search referenced JavaScript bundles on the download page
    js_matches = re.findall(r'(?:src|href)=["\']([^"\']+\.js)["\']', html_content)
    for js_src in js_matches:
        js_url = urljoin(download_page, js_src)
        try:
            req = urllib.request.Request(js_url, headers={'User-Agent': 'Mozilla/5.0'})
            with urllib.request.urlopen(req, timeout=8) as resp:
                js_text = resp.read().decode('utf-8', errors='replace')
            res = search_text(js_text)
            if res:
                print(f"{res[0]} {res[1]}")
                sys.exit(0)
        except Exception:
            continue

sys.stderr.write(f"Could not find official {label} tarball for {platform} in Google download bundle\n")
sys.exit(1)
PY
}

resolve_desktop_download() { resolve_download desktop "${1:-}"; }
resolve_ide_download() { resolve_download ide "${1:-}"; }
resolve_download_from_bundle() { resolve_download "${2:-desktop}" "${1:-}"; }
resolve_main_bundle() {
  local tmpdir="$1"
  local html="$tmpdir/download.html"
  if [ ! -f "$html" ]; then
    curl -fsSL --compressed --retry 3 -o "$html" "$DOWNLOAD_PAGE" 2>/dev/null || true
  fi
  printf '%s\n' "$html"
}

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
  local bundle_or_dir="${2:-$tmpdir}"
  local version url
  read -r version url < <(resolve_desktop_download "$bundle_or_dir")
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
  local bundle_or_dir="${2:-$tmpdir}"
  local version url
  read -r version url < <(resolve_ide_download "$bundle_or_dir")
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
  CLEANUP_TMPDIR=$(mktemp -d "$tmp_parent/$PROJECT_NAME.XXXXXX")
  local tmpdir="$CLEANUP_TMPDIR"
  if [ "$INSTALL_DESKTOP" -eq 1 ]; then
    local version url
    read -r version url < <(resolve_desktop_download "$tmpdir")
    log "Antigravity 2.0 $version: $url"
  fi
  if [ "$INSTALL_IDE" -eq 1 ]; then
    local version url
    read -r version url < <(resolve_ide_download "$tmpdir")
    log "Antigravity IDE $version: $url"
  fi
}

print_success_summary() {
  log ""
  log "Antigravity Linux install complete."
  log ""
  log "Installed:"
  if [ "$INSTALL_DESKTOP" -eq 1 ]; then
    log "- Antigravity 2.0: /usr/local/bin/antigravity"
  fi
  if [ "$INSTALL_IDE" -eq 1 ]; then
    log "- Antigravity IDE: /usr/local/bin/antigravity-ide"
  fi
  log ""
  log "Manage:"
  log "- Status:    antigravity-linux --status"
  log "- Update:    sudo antigravity-linux update --all"
  log "- Uninstall: sudo antigravity-linux --uninstall"
  if [ -z "$INSTALLER_URL" ]; then
    log ""
    log "Note: antigravity-linux was installed without a stored URL. Re-run this local script for updates or reinstall from a published URL."
  fi
  if [ "$INSTALL_IDE" -eq 1 ]; then
    log ""
    log "Folder open integration: use your file manager's Open With menu, or Nautilus context menu after restarting Files."
  fi
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
  CLEANUP_TMPDIR=$(mktemp -d "$tmp_parent/$PROJECT_NAME.XXXXXX")
  local tmpdir="$CLEANUP_TMPDIR"
  [ "$INSTALL_DESKTOP" -eq 1 ] && install_desktop_app "$tmpdir"
  [ "$INSTALL_IDE" -eq 1 ] && install_ide_app "$tmpdir"
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
  print_success_summary
}

main "$@"
