#!/usr/bin/env bash
# Dream OS - Phase 5: cross-app sync (GTK/Qt/cursor/icons).
# COSMIC auto-exports GTK colours + Qt + button-layout; this sets the fonts
# and confirms toolkit settings. User-space only. Idempotent.
set -euo pipefail

# ---- GTK font + cursor + theme --------------------------------------------
gtk_ini() {
  local dir="$1"
  mkdir -p "$dir"
  local icon="Adwaita"
  [ -d /usr/share/icons/Papirus ] && icon="Papirus-Dark"
  cat > "$dir/settings.ini" <<EOF
[Settings]
gtk-font-name=SF Pro Text 11
gtk-cursor-theme-name=Vimix-cursors
gtk-icon-theme-name=$icon
gtk-theme-name=Adwaita
gtk-application-prefer-dark-theme=1
EOF
}
gtk_ini "$HOME/.config/gtk-3.0"
gtk_ini "$HOME/.config/gtk-4.0"

# ---- gsettings (GTK apps) --------------------------------------------------
gsettings set org.gnome.desktop.interface font-name 'SF Pro Text 11' 2>/dev/null || true
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
gsettings set org.gnome.desktop.interface cursor-theme 'Vimix-cursors' 2>/dev/null || true
if [ -d /usr/share/icons/Papirus ]; then
  gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark' 2>/dev/null || true
fi

# ---- Qt platform theme -----------------------------------------------------
envf="$HOME/.config/environment.d/dream-os.conf"
grep -q QT_QPA_PLATFORMTHEME "$envf" 2>/dev/null || \
  echo "QT_QPA_PLATFORMTHEME=qt5ct" >> "$envf"

echo "Phase 5 done. COSMIC exports GTK/Qt colours automatically; fonts now set."
echo "Note: Pop!_OS 24.04 ships old qt5ct/qt6ct, so Qt apps may need manual colour tuning."
