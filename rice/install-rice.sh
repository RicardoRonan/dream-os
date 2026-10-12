#!/usr/bin/env bash
# Dream OS rice — install niri + DankMaterialShell on any distro, then lay down configs.
# Requires a package manager; installing deps needs sudo. Config copy is user-space.
#
#   bash rice/install-rice.sh            # install + configure
#   bash rice/install-rice.sh configs    # only (re)copy configs
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RICE="$REPO/rice"
CFG="$HOME/.config"

say()  { printf '%s\n' "$*"; }
warn() { printf 'WARN: %s\n' "$*" >&2; }

detect_pm() {
  for pm in apt dnf pacman zypper; do
    command -v "$pm" >/dev/null 2>&1 && { echo "$pm"; return; }
  done
  echo none
}

install_deps() {
  local pm="$1"
  case "$pm" in
    apt)
      sudo add-apt-repository -y ppa:avengemedia/danklinux || warn "danklinux PPA failed"
      sudo add-apt-repository -y ppa:avengemedia/dms       || warn "dms PPA failed"
      sudo apt-get update || true
      sudo apt-get install -y niri dms matugen
      ;;
    dnf)
      sudo dnf copr enable -y avengemedia/dms || warn "copr enable failed"
      sudo dnf install -y niri dms matugen
      ;;
    pacman)
      sudo pacman -Syu --needed niri dms-shell-niri matugen xwayland-satellite \
        xdg-desktop-portal-gnome xdg-desktop-portal-gtk
      ;;
    zypper)
      warn "openSUSE: add the DMS OBS repo, then install niri + dms (see rice/README.md)."
      ;;
    *) warn "No supported package manager; install niri + DMS manually (see rice/README.md)." ;;
  esac
}

copy_configs() {
  mkdir -p "$CFG/niri"
  if [ -f "$CFG/niri/config.kdl" ] && ! cmp -s "$RICE/niri/config.kdl" "$CFG/niri/config.kdl"; then
    cp -a "$CFG/niri/config.kdl" "$CFG/niri/config.kdl.bak.$(date +%Y%m%d-%H%M%S)"
    say "Backed up existing niri config."
  fi
  cp "$RICE/niri/config.kdl" "$CFG/niri/config.kdl"
  say "Installed niri config -> $CFG/niri/config.kdl"
  [ -d "$RICE/dms" ] && say "DMS settings live at ~/.config/DankMaterialShell (edit via the shell UI)."
}

enable_shell() {
  if command -v systemctl >/dev/null 2>&1 && command -v dms >/dev/null 2>&1; then
    systemctl --user add-wants niri.service dms 2>/dev/null || \
      systemctl --user add-wants niri.service dms.service 2>/dev/null || \
      warn "could not wire the dms user service; check DMS docs"
    say "DMS wired to start with the niri session."
  fi
}

preflight_login_screen() {
  # The rice never touches the login screen. If it's already broken, stop and fix it first.
  local link=/etc/systemd/system/display-manager.service
  if [ ! -e "$link" ] && [ ! -L "$link" ]; then
    warn "display-manager.service is missing - the login screen would not start at boot."
    warn "Restore it FIRST:  sudo bash \"$REPO/scripts/restore-login-screen.sh\""
    warn "Aborting so we don't make things worse."
    exit 1
  fi
  say "Login screen OK ($(readlink -f "$link")) - the rice does NOT touch it."
}

pm="$(detect_pm)"
say "Detected package manager: $pm"

case "${1:-all}" in
  configs) copy_configs ;;
  all)     preflight_login_screen; install_deps "$pm"; copy_configs; enable_shell ;;
  *) echo "usage: $0 [all|configs]"; exit 1 ;;
esac

cat <<'EOF'

Done. Next:
  1. Log out and pick the "niri" session at the login screen to try the rice.
  2. Set your monitors in ~/.config/niri/config.kdl  (list them with: niri msg outputs).
  3. Dank Greeter (OPTIONAL): install dms-greeter, then point greetd's
     [general] service in /etc/greetd/*.toml at it.
     Do NOT disable cosmic-greeter first - that removes your login screen.
     If you lose the login screen (drop to a TTY), recover with:
       sudo systemctl enable cosmic-greeter && sudo systemctl start cosmic-greeter
EOF
