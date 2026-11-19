#!/usr/bin/env bash
# Dream OS - make one cursor theme available to Xcursor, XWayland and Qt.
#
# Xcursor searches ~/.icons and /usr/share/icons, not ~/.local/share/icons.
# The theme installer drops Vimix in ~/.local/share/icons, so expose it under
# ~/.icons and add the cursor names that Vimix does not ship.
set -euo pipefail

CURSOR="${1:-Vimix-cursors}"
SRC=""
LINKED=0
if [ -d "$HOME/.icons/$CURSOR" ] && [ ! -L "$HOME/.icons/$CURSOR" ]; then
  # A real theme already lives where Xcursor looks. Keep it.
  SRC="$(readlink -f "$HOME/.icons/$CURSOR")"
  LINKED=1
else
  for d in "$HOME/.local/share/icons/$CURSOR" "/usr/share/icons/$CURSOR"; do
    if [ -d "$d" ]; then SRC="$(readlink -f "$d")"; break; fi
  done
fi
if [ -z "$SRC" ] || [ ! -d "$SRC/cursors" ]; then
  echo "cursor-sync: theme not found: $CURSOR" >&2
  exit 1
fi

mkdir -p "$HOME/.icons" "$HOME/.icons/default"

# Xcursor finds the theme by name in ~/.icons.
if [ "$LINKED" = 0 ] && [ "$(readlink -f "$HOME/.icons/$CURSOR" 2>/dev/null || true)" != "$SRC" ]; then
  rm -rf "$HOME/.icons/$CURSOR"
  ln -s "$SRC" "$HOME/.icons/$CURSOR"
fi

# Apps that fall back to the "default" cursor theme get the same look.
if [ ! -e "$HOME/.icons/default/cursors" ] && [ ! -L "$HOME/.icons/default/cursors" ]; then
  ln -s "$SRC/cursors" "$HOME/.icons/default/cursors"
fi
if [ ! -e "$HOME/.icons/default/cursor.theme" ]; then
  cat > "$HOME/.icons/default/cursor.theme" <<EOF
[Icon Theme]
Inherits=$CURSOR
EOF
fi
if [ ! -e "$HOME/.icons/default/index.theme" ]; then
  cat > "$HOME/.icons/default/index.theme" <<EOF
[Icon Theme]
Inherits=$CURSOR
EOF
fi

# Vimix omits a few names that GTK, Qt and drag-and-drop code still request.
# Point them at the matching Vimix artwork instead of letting Xcursor fall back
# to Adwaita for those actions.
aliases=(
  "dnd-link:link"
  "ew-resize:size_hor"
  "ns-resize:size_ver"
  "bd_double_arrow:size_bdiag"
  "fd_double_arrow:size_fdiag"
  "cross_reverse:crosshair"
  "diamond_cross:crosshair"
  "tcross:crosshair"
  "top_left_arrow:left_ptr"
  "question-pointer:help"
)
added=0
if [ -w "$SRC/cursors" ]; then
  for pair in "${aliases[@]}"; do
    dst="${pair%%:*}"; src="${pair#*:}"
    [ -e "$SRC/cursors/$src" ] || continue
    if [ ! -e "$SRC/cursors/$dst" ] && [ ! -L "$SRC/cursors/$dst" ]; then
      ln -s "$src" "$SRC/cursors/$dst"
      added=$((added + 1))
    fi
  done
fi

echo "cursor-sync: $CURSOR -> $HOME/.icons/$CURSOR (aliases added: $added)"
