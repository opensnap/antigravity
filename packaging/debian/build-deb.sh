#!/usr/bin/env bash
# build-deb.sh - Build .deb package for antigravity-cli
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKG_NAME="antigravity-cli"
PKG_VERSION="${1:-1.1.14}"
PKG_DIR="${SCRIPT_DIR}/build/${PKG_NAME}_${PKG_VERSION}"

log() { printf '%s\n' "$*"; }
err() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

# Check dependencies
command -v dpkg-deb >/dev/null 2>&1 || err "dpkg-deb not found. Install dpkg-dev."

# Clean previous build
rm -rf "${SCRIPT_DIR}/build"
mkdir -p "${PKG_DIR}/DEBIAN"
mkdir -p "${PKG_DIR}/usr/bin"
mkdir -p "${PKG_DIR}/usr/share/applications"
mkdir -p "${PKG_DIR}/usr/share/icons/hicolor/512x512/apps"
mkdir -p "${PKG_DIR}/usr/share/doc/${PKG_NAME}"

# Copy control file
cp "${SCRIPT_DIR}/DEBIAN/control" "${PKG_DIR}/DEBIAN/"
sed -i "s/^Version:.*/Version: ${PKG_VERSION}-1/" "${PKG_DIR}/DEBIAN/control"

# Copy scripts
cp "${SCRIPT_DIR}/DEBIAN/postinst" "${PKG_DIR}/DEBIAN/"
cp "${SCRIPT_DIR}/DEBIAN/prerm" "${PKG_DIR}/DEBIAN/"
cp "${SCRIPT_DIR}/DEBIAN/postrm" "${PKG_DIR}/DEBIAN/"
chmod 755 "${PKG_DIR}/DEBIAN/postinst" "${PKG_DIR}/DEBIAN/prerm" "${PKG_DIR}/DEBIAN/postrm"

# Copy binary (from installed location or download)
if [ -f "${HOME}/.local/bin/agy" ]; then
    cp "${HOME}/.local/bin/agy" "${PKG_DIR}/usr/bin/agy"
    chmod 755 "${PKG_DIR}/usr/bin/agy"
elif [ -f "${SCRIPT_DIR}/agy" ]; then
    cp "${SCRIPT_DIR}/agy" "${PKG_DIR}/usr/bin/agy"
    chmod 755 "${PKG_DIR}/usr/bin/agy"
else
    log "Downloading agy binary..."
    curl -fsSL -o "${PKG_DIR}/usr/bin/agy" "https://dl.google.com/dl/antigravity/cli/linux_amd64/agy-${PKG_VERSION}.tar.gz"
    chmod 755 "${PKG_DIR}/usr/bin/agy"
fi

# Copy desktop files
cp "${SCRIPT_DIR}/usr/share/applications/antigravity-cli.desktop" "${PKG_DIR}/usr/share/applications/"
cp "${SCRIPT_DIR}/usr/share/applications/antigravity-cli-terminal.desktop" "${PKG_DIR}/usr/share/applications/"

# Copy shell profile
cp "${SCRIPT_DIR}/usr/share/doc/antigravity-cli/antigravity-cli.sh" "${PKG_DIR}/usr/share/doc/${PKG_NAME}/"

# Calculate installed size
INSTALLED_SIZE=$(du -sk "${PKG_DIR}" | cut -f1)
sed -i "s/^Installed-Size:.*/Installed-Size: ${INSTALLED_SIZE}/" "${PKG_DIR}/DEBIAN/control"

# Build .deb
log "Building .deb package..."
dpkg-deb --build "${PKG_DIR}" "${SCRIPT_DIR}/build/${PKG_NAME}_${PKG_VERSION}-1_amd64.deb"

log ""
log "Package built successfully!"
log "  Location: ${SCRIPT_DIR}/build/${PKG_NAME}_${PKG_VERSION}-1_amd64.deb"
log ""
log "Install with:"
log "  sudo dpkg -i ${SCRIPT_DIR}/build/${PKG_NAME}_${PKG_VERSION}-1_amd64.deb"
log "  sudo apt-get install -f  # fix dependencies if needed"
