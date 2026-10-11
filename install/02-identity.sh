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
  papirus-folders -C grey --theme Papirus-Dark  >/dev/null 2>&1 || true
  papirus-folders -C grey --theme Papirus-Light >/dev/null 2>&1 || true
  printf '"Papirus-Dark"\n' > "$TK/icon_theme"
  gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark' 2>/dev/null || true
  echo "Icons set to Papirus-Dark (grey folders)."
else
  echo "Papirus not installed yet. Run: sudo bash install/00-system-apt.sh"
fi

# ---- terminal/code font (SF Mono if present) -------------------------------
if fc-list 2>/dev/null | grep -qi 'SF Mono'; then
  cat > "$TK/monospace_font" <<'EOF'
(
    family: "SF Mono",
    weight: Normal,
    stretch: Normal,
    style: Normal,
)
EOF
  echo "Monospace font set to SF Mono."
else
  echo "SF Mono not found; see docs/fonts.md (JetBrains Mono NF is the fallback)."
fi

echo "Phase 2 done."
