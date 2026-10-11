#!/usr/bin/env bash
# Dream OS - Phase 2: identity (wallpaper, cursors, icons, terminal font).
# User-space only. Idempotent.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CFG="$HOME/.config"
TK="$CFG/cosmic/com.system76.CosmicTk/v1"
mkdir -p "$TK"

# ---- wallpaper -------------------------------------------------------------
BG="$HOME/.local/share/backgrounds/dream-os"
mkdir -p "$BG"
cp "$REPO"/assets/wallpapers/*.svg "$BG/"
CB="$CFG/cosmic/com.system76.CosmicBackground/v1"
mkdir -p "$CB"
cat > "$CB/all" <<EOF
(
    output: "all",
    source: Path("$BG/dream-os-dark.svg"),
    filter_by_theme: false,
    rotation_frequency: 300,
    filter_method: Lanczos,
    scaling_mode: Zoom,
    sampling_method: Alphanumeric,
)
EOF
echo "true" > "$CB/same-on-all"
echo "Wallpaper installed -> $BG (dark active; pick dream-os-light.svg in Settings for light)."

# ---- cursors (Vimix) -------------------------------------------------------
find_cursor() {
  for d in "$HOME/.local/share/icons/Vimix-cursors" "$HOME/.icons/Vimix-cursors"; do
    [ -d "$d" ] && { echo "$d"; return 0; }
  done
  return 1
}
if ! find_cursor >/dev/null; then
  echo "Downloading Vimix cursors..."
  tmp="$(mktemp -d)"
  if curl -fsSL -o "$tmp/vimix.tar.gz" \
      https://github.com/vinceliuice/Vimix-cursors/archive/refs/heads/master.tar.gz; then
    tar xf "$tmp/vimix.tar.gz" -C "$tmp"
    ( cd "$tmp/Vimix-cursors-master" && ./install.sh >/dev/null 2>&1 ) || true
  else
    echo "WARN: could not download Vimix cursors." >&2
  fi
  rm -rf "$tmp"
fi
CURSOR_NAME="Vimix-cursors"
if d="$(find_cursor)"; then CURSOR_NAME="$(basename "$d")"; fi

# environment for Wayland clients (applies on next login)
mkdir -p "$CFG/environment.d"
cat > "$CFG/environment.d/dream-os.conf" <<EOF
XCURSOR_THEME=$CURSOR_NAME
XCURSOR_SIZE=24
EOF
gsettings set org.gnome.desktop.interface cursor-theme "$CURSOR_NAME" 2>/dev/null || true
# Xcursor fallback for Qt/legacy
mkdir -p "$HOME/.icons/default"
cat > "$HOME/.icons/default/index.theme" <<EOF
[Icon Theme]
Inherits=$CURSOR_NAME
EOF
echo "Cursor set to $CURSOR_NAME (log out/in to apply to all apps)."

# ---- icons (Papirus) -------------------------------------------------------
if [ -d /usr/share/icons/Papirus ]; then
  # Recoloring system-wide icons needs root; do it if writable/privileged, else advise.
  if [ "$(id -u)" -eq 0 ] || [ -w /usr/share/icons/Papirus-Dark ]; then
    papirus-folders -C grey --theme Papirus-Dark  >/dev/null 2>&1 || true
    papirus-folders -C grey --theme Papirus-Light >/dev/null 2>&1 || true
  else
    echo "NOTE: run once with sudo to set grey folders:"
    echo "  sudo papirus-folders -C grey --theme Papirus-Dark && sudo papirus-folders -C grey --theme Papirus-Light"
  fi
  printf '"Papirus-Dark"\n' > "$TK/icon_theme"
  gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark' 2>/dev/null || true
  echo "Icons set to Papirus-Dark (grey folders)."
else
  echo "Papirus not installed yet. Run: sudo bash install/00-system-apt.sh"
fi

# ---- fonts -----------------------------------------------------------------
# Bundle Inter (SIL OFL) so UI text looks right where SF Pro Text is absent.
if [ -d "$REPO/assets/fonts" ]; then
  mkdir -p "$HOME/.local/share/fonts"
  cp -r "$REPO/assets/fonts/." "$HOME/.local/share/fonts/" 2>/dev/null || true
  fc-cache -f >/dev/null 2>&1 || true
fi

# UI font: keep SF Pro Text if present, otherwise Inter.
UI_FONT="SF Pro Text"
fc-list 2>/dev/null | grep -qi 'SF Pro Text' || UI_FONT="Inter"
cat > "$TK/interface_font" <<EOF
(
    family: "$UI_FONT",
    weight: Normal,
    stretch: Normal,
    style: Normal,
)
EOF
echo "Interface font: $UI_FONT."

# Monospace: SF Mono if present, else JetBrains Mono NF, else system mono.
MONO_FONT="monospace"
if fc-list 2>/dev/null | grep -qi 'SF Mono'; then
  MONO_FONT="SF Mono"
elif fc-list 2>/dev/null | grep -qi 'JetBrainsMono Nerd'; then
  MONO_FONT="JetBrainsMono Nerd Font"
fi
cat > "$TK/monospace_font" <<EOF
(
    family: "$MONO_FONT",
    weight: Normal,
    stretch: Normal,
    style: Normal,
)
EOF
echo "Monospace font: $MONO_FONT."

echo "Phase 2 done."
