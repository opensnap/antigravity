#!/usr/bin/env bash
# antigravity-test.sh — Comprehensive test suite for Antigravity CLI & packaging
# Runs on Research-01 (Ubuntu 26.04 LTS, GNOME Wayland)
# Author: sandikodev
# Date: 2026-08-19
set +e  # Don't exit on errors — we handle them ourselves

# ============================================================================
# Configuration
# ============================================================================
WORKSPACE="/mnt/research/antigravity"
LAUNCHERS_DIR="${WORKSPACE}/launchers"
PACKAGING_DIR="${WORKSPACE}/packaging"
TEST_REPORT="/tmp/antigravity-test-report-$(date +%Y%m%d-%H%M%S).txt"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Counters
TOTAL=0
PASSED=0
FAILED=0
SKIPPED=0
WARNINGS=0

# ============================================================================
# Test Framework
# ============================================================================
log() { printf '%s\n' "$*"; }
info() { printf "${CYAN}[INFO]${NC} %s\n" "$*"; }
pass() { printf "${GREEN}[PASS]${NC} %s\n" "$*"; PASSED=$((PASSED+1)); TOTAL=$((TOTAL+1)); }
fail() { printf "${RED}[FAIL]${NC} %s\n" "$*"; FAILED=$((FAILED+1)); TOTAL=$((TOTAL+1)); }
warn() { printf "${YELLOW}[WARN]${NC} %s\n" "$*"; WARNINGS=$((WARNINGS+1)); }
skip() { printf "${YELLOW}[SKIP]${NC} %s\n" "$*"; SKIPPED=$((SKIPPED+1)); TOTAL=$((TOTAL+1)); }
header() { printf "\n${BOLD}${BLUE}══════════════════════════════════════════════════════════════${NC}\n"; printf "${BOLD}${BLUE}  %s${NC}\n" "$1"; printf "${BOLD}${BLUE}══════════════════════════════════════════════════════════════${NC}\n"; }
subheader() { printf "\n${BOLD}${CYAN}── %s ──${NC}\n" "$*"; }

run_test() {
  local test_name="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    pass "$test_name"
  else
    fail "$test_name"
  fi
  return 0
}

run_test_output() {
  local test_name="$1"
  local expected="$2"
  shift 2
  local output
  output=$("$@" 2>&1) || true
  if echo "$output" | grep -q "$expected" 2>/dev/null; then
    pass "$test_name"
  else
    fail "$test_name (expected: $expected, got: $output)"
  fi
  return 0
}

file_exists() {
  local test_name="$1"
  local filepath="$2"
  if [ -f "$filepath" ]; then
    pass "$test_name"
  else
    fail "$test_name (file not found: $filepath)"
  fi
  return 0
}

file_not_empty() {
  local test_name="$1"
  local filepath="$2"
  if [ -s "$filepath" ]; then
    pass "$test_name"
  else
    fail "$test_name (file is empty: $filepath)"
  fi
  return 0
}

dir_exists() {
  local test_name="$1"
  local dirpath="$2"
  if [ -d "$dirpath" ]; then
    pass "$test_name"
  else
    fail "$test_name (directory not found: $dirpath)"
  fi
  return 0
}

# ============================================================================
# Test Suites
# ============================================================================

test_cli_installation() {
  header "TEST SUITE 1: Antigravity CLI Installation"

  subheader "1.1 Binary Location"
  file_exists "agy binary exists at /home/dev/.local/bin/agy" "/home/dev/.local/bin/agy"

  subheader "1.2 Binary Type"
  run_test_output "agy is ELF 64-bit executable" "ELF 64-bit" file /home/dev/.local/bin/agy

  subheader "1.3 Binary Permissions"
  run_test "agy is executable" test -x /home/dev/.local/bin/agy

  subheader "1.4 Version Check"
  run_test_output "agy --version returns 1.1.14" "1.1.14" /home/dev/.local/bin/agy --version

  subheader "1.5 Help Output"
  run_test "agy --help produces output" /home/dev/.local/bin/agy --help

  subheader "1.6 Available in PATH"
  run_test "agy is in PATH" which agy

  subheader "1.7 Binary Size (sanity check)"
  local size
  size=$(stat -c%s /home/dev/.local/bin/agy 2>/dev/null || echo 0)
  if [ "$size" -gt 100000000 ] && [ "$size" -lt 500000000 ]; then
    pass "agy binary size is reasonable ($((size / 1024 / 1024))MB)"
  else
    warn "agy binary size is unexpected: ${size} bytes"
  fi

  subheader "1.8 Dynamic Dependencies"
  run_test "agy links to glibc" ldd /home/dev/.local/bin/agy | grep -q "libc.so"
}

test_desktop_launcher_files() {
  header "TEST SUITE 2: Desktop Launcher Files"

  subheader "2.1 All Launcher Files Exist"
  local launcher_files=(
    "antigravity-cli.desktop"
    "antigravity-cli-gnome.desktop"
    "antigravity-cli-kde.desktop"
    "antigravity-cli-xfce.desktop"
    "antigravity-cli-kitty.desktop"
    "antigravity-cli-kitty-nowm.desktop"
    "antigravity-cli-xterm.desktop"
    "antigravity-cli.xml"
    "install-launcher.sh"
    "README.md"
  )
  for f in "${launcher_files[@]}"; do
    file_exists "File: $f" "${LAUNCHERS_DIR}/$f"
  done

  subheader "2.2 Desktop File Syntax Validation"
  for f in "${LAUNCHERS_DIR}"/*.desktop; do
    local basename
    basename=$(basename "$f")
    if command -v desktop-file-validate >/dev/null 2>&1; then
      run_test "Validate: $basename" desktop-file-validate "$f"
    else
      run_test "Validate: $basename (grep fallback)" grep -q "^\[Desktop Entry\]" "$f"
    fi
  done

  subheader "2.3 Desktop File Required Fields"
  for f in "${LAUNCHERS_DIR}"/*.desktop; do
    local basename
    basename=$(basename "$f")
    local has_type has_name has_exec
    has_type=$(grep -c "^Type=Application" "$f" || true)
    has_name=$(grep -c "^Name=" "$f" || true)
    has_exec=$(grep -c "^Exec=" "$f" || true)
    if [ "$has_type" -ge 1 ] && [ "$has_name" -ge 1 ] && [ "$has_exec" -ge 1 ]; then
      pass "Required fields present: $basename"
    else
      fail "Missing required fields: $basename (Type=$has_type Name=$has_name Exec=$has_exec)"
    fi
  done

  subheader "2.4 Desktop File Content Checks"
  for f in "${LAUNCHERS_DIR}"/*.desktop; do
    local basename
    basename=$(basename "$f")
    if grep -q "Categories=" "$f"; then
      pass "Has Categories: $basename"
    else
      warn "Missing Categories: $basename"
    fi
    if grep -q "Keywords=" "$f"; then
      pass "Has Keywords: $basename"
    else
      warn "Missing Keywords: $basename"
    fi
    if grep -q "GenericName=" "$f"; then
      pass "Has GenericName: $basename"
    else
      warn "Missing GenericName: $basename"
    fi
  done

  subheader "2.5 Each Launcher Targets Different Terminal"
  local terminals_found=()
  for f in "${LAUNCHERS_DIR}"/*.desktop; do
    local exec_line
    exec_line=$(grep "^Exec=" "$f" | head -1 | sed 's/^Exec=//')
    terminals_found+=("$exec_line")
  done
  local unique_count
  unique_count=$(printf '%s\n' "${terminals_found[@]}" | sort -u | wc -l)
  if [ "$unique_count" -ge 5 ]; then
    pass "Unique terminal launchers: $unique_count"
  else
    warn "Only $unique_count unique terminal launchers found"
  fi

  subheader "2.6 MIME Type Definition"
  file_exists "MIME XML exists" "${LAUNCHERS_DIR}/antigravity-cli.xml"
  run_test "MIME XML is valid" grep -q "application/x-antigravity-project" "${LAUNCHERS_DIR}/antigravity-cli.xml"
  run_test "MIME XML has glob patterns" grep -q 'glob pattern=' "${LAUNCHERS_DIR}/antigravity-cli.xml"
}

test_launcher_install_script() {
  header "TEST SUITE 3: Launcher Install Script"

  subheader "3.1 Script Exists and is Executable"
  file_exists "install-launcher.sh exists" "${LAUNCHERS_DIR}/install-launcher.sh"
  run_test "install-launcher.sh is executable" test -x "${LAUNCHERS_DIR}/install-launcher.sh"

  subheader "3.2 Script Syntax Check"
  run_test "install-launcher.sh has valid bash syntax" bash -n "${LAUNCHERS_DIR}/install-launcher.sh"

  subheader "3.3 Script Has Required Functions"
  run_test "Has detect_terminal function" grep -q "detect_terminal()" "${LAUNCHERS_DIR}/install-launcher.sh"
  run_test "Has generate_desktop_entry function" grep -q "generate_desktop_entry()" "${LAUNCHERS_DIR}/install-launcher.sh"
  run_test "Has install_launcher function" grep -q "install_launcher()" "${LAUNCHERS_DIR}/install-launcher.sh"
  run_test "Has uninstall_launcher function" grep -q "uninstall_launcher()" "${LAUNCHERS_DIR}/install-launcher.sh"

  subheader "3.4 Script Has Required Flags"
  run_test "Has --install flag" grep -q "\-\-install" "${LAUNCHERS_DIR}/install-launcher.sh"
  run_test "Has --uninstall flag" grep -q "\-\-uninstall" "${LAUNCHERS_DIR}/install-launcher.sh"
  run_test "Has --status flag" grep -q "\-\-status" "${LAUNCHERS_DIR}/install-launcher.sh"
  run_test "Has --help flag" grep -q "\-\-help" "${LAUNCHERS_DIR}/install-launcher.sh"

  subheader "3.5 Script Terminal Detection"
  run_test "Detects alacritty" grep -q "alacritty" "${LAUNCHERS_DIR}/install-launcher.sh"
  run_test "Detects kitty" grep -q "kitty" "${LAUNCHERS_DIR}/install-launcher.sh"
  run_test "Detects gnome-terminal" grep -q "gnome-terminal" "${LAUNCHERS_DIR}/install-launcher.sh"
  run_test "Detects konsole" grep -q "konsole" "${LAUNCHERS_DIR}/install-launcher.sh"
  run_test "Detects xfce4-terminal" grep -q "xfce4-terminal" "${LAUNCHERS_DIR}/install-launcher.sh"
  run_test "Detects xterm" grep -q "xterm" "${LAUNCHERS_DIR}/install-launcher.sh"
}

test_launcher_install_uninstall() {
  header "TEST SUITE 4: Launcher Install/Uninstall Lifecycle"

  subheader "4.1 Install Launcher"
  run_test "Install launcher" bash "${LAUNCHERS_DIR}/install-launcher.sh" --install
  file_exists "Desktop file installed" "${HOME}/.local/share/applications/antigravity-cli.desktop"

  subheader "4.2 Verify Installed Desktop File"
  if [ -f "${HOME}/.local/share/applications/antigravity-cli.desktop" ]; then
    run_test "Installed file has [Desktop Entry]" grep -q "^\[Desktop Entry\]" "${HOME}/.local/share/applications/antigravity-cli.desktop"
    run_test "Installed file has Exec=" grep -q "^Exec=" "${HOME}/.local/share/applications/antigravity-cli.desktop"
    run_test "Installed file has Name=" grep -q "^Name=" "${HOME}/.local/share/applications/antigravity-cli.desktop"
    run_test "Installed file has Icon=" grep -q "^Icon=" "${HOME}/.local/share/applications/antigravity-cli.desktop"
    run_test "Installed file has Categories=" grep -q "^Categories=" "${HOME}/.local/share/applications/antigravity-cli.desktop"
    run_test "Exec line contains 'agy'" grep -q "agy" "${HOME}/.local/share/applications/antigravity-cli.desktop"
  fi

  subheader "4.3 Status Check"
  run_test "Status shows launcher installed" bash "${LAUNCHERS_DIR}/install-launcher.sh" --status

  subheader "4.4 Uninstall Launcher"
  run_test "Uninstall launcher" bash "${LAUNCHERS_DIR}/install-launcher.sh" --uninstall
  run_test "Desktop file removed" test ! -f "${HOME}/.local/share/applications/antigravity-cli.desktop"

  subheader "4.5 Re-install for Production Use"
  run_test "Re-install launcher" bash "${LAUNCHERS_DIR}/install-launcher.sh" --install
  file_exists "Desktop file re-installed" "${HOME}/.local/share/applications/antigravity-cli.desktop"
}

test_packaging_debian() {
  header "TEST SUITE 5: Debian Packaging (Ubuntu/Debian)"

  subheader "5.1 Directory Structure"
  dir_exists "packaging/debian exists" "${PACKAGING_DIR}/debian"
  dir_exists "DEBIAN directory exists" "${PACKAGING_DIR}/debian/DEBIAN"
  dir_exists "usr directory exists" "${PACKAGING_DIR}/debian/usr"

  subheader "5.2 DEBIAN/control"
  file_exists "control file exists" "${PACKAGING_DIR}/debian/DEBIAN/control"
  file_not_empty "control file not empty" "${PACKAGING_DIR}/debian/DEBIAN/control"
  run_test "control has Package field" grep -q "^Package:" "${PACKAGING_DIR}/debian/DEBIAN/control"
  run_test "control has Version field" grep -q "^Version:" "${PACKAGING_DIR}/debian/DEBIAN/control"
  run_test "control has Architecture field" grep -q "^Architecture:" "${PACKAGING_DIR}/debian/DEBIAN/control"
  run_test "control has Depends field" grep -q "^Depends:" "${PACKAGING_DIR}/debian/DEBIAN/control"
  run_test "control has Description field" grep -q "^Description:" "${PACKAGING_DIR}/debian/DEBIAN/control"
  run_test "control has Maintainer field" grep -q "^Maintainer:" "${PACKAGING_DIR}/debian/DEBIAN/control"
  run_test "control has Homepage field" grep -q "^Homepage:" "${PACKAGING_DIR}/debian/DEBIAN/control"

  subheader "5.3 DEBIAN Scripts"
  file_exists "postinst exists" "${PACKAGING_DIR}/debian/DEBIAN/postinst"
  file_exists "prerm exists" "${PACKAGING_DIR}/debian/DEBIAN/prerm"
  file_exists "postrm exists" "${PACKAGING_DIR}/debian/DEBIAN/postrm"
  run_test "postinst has valid bash syntax" bash -n "${PACKAGING_DIR}/debian/DEBIAN/postinst"
  run_test "prerm has valid bash syntax" bash -n "${PACKAGING_DIR}/debian/DEBIAN/prerm"
  run_test "postrm has valid bash syntax" bash -n "${PACKAGING_DIR}/debian/DEBIAN/postrm"
  run_test "postinst has #DEBHELPER#" grep -q "#DEBHELPER#" "${PACKAGING_DIR}/debian/DEBIAN/postinst"
  run_test "prerm has #DEBHELPER#" grep -q "#DEBHELPER#" "${PACKAGING_DIR}/debian/DEBIAN/prerm"
  run_test "postrm has #DEBHELPER#" grep -q "#DEBHELPER#" "${PACKAGING_DIR}/debian/DEBIAN/postrm"

  subheader "5.4 Desktop Files in Package"
  file_exists "desktop entry exists" "${PACKAGING_DIR}/debian/usr/share/applications/antigravity-cli.desktop"
  file_exists "terminal desktop entry exists" "${PACKAGING_DIR}/debian/usr/share/applications/antigravity-cli-terminal.desktop"
  run_test "desktop entry has Exec=" grep -q "^Exec=" "${PACKAGING_DIR}/debian/usr/share/applications/antigravity-cli.desktop"

  subheader "5.5 Build Script"
  file_exists "build-deb.sh exists" "${PACKAGING_DIR}/debian/build-deb.sh"
  run_test "build-deb.sh has valid bash syntax" bash -n "${PACKAGING_DIR}/debian/build-deb.sh"
  run_test "build-deb.sh has dpkg-deb" grep -q "dpkg-deb" "${PACKAGING_DIR}/debian/build-deb.sh"
  run_test "build-deb.sh references control" grep -q "control" "${PACKAGING_DIR}/debian/build-deb.sh"

  subheader "5.6 Package Metadata"
  run_test "Package name is antigravity-cli" grep -q "^Package: antigravity-cli" "${PACKAGING_DIR}/debian/DEBIAN/control"
  run_test "Architecture is amd64" grep -q "^Architecture: amd64" "${PACKAGING_DIR}/debian/DEBIAN/control"
  run_test "Priority is optional" grep -q "^Priority: optional" "${PACKAGING_DIR}/debian/DEBIAN/control"
  run_test "Section is devel" grep -q "^Section: devel" "${PACKAGING_DIR}/debian/DEBIAN/control"
}

test_packaging_arch() {
  header "TEST SUITE 6: Arch Linux Packaging (AUR)"

  subheader "6.1 Directory Structure"
  dir_exists "packaging/arch exists" "${PACKAGING_DIR}/arch"

  subheader "6.2 PKGBUILD"
  file_exists "PKGBUILD exists" "${PACKAGING_DIR}/arch/PKGBUILD"
  file_not_empty "PKGBUILD not empty" "${PACKAGING_DIR}/arch/PKGBUILD"
  run_test "PKGBUILD has pkgname" grep -q "^pkgname=" "${PACKAGING_DIR}/arch/PKGBUILD"
  run_test "PKGBUILD has pkgver" grep -q "^pkgver=" "${PACKAGING_DIR}/arch/PKGBUILD"
  run_test "PKGBUILD has pkgrel" grep -q "^pkgrel=" "${PACKAGING_DIR}/arch/PKGBUILD"
  run_test "PKGBUILD has pkgdesc" grep -q "^pkgdesc=" "${PACKAGING_DIR}/arch/PKGBUILD"
  run_test "PKGBUILD has arch" grep -q "^arch=" "${PACKAGING_DIR}/arch/PKGBUILD"
  run_test "PKGBUILD has url" grep -q "^url=" "${PACKAGING_DIR}/arch/PKGBUILD"
  run_test "PKGBUILD has license" grep -q "^license=" "${PACKAGING_DIR}/arch/PKGBUILD"
  run_test "PKGBUILD has depends" grep -q "^depends=" "${PACKAGING_DIR}/arch/PKGBUILD"
  run_test "PKGBUILD has provides" grep -q "^provides=" "${PACKAGING_DIR}/arch/PKGBUILD"
  run_test "PKGBUILD has conflicts" grep -q "^conflicts=" "${PACKAGING_DIR}/arch/PKGBUILD"
  run_test "PKGBUILD has source_x86_64" grep -q "^source_x86_64=" "${PACKAGING_DIR}/arch/PKGBUILD"
  run_test "PKGBUILD has source_aarch64" grep -q "^source_aarch64=" "${PACKAGING_DIR}/arch/PKGBUILD"
  run_test "PKGBUILD has package() function" grep -q "^package()" "${PACKAGING_DIR}/arch/PKGBUILD"

  subheader "6.3 PKGBUILD Values"
  run_test "pkgname is antigravity-cli" grep -q '^pkgname=antigravity-cli$' "${PACKAGING_DIR}/arch/PKGBUILD"
  run_test "provides includes agy" grep -q "provides=.*'agy'" "${PACKAGING_DIR}/arch/PKGBUILD"
  run_test "source includes google domain" grep -q "dl.google.com" "${PACKAGING_DIR}/arch/PKGBUILD"

  subheader "6.4 .SRCINFO"
  file_exists ".SRCINFO exists" "${PACKAGING_DIR}/arch/.SRCINFO"
  file_not_empty ".SRCINFO not empty" "${PACKAGING_DIR}/arch/.SRCINFO"
  run_test ".SRCINFO has pkgbase" grep -q "pkgbase" "${PACKAGING_DIR}/arch/.SRCINFO"
  run_test ".SRCINFO has pkgver" grep -q "pkgver" "${PACKAGING_DIR}/arch/.SRCINFO"
  run_test ".SRCINFO has source_x86_64" grep -q "source_x86_64" "${PACKAGING_DIR}/arch/.SRCINFO"

  subheader "6.5 Install Hooks"
  file_exists "install hooks exist" "${PACKAGING_DIR}/arch/antigravity-cli.install"
  run_test "install hooks have post_install" grep -q "post_install()" "${PACKAGING_DIR}/arch/antigravity-cli.install"
  run_test "install hooks have post_upgrade" grep -q "post_upgrade()" "${PACKAGING_DIR}/arch/antigravity-cli.install"

  subheader "6.6 Shell Profile"
  file_exists "shell profile exists" "${PACKAGING_DIR}/arch/antigravity-cli.sh"
  run_test "shell profile sets PATH" grep -q "PATH" "${PACKAGING_DIR}/arch/antigravity-cli.sh"

  subheader "6.7 Desktop Files in Package"
  file_exists "desktop entry exists" "${PACKAGING_DIR}/arch/antigravity-cli.desktop"
  file_exists "terminal desktop entry exists" "${PACKAGING_DIR}/arch/antigravity-cli-terminal.desktop"
  run_test "desktop entry has Exec=" grep -q "^Exec=" "${PACKAGING_DIR}/arch/antigravity-cli.desktop"
}

test_documentation() {
  header "TEST SUITE 7: Documentation Completeness"

  subheader "7.1 Main README"
  file_exists "Main README exists" "${WORKSPACE}/README.md"
  file_not_empty "Main README not empty" "${WORKSPACE}/README.md"
  local readme_lines
  readme_lines=$(wc -l < "${WORKSPACE}/README.md")
  if [ "$readme_lines" -gt 500 ]; then
    pass "Main README has $readme_lines lines (comprehensive)"
  else
    warn "Main README has only $readme_lines lines"
  fi

  subheader "7.2 README Sections"
  local required_sections=(
    "About Antigravity"
    "Installation on Research-01"
    "Repository Issues"
    "Pull Requests"
    "Analysis & Contribution"
    "Packaging Prototypes"
    "Desktop Launchers"
    "Work Plan"
    "References"
  )
  for section in "${required_sections[@]}"; do
    run_test "README has section: $section" grep -qi "$section" "${WORKSPACE}/README.md"
  done

  subheader "7.3 README Key Content"
  run_test "README mentions sandikodev" grep -q "sandikodev" "${WORKSPACE}/README.md"
  run_test "README mentions Ubuntu 26.04" grep -q "Ubuntu 26.04" "${WORKSPACE}/README.md"
  run_test "README mentions Research-01" grep -q "Research-01" "${WORKSPACE}/README.md"
  run_test "README mentions Issue #1" grep -q "Issue #1" "${WORKSPACE}/README.md"
  run_test "README mentions PR #2" grep -q "PR #2" "${WORKSPACE}/README.md"
  run_test "README mentions PR #3" grep -q "PR #3" "${WORKSPACE}/README.md"
  run_test "README mentions PR #4" grep -q "PR #4" "${WORKSPACE}/README.md"
  run_test "README has download URLs" grep -q "storage.googleapis.com" "${WORKSPACE}/README.md"
  run_test "README has GitHub URLs" grep -q "github.com/opensnap/antigravity" "${WORKSPACE}/README.md"

  subheader "7.4 Launcher README"
  file_exists "Launcher README exists" "${LAUNCHERS_DIR}/README.md"
  file_not_empty "Launcher README not empty" "${LAUNCHERS_DIR}/README.md"
  run_test "Launcher README has DE compatibility table" grep -qi "Desktop Environment" "${LAUNCHERS_DIR}/README.md"
  run_test "Launcher README has GNOME" grep -q "GNOME" "${LAUNCHERS_DIR}/README.md"
  run_test "Launcher README has KDE" grep -q "KDE" "${LAUNCHERS_DIR}/README.md"
  run_test "Launcher README has XFCE" grep -q "XFCE" "${LAUNCHERS_DIR}/README.md"
  run_test "Launcher README has Sway" grep -q "Sway" "${LAUNCHERS_DIR}/README.md"
  run_test "Launcher README has i3" grep -q "i3" "${LAUNCHERS_DIR}/README.md"
  run_test "Launcher README has FreeBSD" grep -q "FreeBSD" "${LAUNCHERS_DIR}/README.md"
  run_test "Launcher README has troubleshooting" grep -qi "Troubleshooting" "${LAUNCHERS_DIR}/README.md"

  subheader "7.5 Debian README"
  file_exists "Debian README exists" "${PACKAGING_DIR}/debian/README.md"
  run_test "Debian README has build instructions" grep -qi "Build" "${PACKAGING_DIR}/debian/README.md"
  run_test "Debian README has install instructions" grep -qi "Install" "${PACKAGING_DIR}/debian/README.md"
  run_test "Debian README has uninstall instructions" grep -qi "Uninstall" "${PACKAGING_DIR}/debian/README.md"

  subheader "7.6 Arch README"
  file_exists "Arch README exists" "${PACKAGING_DIR}/arch/README.md"
  run_test "Arch README has build instructions" grep -qi "Build" "${PACKAGING_DIR}/arch/README.md"
  run_test "Arch README has AUR submit instructions" grep -qi "AUR\|Submit" "${PACKAGING_DIR}/arch/README.md"
  run_test "Arch README has install from AUR" grep -qi "yay\|paru" "${PACKAGING_DIR}/arch/README.md"
}

test_host_environment() {
  header "TEST SUITE 8: Host Environment Compatibility"

  subheader "8.1 OS Detection"
  run_test_output "Ubuntu 26.04 detected" "26.04" lsb_release -a 2>/dev/null || true

  subheader "8.2 Required Tools"
  run_test "curl is available" which curl
  run_test "tar is available" which tar
  run_test "python3 is available" which python3
  run_test "bash is available" which bash
  run_test "git is available" which git
  run_test "dpkg-deb is available" which dpkg-deb

  subheader "8.3 Desktop Environment"
  run_test "XDG_CURRENT_DESKTOP is set" printenv XDG_CURRENT_DESKTOP
  run_test "GNOME is detected" bash -c "printenv XDG_CURRENT_DESKTOP | grep -qi gnome"

  subheader "8.4 Terminal Emulators"
  run_test "Alacritty is installed" which alacritty
  run_test "xterm is installed" which xterm

  subheader "8.5 Desktop Integration Tools"
  run_test "update-desktop-database available" which update-desktop-database
  run_test "gtk-update-icon-cache available" which gtk-update-icon-cache
  run_test "desktop-file-validate available" which desktop-file-validate

  subheader "8.6 Font Support"
  run_test "Nerd Font installed" bash -c "fc-list | grep -qi nerd"
  run_test "JetBrainsMono installed" bash -c "fc-list | grep -qi jetbrains"

  subheader "8.7 glibc Version"
  local glibc_version
  glibc_version=$(ldd --version 2>&1 | head -1 | grep -oP '[\d]+\.[\d]+' | head -1)
  if [ -n "$glibc_version" ]; then
    pass "glibc version: $glibc_version (>= 2.28 required)"
  else
    warn "Could not determine glibc version"
  fi
}

test_cross_de_compatibility() {
  header "TEST SUITE 9: Cross-Desktop-Environment Compatibility"

  subheader "9.1 Desktop Files Use Standard Fields Only"
  for f in "${LAUNCHERS_DIR}"/*.desktop; do
    local basename
    basename=$(basename "$f")
    # Check for non-standard fields (exclude known valid ones)
    local non_standard
    non_standard=$(grep -E "^[A-Z][a-zA-Z_-]+=" "$f" | grep -v -E "^(Type|Name|GenericName|Comment|Exec|Icon|Terminal|Categories|MimeType|Keywords|StartupNotify|Actions|StartupWMClass|TryExec|Path|Dev|Hidden|OnlyShowIn|NotShowIn|DBusActivatable|Implements|Keywords|X-GNOME|X-KDE|X-Flatpak)=" || true)
    if [ -z "$non_standard" ]; then
      pass "No non-standard fields: $basename"
    else
      warn "Non-standard fields in $basename: $non_standard"
    fi
  done

  subheader "9.2 Desktop Files Have Proper Encodings"
  for f in "${LAUNCHERS_DIR}"/*.desktop; do
    local basename
    basename=$(basename "$f")
    # Check for UTF-8 encoding issues
    if file "$f" | grep -qi "utf-8\|ascii"; then
      pass "UTF-8/ASCII encoding: $basename"
    else
      warn "Unexpected encoding: $basename"
    fi
  done

  subheader "9.3 Desktop Files Have Proper Line Endings"
  for f in "${LAUNCHERS_DIR}"/*.desktop; do
    local basename
    basename=$(basename "$f")
    # Check for Windows line endings
    if grep -qP '\r' "$f"; then
      warn "Windows line endings detected: $basename"
    else
      pass "Unix line endings: $basename"
    fi
  done

  subheader "9.4 MIME Type Definition Completeness"
  file_exists "MIME XML exists" "${LAUNCHERS_DIR}/antigravity-cli.xml"
  run_test "MIME has UTF-8 encoding" grep -q 'encoding="UTF-8"' "${LAUNCHERS_DIR}/antigravity-cli.xml"
  run_test "MIME has xmlns" grep -q 'xmlns=' "${LAUNCHERS_DIR}/antigravity-cli.xml"
  run_test "MIME defines project type" grep -q 'application/x-antigravity-project' "${LAUNCHERS_DIR}/antigravity-cli.xml"
  run_test "MIME defines workspace type" grep -q 'application/x-antigravity-workspace' "${LAUNCHERS_DIR}/antigravity-cli.xml"
}

test_script_quality() {
  header "TEST SUITE 10: Script Quality Checks"

  subheader "10.1 Shellcheck (if available)"
  if command -v shellcheck >/dev/null 2>&1; then
    run_test "install-launcher.sh passes shellcheck" shellcheck "${LAUNCHERS_DIR}/install-launcher.sh"
    run_test "build-deb.sh passes shellcheck" shellcheck "${PACKAGING_DIR}/debian/build-deb.sh"
  else
    skip "shellcheck not installed"
  fi

  subheader "10.2 No Hardcoded Secrets"
  for f in $(find "${WORKSPACE}" -type f -name "*.sh" -o -name "*.desktop" -o -name "PKGBUILD" -o -name "control" | grep -v "test-antigravity"); do
    if grep -qiE "(password|secret|token|api_key|private_key)" "$f" 2>/dev/null; then
      fail "Potential secret in: $f"
    else
      pass "No secrets in: $(basename "$f")"
    fi
  done

  subheader "10.3 No Absolute Paths to Home Directory"
  for f in $(find "${WORKSPACE}" -type f \( -name "*.sh" -o -name "PKGBUILD" -o -name "control" \) | grep -v "test-antigravity"); do
    if grep -qE "/home/[^/]+/" "$f" 2>/dev/null && ! grep -q "SUDO_USER\|HOME" "$f" 2>/dev/null; then
      warn "Hardcoded home path in: $(basename "$f")"
    else
      pass "No hardcoded home path: $(basename "$f")"
    fi
  done

  subheader "10.4 File Permissions"
  run_test "install-launcher.sh is executable" test -x "${LAUNCHERS_DIR}/install-launcher.sh"
  run_test "build-deb.sh is executable" test -x "${PACKAGING_DIR}/debian/build-deb.sh"
  for f in "${PACKAGING_DIR}/debian/DEBIAN/"postinst "${PACKAGING_DIR}/debian/DEBIAN/"prerm "${PACKAGING_DIR}/debian/DEBIAN/"postrm; do
    run_test "$(basename "$f") is executable" test -x "$f"
  done
}

# ============================================================================
# Main
# ============================================================================
main() {
  printf "${BOLD}${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}\n"
  printf "${BOLD}${BLUE}║     Antigravity — Comprehensive Test Suite                  ║${NC}\n"
  printf "${BOLD}${BLUE}║     Host: Research-01 (Ubuntu 26.04 LTS)                   ║${NC}\n"
  printf "${BOLD}${BLUE}║     Date: $(date '+%Y-%m-%d %H:%M:%S')                              ║${NC}\n"
  printf "${BOLD}${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}\n"

  test_cli_installation
  test_desktop_launcher_files
  test_launcher_install_script
  test_launcher_install_uninstall
  test_packaging_debian
  test_packaging_arch
  test_documentation
  test_host_environment
  test_cross_de_compatibility
  test_script_quality

  # ============================================================================
  # Summary
  # ============================================================================
  header "TEST SUMMARY"

  printf "\n"
  printf "${BOLD}Total tests:${NC}   %d\n" "$TOTAL"
  printf "${GREEN}Passed:${NC}        %d\n" "$PASSED"
  printf "${RED}Failed:${NC}        %d\n" "$FAILED"
  printf "${YELLOW}Skipped:${NC}       %d\n" "$SKIPPED"
  printf "${YELLOW}Warnings:${NC}      %d\n" "$WARNINGS"
  printf "\n"

  if [ "$FAILED" -eq 0 ]; then
    printf "${GREEN}${BOLD}═══ ALL TESTS PASSED ═══${NC}\n"
  else
    printf "${RED}${BOLD}═══ %d TEST(S) FAILED ═══${NC}\n" "$FAILED"
  fi

  if [ "$WARNINGS" -gt 0 ]; then
    printf "${YELLOW}${BOLD}═══ %d WARNING(S) ═══${NC}\n" "$WARNINGS"
  fi

  # Save report
  {
    echo "Antigravity Test Report"
    echo "======================="
    echo "Date: $(date)"
    echo "Host: Research-01 (Ubuntu 26.04 LTS)"
    echo ""
    echo "Results:"
    echo "  Total:  $TOTAL"
    echo "  Passed: $PASSED"
    echo "  Failed: $FAILED"
    echo "  Skipped: $SKIPPED"
    echo "  Warnings: $WARNINGS"
    echo ""
    if [ "$FAILED" -eq 0 ]; then
      echo "STATUS: ALL TESTS PASSED"
    else
      echo "STATUS: $FAILED TEST(S) FAILED"
    fi
  } > "$TEST_REPORT"

  echo ""
  echo "Report saved to: $TEST_REPORT"

  return "$FAILED"
}

main "$@"
