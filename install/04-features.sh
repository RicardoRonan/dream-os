#!/usr/bin/env bash
# Dream OS - Phase 4: features.
# Utility applets (flatpak), 3-finger gestures, panel placement.
# User-space only. Idempotent. Hot corners need a Rust build (see docs).
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CFG="$HOME/.config"
PANEL="$CFG/cosmic/com.system76.CosmicPanel.Panel/v1"

# ---- utility applets (flatpak, cosmic remote) ------------------------------
APPLETS=(
  dev.cappsy.CosmicExtAppletLogoMenu
  com.github.codevardhan.caffeine-applet
  io.github.cosmic_utils.sysinfo-applet
  dev.DBrox.CosmicPrivacyIndicator
  com.github.bgub.CosmicExtAppletPomodoro
)
if command -v flatpak >/dev/null 2>&1; then
  for app in "${APPLETS[@]}"; do
    if flatpak info --user "$app" >/dev/null 2>&1; then
      echo "applet present: $app"
    else
      echo "installing applet: $app"
      flatpak install -y --user cosmic "$app" >/dev/null 2>&1 || echo "WARN: failed $app" >&2
    fi
  done
fi

# ---- panel placement (single source of truth) ------------------------------
# Wing order and clock position live in scripts/appearance.sh so 03 and 04
# cannot drift apart.
bash "$REPO/scripts/appearance.sh" panel
echo "Panel: Logo Menu + weather left; status cluster and clock right."

# ---- Logo Menu: hamburger "menu button" icon -------------------------------
# The applet is sandboxed, so the SVG must live somewhere it can read (its config dir).
LM="$CFG/cosmic/dev.cappsy.CosmicExtAppletLogoMenu"
if flatpak info --user dev.cappsy.CosmicExtAppletLogoMenu >/dev/null 2>&1; then
  mkdir -p "$LM/v1"
  cp "$REPO/assets/icons/DreamOS/scalable/actions/dream-os-menu-symbolic.svg" \
     "$LM/dream-os-menu-symbolic.svg"
  printf '"Cosmic (Symbolic)"\n' > "$LM/v1/logo"
  echo "true" > "$LM/v1/custom_logo_active"
  printf '"%s"\n' "$LM/dream-os-menu-symbolic.svg" > "$LM/v1/custom_logo_path"
  # kill stale applet instances so the new logo loads on panel restart
  for _p in $(pgrep -f cosmic-ext-applet-logomenu); do kill "$_p" 2>/dev/null || true; done
  echo "Logo Menu set to a hamburger menu-button icon."
fi

# ---- notifications daemon ownership ---------------------------------------
# mako (installed with the rice) is enabled as a user service and claims
# org.freedesktop.Notifications in every graphical session. On COSMIC that
# blocks cosmic-notifications, so the panel never gets the applet fd and the
# bell is missing. The Sway rice starts mako from its own config, so masking
# the user unit is safe.
if command -v systemctl >/dev/null 2>&1 && systemctl --user show-environment >/dev/null 2>&1; then
  if systemctl --user cat mako.service >/dev/null 2>&1; then
    systemctl --user mask --now mako.service >/dev/null 2>&1 \
      && echo "Notifications: masked mako.service (COSMIC owns org.freedesktop.Notifications)."
    # restart the daemon so it can bind the name now that mako is gone
    pkill -x cosmic-notifications 2>/dev/null || true
  fi
fi

# ---- 3-finger gestures (4-finger is native in COSMIC) ----------------------
mkdir -p "$CFG"
cat > "$CFG/libinput-gestures.conf" <<'EOF'
# Dream OS gestures. COSMIC handles 4-finger natively; these add 3-finger.
# Reload: libinput-gestures-setup restart
gesture swipe up 3 cosmic-workspaces
gesture swipe down 3 cosmic-workspaces
EOF
if command -v libinput-gestures-setup >/dev/null 2>&1; then
  libinput-gestures-setup autostart start >/dev/null 2>&1 || true
  if id -nG "$USER" | grep -qw input; then
    libinput-gestures-setup restart >/dev/null 2>&1 || true
    echo "libinput-gestures configured and (re)started."
  else
    echo "3-finger gestures need input group access:"
    echo "  sudo usermod -aG input $USER   # then log out and back in"
  fi
else
  echo "libinput-gestures not installed yet (sudo bash install/00-system-apt.sh)."
fi

# ---- mouse back/forward buttons --------------------------------------------
# User service maps BTN_SIDE/BTN_EXTRA to Alt+Left/Alt+Right. Needs input group.
bash "$REPO/scripts/mouse-buttons.sh" || true

pkill -x cosmic-panel 2>/dev/null || true
echo "Phase 4 done. Hot corners: see docs/features.md (needs a Rust build)."
