#!/usr/bin/env bash
# build-deb.sh — Build .deb package for Antigravity (Desktop + IDE + CLI)
# Resolves URLs dynamically from Google's download page and CLI manifest.
# Supports: amd64, arm64
# Usage: bash build-deb.sh [--fast]
#   --fast  Skip Electron locales/debug to reduce build time on slow mounts
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKG_NAME="antigravity"
DOWNLOAD_PAGE="https://antigravity.google/download"
CLI_MANIFEST_BASE="https://antigravity-cli-auto-updater-974169037036.us-central1.run.app/manifests"
FAST_MODE=false
[[ "${1:-}" == "--fast" ]] && FAST_MODE=true

# Build in /tmp to avoid SSHFS timeouts; fall back to SCRIPT_DIR/build if /tmp is too small
BUILD_ROOT="/tmp/antigravity-build-$$"
if [ -d /tmp ] && [ -w /tmp ]; then
  local_free=$(df -BM /tmp 2>/dev/null | awk 'NR==2{print $4}' | tr -d 'M')
  if [ "${local_free:-0}" -lt 4000 ]; then
    warn "/tmp has only ${local_free:-?}MB free, using ${SCRIPT_DIR}/build"
    BUILD_ROOT="${SCRIPT_DIR}/build"
  fi
else
  BUILD_ROOT="${SCRIPT_DIR}/build"
fi

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
log()  { printf "${GREEN}[build]${NC} %s\n" "$*"; }
warn() { printf "${YELLOW}[warn]${NC} %s\n" "$*"; }
err()  { printf "${RED}[error]${NC} %s\n" "$*" >&2; exit 1; }

detect_arch() {
  case "$(uname -m)" in
    x86_64)  echo "amd64" ;;
    aarch64) echo "arm64" ;;
    *)       err "Unsupported architecture: $(uname -m)" ;;
  esac
}

arch_to_google_platform() {
  case "$1" in
    amd64) echo "linux-x64" ;;
    arm64) echo "linux-arm" ;;
  esac
}

arch_to_cli_platform() {
  case "$1" in
    amd64) echo "linux_amd64" ;;
    arm64) echo "linux_arm64" ;;
  esac
}

# --- Resolve download URLs from Google ---
resolve_desktop_url() {
  local platform="$1"
  log "Resolving Desktop URL from ${DOWNLOAD_PAGE}..." >&2
  local html
  html=$(curl -fsSL --compressed --retry 3 "$DOWNLOAD_PAGE")
  local url
  url=$(echo "$html" | python3 -c "
import re, sys
html = sys.stdin.read()
matches = re.findall(r'https?://[^\"\s<>)]+/${platform}/Antigravity\.tar\.gz', html)
if matches:
    print(matches[-1])
else:
    sys.exit(1)
" 2>/dev/null) || err "Could not resolve Desktop URL for ${platform}"
  echo "$url"
}

resolve_ide_url() {
  local platform="$1"
  log "Resolving IDE URL from ${DOWNLOAD_PAGE}..." >&2
  local html
  html=$(curl -fsSL --compressed --retry 3 "$DOWNLOAD_PAGE")
  local url
  url=$(echo "$html" | python3 -c "
import re, sys
html = sys.stdin.read()
matches = re.findall(r'https?://[^\"\s<>)]+/${platform}/Antigravity%20IDE\.tar\.gz', html)
if matches:
    print(matches[-1])
else:
    sys.exit(1)
" 2>/dev/null) || err "Could not resolve IDE URL for ${platform}"
  echo "$url"
}

resolve_cli_url() {
  local arch="$1"
  log "Resolving CLI URL from manifest..." >&2
  local manifest_url="${CLI_MANIFEST_BASE}/${arch}.json"
  local json
  json=$(curl -fsSL --retry 3 "$manifest_url")
  local url
  url=$(echo "$json" | python3 -c "import json,sys; print(json.load(sys.stdin)['url'])" 2>/dev/null) \
    || err "Could not resolve CLI URL from manifest"
  local version
  version=$(echo "$json" | python3 -c "import json,sys; print(json.load(sys.stdin)['version'])" 2>/dev/null)
  log "  CLI version: ${version}" >&2
  echo "$url"
}

download() {
  local url="$1" output="$2"
  curl -fsSL --retry 3 --retry-delay 5 -o "$output" "$url" || err "Failed to download: $url"
}

main() {
  local arch
  arch=$(detect_arch)
  local google_platform cli_platform
  google_platform=$(arch_to_google_platform "$arch")
  cli_platform=$(arch_to_cli_platform "$arch")

  log "Building ${PKG_NAME} for ${arch}..."

  command -v dpkg-deb >/dev/null 2>&1 || err "dpkg-deb not found. Install: sudo apt install dpkg-dev"
  command -v curl >/dev/null 2>&1 || err "curl not found."
  command -v python3 >/dev/null 2>&1 || err "python3 not found."
  command -v tar >/dev/null 2>&1 || err "tar not found."

  rm -rf "${BUILD_ROOT}" "${SCRIPT_DIR}/build"
  mkdir -p "${SCRIPT_DIR}/build"
  local work_dir="${BUILD_ROOT}/work"
  local pkg_dir="${BUILD_ROOT}/${PKG_NAME}"
  mkdir -p "$work_dir" "${pkg_dir}/DEBIAN"

  # --- Resolve URLs ---
  local desktop_url ide_url cli_url
  desktop_url=$(resolve_desktop_url "$google_platform")
  ide_url=$(resolve_ide_url "$google_platform")
  cli_url=$(resolve_cli_url "$cli_platform")

  log "Desktop URL: ${desktop_url}"
  log "IDE URL:     ${ide_url}"
  log "CLI URL:     ${cli_url}"

  # --- Download Desktop ---
  log "Downloading Desktop..."
  download "$desktop_url" "${work_dir}/desktop.tar.gz"
  tar -xzf "${work_dir}/desktop.tar.gz" -C "$work_dir/"
  local desktop_dir
  desktop_dir=$(ls -d "${work_dir}/Antigravity-"* 2>/dev/null | head -1)
  [ -d "$desktop_dir" ] || err "Desktop dir not found after extraction"
  local desktop_ver
  desktop_ver=$(basename "$desktop_dir" | grep -oP '\d+\.\d+\.\d+' || echo "unknown")
  log "  Extracted: $(basename "$desktop_dir") (v${desktop_ver})"

  # --- Download IDE ---
  log "Downloading IDE..."
  download "$ide_url" "${work_dir}/ide.tar.gz"
  tar -xzf "${work_dir}/ide.tar.gz" -C "$work_dir/"
  [ -d "${work_dir}/Antigravity IDE" ] || err "IDE dir not found after extraction"
  log "  Extracted: Antigravity IDE"

  # --- Download CLI ---
  log "Downloading CLI..."
  download "$cli_url" "${work_dir}/cli.tar.gz"
  tar -xzf "${work_dir}/cli.tar.gz" -C "$work_dir/"
  # The CLI binary may be named 'antigravity' or 'agy' depending on version
  if [ -f "${work_dir}/antigravity" ]; then
    mv "${work_dir}/antigravity" "${work_dir}/agy"
    log "  Extracted: agy (renamed from antigravity)"
  elif [ -f "${work_dir}/agy" ]; then
    log "  Extracted: agy"
  elif [ -f "${work_dir}/antigravity/agy" ]; then
    mv "${work_dir}/antigravity/agy" "${work_dir}/agy"
    log "  Extracted: agy"
  else
    err "agy binary not found in downloaded archive"
  fi
  local cli_ver
  cli_ver=$("${work_dir}/agy" --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+' || echo "unknown")
  log "  CLI version: ${cli_ver}"

  # --- Assemble package ---
  log "Assembling package..."

  # Helper: fast copy (rsync if available, else cp)
  fast_copy() {
    if command -v rsync >/dev/null 2>&1; then
      rsync -a --info=progress2 "$@"
    else
      cp -a "$@"
    fi
  }

  # Helper: strip Electron bloat for --fast mode
  strip_electron() {
    local dir="$1"
    if $FAST_MODE; then
      # Remove locales (keep only en-US), debug symbols, crashpad
      rm -rf "${dir}/locales/"!(en-US.pak) 2>/dev/null || true
      rm -rf "${dir}/debug" "${dir}/.debug" 2>/dev/null || true
      rm -rf "${dir}/Crashpad" 2>/dev/null || true
      # Remove unused SwiftShader
      rm -rf "${dir}/swiftshader" 2>/dev/null || true
      log "  Stripped Electron bloat from $(basename "$dir")"
    fi
  }

  # Desktop 2.0
  local desktop_top
  desktop_top=$(basename "$desktop_dir")
  local desktop_ver
  desktop_ver=$(echo "$desktop_url" | grep -oP 'antigravity-hub/\K[^/]+' | cut -d- -f1)
  [ -z "$desktop_ver" ] && desktop_ver="0.0.0"
  log "  Version: ${desktop_ver}"

  mkdir -p "${pkg_dir}/opt/antigravity"
  log "  Copying Desktop 2.0..."
  fast_copy "$desktop_dir" "${pkg_dir}/opt/antigravity/"
  strip_electron "${pkg_dir}/opt/antigravity/${desktop_top}"

  # IDE
  mkdir -p "${pkg_dir}/opt/antigravity-ide"
  log "  Copying IDE..."
  fast_copy "${work_dir}/Antigravity IDE" "${pkg_dir}/opt/antigravity-ide/Antigravity-IDE"
  strip_electron "${pkg_dir}/opt/antigravity-ide/Antigravity-IDE"

  # CLI
  mkdir -p "${pkg_dir}/usr/bin"
  install -Dm755 "${work_dir}/agy" "${pkg_dir}/usr/bin/agy"

  # Symlinks
  mkdir -p "${pkg_dir}/usr/local/bin"
  ln -sf "/opt/antigravity/${desktop_top}/antigravity" "${pkg_dir}/usr/local/bin/antigravity"
  ln -sf "/opt/antigravity-ide/Antigravity-IDE/antigravity-ide" "${pkg_dir}/usr/local/bin/antigravity-ide"

  # Desktop entries
  mkdir -p "${pkg_dir}/usr/share/applications"
  cp "${SCRIPT_DIR}/usr/share/applications/antigravity.desktop" "${pkg_dir}/usr/share/applications/"
  cp "${SCRIPT_DIR}/usr/share/applications/antigravity-ide.desktop" "${pkg_dir}/usr/share/applications/"
  cp "${SCRIPT_DIR}/usr/share/applications/antigravity-cli.desktop" "${pkg_dir}/usr/share/applications/"

  # Icons
  mkdir -p "${pkg_dir}/usr/share/icons/hicolor/512x512/apps"
  local icon_ide="${pkg_dir}/opt/antigravity-ide/Antigravity-IDE/resources/app/resources/linux/code.png"
  if [ -f "$icon_ide" ]; then
    cp "$icon_ide" "${pkg_dir}/usr/share/icons/hicolor/512x512/apps/antigravity-ide.png"
  fi

  # Nautilus extension
  mkdir -p "${pkg_dir}/usr/share/nautilus-python/extensions"
  cat > "${pkg_dir}/usr/share/nautilus-python/extensions/open-in-antigravity-ide.py" << 'NAUTILUS'
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
NAUTILUS

  # Shell profile
  mkdir -p "${pkg_dir}/usr/share/doc/${PKG_NAME}"
  cat > "${pkg_dir}/usr/share/doc/${PKG_NAME}/antigravity-cli.sh" << 'PROFILE'
# Antigravity CLI — PATH setup
if [ -d /usr/bin ] && [[ ":$PATH:" != *":/usr/bin:"* ]]; then
    export PATH="/usr/bin:$PATH"
fi
PROFILE

  # Maintainer scripts
  for script in postinst prerm postrm; do
    cp "${SCRIPT_DIR}/DEBIAN/${script}" "${pkg_dir}/DEBIAN/"
    chmod 755 "${pkg_dir}/DEBIAN/${script}"
  done

  # --- DEBIAN/control ---
  cp "${SCRIPT_DIR}/DEBIAN/control" "${pkg_dir}/DEBIAN/"
  sed -i "s/^Version:.*/Version: ${desktop_ver}-1/" "${pkg_dir}/DEBIAN/control"
  sed -i "s/^Architecture:.*/Architecture: ${arch}/" "${pkg_dir}/DEBIAN/control"

  # --- Calculate installed size ---
  local installed_size
  installed_size=$(du -sk "${pkg_dir}" | cut -f1)
  sed -i "s/^Installed-Size:.*/Installed-Size: ${installed_size}/" "${pkg_dir}/DEBIAN/control"

  # --- Build .deb ---
  local deb_name="${PKG_NAME}_${desktop_ver}-1_${arch}.deb"
  log "Building ${deb_name}..."

  # If building in /tmp, copy back to SCRIPT_DIR/build for persistence
  if [ "$BUILD_ROOT" != "${SCRIPT_DIR}/build" ]; then
    log "  Building in local /tmp (fast)..."
    dpkg-deb --build "${pkg_dir}" "${BUILD_ROOT}/${deb_name}"
    cp "${BUILD_ROOT}/${deb_name}" "${SCRIPT_DIR}/build/${deb_name}"
    log "  Copied to ${SCRIPT_DIR}/build/${deb_name}"
  else
    dpkg-deb --build "${pkg_dir}" "${SCRIPT_DIR}/build/${deb_name}"
  fi

  log ""
  log "Package built successfully!"
  log "  Location: ${SCRIPT_DIR}/build/${deb_name}"
  log "  Size: $(du -h "${SCRIPT_DIR}/build/${deb_name}" | cut -f1)"
  log ""
  log "Contents:"
  log "  Desktop 2.0: ${desktop_ver}"
  log "  IDE:         (same release)"
  log "  CLI (agy):   ${cli_ver}"
  if $FAST_MODE; then
    log "  Mode:        fast (stripped locales/debug/swiftshader)"
  fi
  log ""
  log "Install:"
  log "  sudo dpkg -i ${SCRIPT_DIR}/build/${deb_name}"
  log "  sudo apt-get install -f"
}

main "$@"
