#!/usr/bin/env bash
# Dream OS - clearer power/session icons via a small override theme (inherits Papirus).
# User-space only. Idempotent.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="$HOME/.local/share/icons/DreamOS"

rm -rf "$DEST"
mkdir -p "$DEST"
cp -a "$REPO/assets/icons/DreamOS/." "$DEST/"
gtk-update-icon-cache -f -t "$DEST" >/dev/null 2>&1 || true

TK="$HOME/.config/cosmic/com.system76.CosmicTk/v1"
mkdir -p "$TK"
printf '"DreamOS"\n' > "$TK/icon_theme"
gsettings set org.gnome.desktop.interface icon-theme 'DreamOS' 2>/dev/null || true

pkill -x cosmic-panel 2>/dev/null || true
echo "Icon theme set to DreamOS (Papirus + clearer lock/log-out/suspend/reboot/shutdown)."
