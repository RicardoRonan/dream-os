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

# ---- panel placement (small toggles in the menu bar) -----------------------
if [ -f "$PANEL/plugins_wings" ]; then
  cp -a "$PANEL" "$PANEL.bak.$(date +%Y%m%d-%H%M%S)"
  cat > "$PANEL/plugins_wings" <<'EOF'
Some((
    [
        "dev.cappsy.CosmicExtAppletLogoMenu",
        "com.system76.CosmicPanelWorkspacesButton",
        "io.github.cosmic_utils.cosmic-ext-applet-clipboard-manager",
    ],
    [
        "com.system76.CosmicAppletStatusArea",
        "com.system76.CosmicAppletBattery",
        "com.system76.CosmicAppletNotifications",
    ],
))
EOF
  echo "Panel decluttered: Logo Menu added; utility applets folded out of the bar."
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
  libinput-gestures-setup restart >/dev/null 2>&1 || true
  echo "libinput-gestures configured and (re)started."
else
  echo "libinput-gestures not installed yet (sudo bash install/00-system-apt.sh)."
fi

pkill -x cosmic-panel 2>/dev/null || true
echo "Phase 4 done. Hot corners: see docs/features.md (needs a Rust build)."
