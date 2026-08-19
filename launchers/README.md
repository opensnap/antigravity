# Antigravity — Desktop Launchers

Desktop launcher files for Antigravity CLI across various Linux/BSD desktop environments.

## Table of Contents

- [About](#about)
- [Supported Desktop Environments](#supported-desktop-environments)
- [Launcher Files](#launcher-files)
- [Manual Installation](#manual-installation)
- [Automated Installation](#automated-installation)
- [Uninstall](#uninstall)
- [Troubleshooting](#troubleshooting)

---

## About

The `.desktop` files follow the freedesktop.org Desktop Entry Specification:
https://specifications.freedesktop.org/desktop-entry-spec/latest/

These files enable Antigravity CLI to appear in:
- Application menu / app launcher
- System search
- File manager "Open With" menu
- Rofi / wofi / dmenu launcher

---

## Supported Desktop Environments

| DE | Status | Default Terminal | Launcher File |
|---|---|---|---|
| GNOME | ✅ Fully supported | gnome-terminal | `antigravity-cli-gnome.desktop` |
| KDE Plasma | ✅ Fully supported | konsole | `antigravity-cli-kde.desktop` |
| XFCE | ✅ Fully supported | xfce4-terminal | `antigravity-cli-xfce.desktop` |
| Cinnamon | ✅ Fully supported | gnome-terminal | `antigravity-cli-gnome.desktop` |
| MATE | ✅ Fully supported | mate-terminal | `antigravity-cli-gnome.desktop` |
| Budgie | ✅ Fully supported | gnome-terminal | `antigravity-cli-gnome.desktop` |
| LXQt | ✅ Fully supported | qterminal | `antigravity-cli-xterm.desktop` |
| Pantheon | ✅ Fully supported | io.elementary.terminal | `antigravity-cli-xterm.desktop` |
| Sway | ⚠️ Manual (rofi/wofi) | foot / alacritty | N/A (use rofi) |
| i3 | ⚠️ Manual (rofi/dmenu) | i3-sensible-terminal | N/A (use rofi) |
| dwm | ⚠️ Manual (dmenu) | st / xterm | N/A (use dmenu) |
| Hyprland | ⚠️ Manual (wofi) | foot / alacritty | N/A (use wofi) |

### BSD Systems

| System | Status | Notes |
|---|---|---|
| FreeBSD | ✅ Supported | Install via pkg, .desktop files work |
| OpenBSD | ✅ Supported | Install via pkg_add, .desktop files work |
| NetBSD | ✅ Supported | Install via pkgin, .desktop files work |

---

## Launcher Files

### 1. `antigravity-cli.desktop` (Default — Alacritty)

**For:** GNOME, XFCE, Cinnamon, MATE, Budgie, or any system with Alacritty

```ini
[Desktop Entry]
Type=Application
Name=Antigravity CLI
GenericName=AI Agent CLI
Comment=Google Antigravity AI agent command-line interface
Exec=alacritty -e agy
Icon=antigravity-cli
Terminal=false
Categories=Development;IDE;Utility;
MimeType=text/plain;
Keywords=ai;agent;cli;google;antigravity;
StartupNotify=true
Actions=NewWindow;

[Desktop Action NewWindow]
Name=New Window
Exec=alacritty -e agy
```

### 2. `antigravity-cli-gnome.desktop` (GNOME Terminal)

**For:** GNOME, Cinnamon, MATE, Budgie (without Alacritty)

```ini
[Desktop Entry]
Type=Application
Name=Antigravity CLI (GNOME Terminal)
GenericName=AI Agent CLI
Comment=Google Antigravity AI agent command-line interface (opens in GNOME Terminal)
Exec=gnome-terminal -- agy
Icon=antigravity-cli
Terminal=false
Categories=Development;IDE;Utility;
MimeType=text/plain;
Keywords=ai;agent;cli;google;antigravity;
StartupNotify=true
```

### 3. `antigravity-cli-kde.desktop` (Konsole)

**For:** KDE Plasma

```ini
[Desktop Entry]
Type=Application
Name=Antigravity CLI (Konsole)
GenericName=AI Agent CLI
Comment=Google Antigravity AI agent command-line interface (opens in Konsole)
Exec=konsole -e agy
Icon=antigravity-cli
Terminal=false
Categories=Development;IDE;Utility;
MimeType=text/plain;
Keywords=ai;agent;cli;google;antigravity;
StartupNotify=true
```

### 4. `antigravity-cli-xfce.desktop` (XFCE Terminal)

**For:** XFCE4

```ini
[Desktop Entry]
Type=Application
Name=Antigravity CLI (Terminal)
GenericName=AI Agent CLI
Comment=Google Antigravity AI agent command-line interface (opens in default terminal)
Exec=xfce4-terminal -e agy
Icon=antigravity-cli
Terminal=false
Categories=Development;IDE;Utility;
MimeType=text/plain;
Keywords=ai;agent;cli;google;antigravity;
StartupNotify=true
```

### 5. `antigravity-cli-kitty.desktop` (Kitty)

**For:** Sway, Hyprland, or systems using Kitty

```ini
[Desktop Entry]
Type=Application
Name=Antigravity CLI (Kitty)
GenericName=AI Agent CLI
Comment=Google Antigravity AI agent command-line interface (opens in Kitty)
Exec=kitty agy
Icon=antigravity-cli
Terminal=false
Categories=Development;IDE;Utility;
MimeType=text/plain;
Keywords=ai;agent;cli;google;antigravity;
StartupNotify=true
```

### 6. `antigravity-cli-xterm.desktop` (xterm — Fallback)

**For:** All DEs (universal fallback)

```ini
[Desktop Entry]
Type=Application
Name=Antigravity CLI (xterm)
GenericName=AI Agent CLI
Comment=Google Antigravity AI agent command-line interface (opens in xterm)
Exec=xterm -e agy
Icon=antigravity-cli
Terminal=false
Categories=Development;IDE;Utility;
MimeType=text/plain;
Keywords=ai;agent;cli;google;antigravity;
StartupNotify=true
```

### 7. `antigravity-cli.xml` (MIME Type Definition)

For file manager integration (optional):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
  <mime-type type="application/x-antigravity-project">
    <comment>Antigravity Project</comment>
    <glob pattern="*.agyi" weight="50"/>
    <glob pattern="*.antigravity" weight="50"/>
  </mime-type>
  <mime-type type="application/x-antigravity-workspace">
    <comment>Antigravity Workspace</comment>
    <glob pattern="*.agyw" weight="50"/>
  </mime-type>
</mime-info>
```

---

## Manual Installation

### GNOME / Cinnamon / MATE / Budgie

```bash
# Detect terminal
if command -v alacritty >/dev/null; then
  TERMINAL="alacritty"
elif command -v gnome-terminal >/dev/null; then
  TERMINAL="gnome-terminal"
else
  TERMINAL="xterm"
fi

# Copy launcher
mkdir -p ~/.local/share/applications ~/.local/share/icons/hicolor/512x512/apps
cp antigravity-cli.desktop ~/.local/share/applications/
chmod +x ~/.local/share/applications/antigravity-cli.desktop

# Update desktop database
update-desktop-database ~/.local/share/applications 2>/dev/null || true
gtk-update-icon-cache -q ~/.local/share/icons/hicolor 2>/dev/null || true

echo "Launcher installed! Find 'Antigravity CLI' in your application menu."
```

### KDE Plasma

```bash
mkdir -p ~/.local/share/applications ~/.local/share/icons/hicolor/512x512/apps
cp antigravity-cli-kde.desktop ~/.local/share/applications/antigravity-cli.desktop
chmod +x ~/.local/share/applications/antigravity-cli.desktop
kbuildsycoca5 2>/dev/null || true
echo "Launcher installed! Find 'Antigravity CLI' in Kickoff menu."
```

### XFCE

```bash
mkdir -p ~/.local/share/applications ~/.local/share/icons/hicolor/512x512/apps
cp antigravity-cli-xfce.desktop ~/.local/share/applications/antigravity-cli.desktop
chmod +x ~/.local/share/applications/antigravity-cli.desktop
update-desktop-database ~/.local/share/applications 2>/dev/null || true
echo "Launcher installed! Find 'Antigravity CLI' in Applications menu."
```

### Sway / i3 / dwm / Hyprland

For tiling WMs, use rofi or wofi as a launcher:

```bash
# Install rofi (if not already installed)
sudo pacman -S rofi  # Arch
sudo apt install rofi  # Ubuntu

# Create launcher script
cat > ~/.local/bin/launch-antigravity << 'EOF'
#!/usr/bin/env bash
alacritty -e agy &
EOF
chmod +x ~/.local/bin/launch-antigravity

# Add keybinding in sway/config or i3/config
# Sway: bindsym $mod+Return exec alacritty -e agy
# i3: bindsym $mod+Return exec alacritty -e agy
```

---

## Automated Installation

Use the provided installer script:

```bash
# Install launcher (auto-detect terminal)
bash install-launcher.sh --install

# Uninstall launcher
bash install-launcher.sh --uninstall

# Check status
bash install-launcher.sh --status
```

---

## Uninstall

```bash
rm -f ~/.local/share/applications/antigravity-cli.desktop
rm -f ~/.local/share/icons/hicolor/512x512/apps/antigravity-cli.png

# Update caches
update-desktop-database ~/.local/share/applications 2>/dev/null || true
gtk-update-icon-cache -q ~/.local/share/icons/hicolor 2>/dev/null || true

# KDE
kbuildsycoca5 2>/dev/null || true
```

---

## Troubleshooting

### Launcher does not appear in menu

1. **Check file exists:**
   ```bash
   ls -la ~/.local/share/applications/antigravity-cli.desktop
   ```

2. **Check syntax is valid:**
   ```bash
   desktop-file-validate ~/.local/share/applications/antigravity-cli.desktop
   ```

3. **Update database:**
   ```bash
   update-desktop-database ~/.local/share/applications
   ```

4. **Logout/Login** or **restart DE**

### Icon does not appear

1. **Check icon exists:**
   ```bash
   ls -la ~/.local/share/icons/hicolor/512x512/apps/antigravity-cli.png
   ```

2. **Update icon cache:**
   ```bash
   gtk-update-icon-cache -q ~/.local/share/icons/hicolor
   ```

### Terminal does not open

1. **Check terminal is available:**
   ```bash
   which alacritty gnome-terminal konsole xfce4-terminal xterm
   ```

2. **Change terminal in .desktop:**
   Edit the `Exec=` line in `~/.local/share/applications/antigravity-cli.desktop`

3. **Test manually:**
   ```bash
   alacritty -e agy  # or another terminal
   ```

### Sway/i3 launcher not working

1. **Ensure rofi is installed:**
   ```bash
   sudo pacman -S rofi  # Arch
   sudo apt install rofi  # Ubuntu
   ```

2. **Test rofi:**
   ```bash
   echo -e "agyi\nagyi --help" | rofi -dmenu -p "Antigravity"
   ```

---

## References

| Resource | URL |
|---|---|
| Desktop Entry Spec | `https://specifications.freedesktop.org/desktop-entry-spec/latest/` |
| Icon Theme Spec | `https://specifications.freedesktop.org/icon-theme-spec/latest/` |
| MIME Info Spec | `https://specifications.freedesktop.org/shared-mime-info-spec/latest/` |

---

*Last updated: 2026-08-19*
*Researcher: sandikodev*
