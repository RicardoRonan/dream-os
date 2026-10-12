#!/usr/bin/env bash
# Dream OS rice - install a Wayland rice + lay down Dream OS configs.
#   apt/zypper  -> Sway + Waybar (packaged on Debian/Ubuntu/openSUSE)
#   dnf/pacman  -> niri + DankMaterialShell (packaged on Fedora/Arch)
# Installing deps needs sudo; copying configs is user-space.
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

preflight_login_screen() {
  # The rice adds a session; it NEVER touches the login screen.
  local link=/etc/systemd/system/display-manager.service
  if [ ! -e "$link" ] && [ ! -L "$link" ]; then
    warn "display-manager.service is missing - the login screen wouldn't start at boot."
    warn "Restore it FIRST:  sudo bash \"$REPO/scripts/restore-login-screen.sh\""
    warn "Aborting so we don't make things worse."
    exit 1
  fi
  say "Login screen OK ($(readlink -f "$link")) - the rice does NOT touch it."
}

# ---- stacks -----------------------------------------------------------------

install_sway() {
  local pm="$1"
  case "$pm" in
    apt)
      sudo apt-get update
      sudo apt-get install -y sway swaybg swayidle swaylock waybar wofi mako-notifier \
        grim slurp wl-clipboard cliphist mate-polkit kitty brightnessctl pavucontrol \
        blueman network-manager-gnome
      ;;
    zypper)
      sudo zypper install -y sway swaybg swayidle swaylock waybar wofi mako grim slurp \
        wl-clipboard cliphist polkit-gnome kitty brightnessctl pavucontrol \
        blueman NetworkManager-applet
      ;;
  esac
  backup_and_copy "$RICE/sway"  "$CFG/sway"
  backup_and_copy "$RICE/waybar" "$CFG/waybar"
  backup_and_copy "$RICE/mako"  "$CFG/mako"
  backup_and_copy "$RICE/wofi"  "$CFG/wofi"

  # Hybrid Intel+NVIDIA: force Intel AND pass --unsupported-gpu, or sway aborts
  # with "Proprietary Nvidia drivers are NOT supported".
  # cosmic-greeter runs as its own user and only reads /usr/share/wayland-sessions,
  # so a ~/.local session file is ignored - write the system one (sudo).
  sudo tee /usr/share/wayland-sessions/dream-os-sway.desktop >/dev/null <<'EOF'
[Desktop Entry]
Name=Sway (Dream OS)
Comment=Dream OS rice (Intel GPU + --unsupported-gpu for hybrid NVIDIA)
Exec=env WLR_DRM_DEVICES=/dev/dri/card0 WLR_NO_HARDWARE_CURSORS=1 sway --unsupported-gpu
Type=Application
DesktopNames=sway
EOF
  # Also make the stock "Sway" entry work.
  sudo sed -i 's|^Exec=sway$|Exec=env WLR_DRM_DEVICES=/dev/dri/card0 WLR_NO_HARDWARE_CURSORS=1 sway --unsupported-gpu|' \
    /usr/share/wayland-sessions/sway.desktop 2>/dev/null || true

  # Stop the waybar user-service from drawing a second bar over COSMIC.
  systemctl --user mask waybar.service 2>/dev/null || true

  say "Sway + Waybar configured (session appears at login)."
}

install_niri() {
  local pm="$1"
  case "$pm" in
    dnf)
      sudo dnf copr enable -y avengemedia/dms || warn "copr enable failed"
      sudo dnf install -y niri dms matugen
      ;;
    pacman)
      sudo pacman -Syu --needed niri dms-shell-niri matugen xwayland-satellite \
        xdg-desktop-portal-gnome xdg-desktop-portal-gtk
      ;;
  esac
  backup_and_copy "$RICE/niri" "$CFG/niri"
  if command -v systemctl >/dev/null 2>&1 && command -v dms >/dev/null 2>&1; then
    systemctl --user add-wants niri.service dms 2>/dev/null || true
  fi
  say "niri + DankMaterialShell configured."
}

backup_and_copy() {
  local src="$1" dst="$2"
  mkdir -p "$dst"
  for f in "$src"/*; do
    local base; base="$(basename "$f")"
    if [ -e "$dst/$base" ] && ! cmp -s "$f" "$dst/$base"; then
      cp -a "$dst/$base" "$dst/$base.bak.$(date +%Y%m%d-%H%M%S)"
    fi
    cp -a "$f" "$dst/$base"
  done
  say "Installed $(basename "$src") -> $dst"
}

# ---- run --------------------------------------------------------------------

pm="$(detect_pm)"
say "Detected package manager: $pm"
preflight_login_screen

case "$pm" in
  apt|zypper) stack=sway ;;
  dnf|pacman) stack=niri ;;
  *)          stack=sway ;;
esac

case "${1:-all}" in
  configs)
    if [ "$stack" = sway ]; then
      backup_and_copy "$RICE/sway" "$CFG/sway"; backup_and_copy "$RICE/waybar" "$CFG/waybar"
      backup_and_copy "$RICE/mako" "$CFG/mako"; backup_and_copy "$RICE/wofi" "$CFG/wofi"
    else
      backup_and_copy "$RICE/niri" "$CFG/niri"
    fi
    ;;
  all)
    case "$stack" in
      sway) install_sway "$pm" ;;
      niri) install_niri "$pm" ;;
    esac
    ;;
  *) echo "usage: $0 [all|configs]"; exit 1 ;;
esac

cat <<EOF

Done. Next:
  1. Log out and pick the "$stack" session at the login screen to try the rice.
  2. Dream OS wallpaper/fonts come from the theme install (just identity).
  3. The rice never disables your login - COSMIC stays as the fallback session.
     If you ever drop to a TTY:  sudo bash "$REPO/scripts/restore-login-screen.sh"
EOF
