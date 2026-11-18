#!/usr/bin/env bash
# Dream OS - map COSMIC app IDs onto WhiteSur squircle icons.
# Creates symlinks inside the DreamOS override theme so the stock COSMIC
# artwork does not leak through. User-space only. Idempotent.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MAP="$REPO/configs/icons/cosmic-app-map.tsv"
DEST="$HOME/.local/share/icons/DreamOS/scalable/apps"
THEME="${WHITESUR_THEME:-WhiteSur-grey-dark}"

find_icon() {
  local name="$1" dir
  for dir in "$HOME/.local/share/icons/$THEME" "/usr/share/icons/$THEME"; do
    [ -d "$dir" ] || continue
    local hit
    hit="$(find "$dir" \( -iname "$name.svg" -o -iname "$name.png" \) -print -quit 2>/dev/null || true)"
    if [ -n "$hit" ]; then
      printf '%s\n' "$hit"
      return 0
    fi
  done
  return 1
}

mkdir -p "$DEST"
[ -f "$MAP" ] || { echo "icon-map: missing $MAP" >&2; exit 1; }

while IFS=$'\t' read -r app target; do
  case "$app" in ''|\#*) continue ;; esac
  src="$(find_icon "$target" || true)"
  if [ -n "$src" ]; then
    ln -sfn "$src" "$DEST/$app.svg"
    echo "icon-map: $app -> $src"
  else
    echo "icon-map: WARN $target not found for $app" >&2
  fi
done < "$MAP"

if [ -d "$HOME/.local/share/icons/DreamOS" ]; then
  gtk-update-icon-cache -f -t "$HOME/.local/share/icons/DreamOS" >/dev/null 2>&1 || true
fi
