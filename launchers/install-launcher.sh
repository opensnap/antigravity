#!/usr/bin/env bash
# antigravity-cli-install-launcher.sh
# Install desktop launcher untuk Antigravity CLI
# Mendukung: GNOME, KDE, XFCE, Cinnamon, MATE, Budgie, LXQt, Sway/i3 (via rofi/wofi)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_NAME="antigravity-cli"
INSTALL_DIR="${HOME}/.local/share"
DESKTOP_DIR="${INSTALL_DIR}/applications"
ICON_DIR="${INSTALL_DIR}/icons/hicolor/512x512/apps"

log() { printf '%s\n' "$*"; }
warn() { printf 'WARN: %s\n' "$*" >&2; }
err() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

detect_terminal() {
  local terminals=("alacritty" "kitty" "gnome-terminal" "konsole" "xfce4-terminal" "xterm")
  for t in "${terminals[@]}"; do
    if command -v "$t" >/dev/null 2>&1; then
      echo "$t"
      return
    fi
  done
  echo "xterm"
}

generate_desktop_entry() {
  local terminal="$1"
  local desktop_file="$2"
  local exec_line

  case "$terminal" in
    alacritty)
      exec_line="alacritty -e agy"
      ;;
    kitty)
      exec_line="kitty agy"
      ;;
    gnome-terminal)
      exec_line="gnome-terminal -- agy"
      ;;
    konsole)
      exec_line="konsole -e agy"
      ;;
    xfce4-terminal)
      exec_line="xfce4-terminal -e agy"
      ;;
    xterm)
      exec_line="xterm -e agy"
      ;;
    *)
      exec_line="xterm -e agy"
      ;;
  esac

  cat > "$desktop_file" <<DESKTOP
[Desktop Entry]
Type=Application
Name=Antigravity CLI
GenericName=AI Agent CLI
Comment=Google Antigravity AI agent command-line interface
Exec=${exec_line}
Icon=${APP_NAME}
Terminal=false
Categories=Development;IDE;Utility;
MimeType=text/plain;
Keywords=ai;agent;cli;google;antigravity;
StartupNotify=true
Actions=NewWindow;

[Desktop Action NewWindow]
Name=New Window
Exec=${exec_line}
DESKTOP

  log "Generated desktop entry for: $terminal"
  log "  File: $desktop_file"
  log "  Exec: $exec_line"
}

generate_icon() {
  local icon_file="$1"
  if [ -f "${SCRIPT_DIR}/icons/antigravity-cli.png" ]; then
    cp "${SCRIPT_DIR}/icons/antigravity-cli.png" "$icon_file"
    log "Copied icon to: $icon_file"
  else
    warn "No icon file found at ${SCRIPT_DIR}/icons/antigravity-cli.png"
    warn "You can download one from: https://antigravity.google/favicon.svg"
    warn "Or use any 512x512 PNG as placeholder"
    # Create a minimal placeholder
    if command -v convert >/dev/null 2>&1; then
      convert -size 512x512 xc:"#4285F4" -fill white -gravity center -pointsize 120 -annotate 0 "Ag" "$icon_file"
      log "Generated placeholder icon"
    fi
  fi
}

install_launcher() {
  local terminal
  terminal=$(detect_terminal)
  log "Detected terminal: $terminal"

  mkdir -p "$DESKTOP_DIR" "$ICON_DIR"

  local desktop_file="${DESKTOP_DIR}/${APP_NAME}.desktop"
  generate_desktop_entry "$terminal" "$desktop_file"
  generate_icon "${ICON_DIR}/${APP_NAME}.png"

  chmod +x "$desktop_file"

  # Update desktop database
  if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true
    log "Updated desktop database"
  fi

  # Update icon cache
  if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -q "${INSTALL_DIR}/icons/hicolor" 2>/dev/null || true
    log "Updated icon cache"
  fi

  log ""
  log "Installation complete!"
  log "  Desktop entry: $desktop_file"
  log "  Icon: ${ICON_DIR}/${APP_NAME}.png"
  log ""
  log "You can now find 'Antigravity CLI' in your application menu."
  log "Or run directly: agy"
}

uninstall_launcher() {
  log "Removing Antigravity CLI launcher..."
  rm -f "${DESKTOP_DIR}/${APP_NAME}.desktop"
  rm -f "${ICON_DIR}/${APP_NAME}.png"

  if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true
  fi
  if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -q "${INSTALL_DIR}/icons/hicolor" 2>/dev/null || true
  fi

  log "Uninstalled Antigravity CLI launcher"
}

usage() {
  cat <<'USAGE'
Antigravity CLI Launcher Installer

Usage:
  install-launcher.sh [options]

Options:
  --install       Install desktop launcher (default)
  --uninstall     Remove desktop launcher
  --status        Show launcher status
  -h, --help      Show this help

Examples:
  bash install-launcher.sh --install
  bash install-launcher.sh --uninstall
USAGE
}

DO_INSTALL=1
DO_UNINSTALL=0
DO_STATUS=0

while [ $# -gt 0 ]; do
  case "$1" in
    --install) DO_INSTALL=1; DO_UNINSTALL=0; DO_STATUS=0 ;;
    --uninstall) DO_INSTALL=0; DO_UNINSTALL=1; DO_STATUS=0 ;;
    --status) DO_INSTALL=0; DO_UNINSTALL=0; DO_STATUS=1 ;;
    -h|--help) usage; exit 0 ;;
    *) err "Unknown option: $1" ;;
  esac
  shift
done

if [ "$DO_STATUS" -eq 1 ]; then
  if [ -f "${DESKTOP_DIR}/${APP_NAME}.desktop" ]; then
    log "Launcher installed: ${DESKTOP_DIR}/${APP_NAME}.desktop"
    log "Icon installed: ${ICON_DIR}/${APP_NAME}.png"
  else
    log "Launcher not installed"
  fi
  exit 0
fi

if [ "$DO_UNINSTALL" -eq 1 ]; then
  uninstall_launcher
  exit 0
fi

install_launcher
