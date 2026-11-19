#!/usr/bin/env bash
# Dream OS - Phase 5: cross-app sync (GTK/Qt/cursor/icons).
# COSMIC auto-exports GTK colours + Qt + button-layout; this sets the fonts
# and confirms toolkit settings. User-space only. Idempotent.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# ---- GTK / font / cursor / icon sync (single source of truth) --------------
# appearance.sh owns the values; this phase only applies them to GTK/Qt and
# installs the timer that keeps the radius block after COSMIC rewrites gtk.css.
bash "$ROOT/scripts/appearance.sh" tk
bash "$ROOT/scripts/appearance.sh" gtk
bash "$ROOT/scripts/appearance.sh" cursor
bash "$ROOT/scripts/gtk-radius.sh" install-watch --quiet
bash "$ROOT/scripts/appearance.sh" install-sync
bash "$ROOT/scripts/bt-sbc-xq.sh" install

# ---- Qt platform theme -----------------------------------------------------
envf="$HOME/.config/environment.d/dream-os.conf"
grep -q QT_QPA_PLATFORMTHEME "$envf" 2>/dev/null || \
  echo "QT_QPA_PLATFORMTHEME=qt5ct" >> "$envf"

echo "Phase 5 done. COSMIC exports GTK/Qt colours automatically; fonts now set."
echo "Note: Pop!_OS 24.04 ships old qt5ct/qt6ct, so Qt apps may need manual colour tuning."
