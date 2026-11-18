#!/usr/bin/env bash
# Dream OS - install the WhiteSur icon theme (cursors optional).
# WhiteSur is GPL-3.0 and is fetched from upstream rather than vendored.
# Idempotent: existing themes are left alone unless --force is passed.
# Use --icons-only to keep the user's current cursor theme.
set -euo pipefail

FORCE=0
ICONS_ONLY=0
for arg in "$@"; do
  case "$arg" in
    --force) FORCE=1 ;;
    --icons-only) ICONS_ONLY=1 ;;
    *) echo "usage: $0 [--force] [--icons-only]" >&2; exit 2 ;;
  esac
done
DEST="$HOME/.local/share/icons"
TMP="${TMPDIR:-/tmp/opencode}/dream-os-whitesur"

need_icons() {
  [ "$FORCE" = 1 ] || [ ! -d "$DEST/WhiteSur-grey-dark" ]
}
need_cursors() {
  [ "$ICONS_ONLY" = 0 ] || return 1
  [ "$FORCE" = 1 ] || [ ! -d "$DEST/WhiteSur-cursors" ]
}

if ! command -v git >/dev/null 2>&1; then
  echo "install-whitesur: git is required" >&2
  exit 1
fi

mkdir -p "$TMP"
if need_icons; then
  rm -rf "$TMP/WhiteSur-icon-theme"
  echo "install-whitesur: cloning icon theme"
  git clone --depth=1 https://github.com/vinceliuice/WhiteSur-icon-theme.git \
    "$TMP/WhiteSur-icon-theme"
  ( cd "$TMP/WhiteSur-icon-theme" && ./install.sh -t grey -d "$DEST" )
else
  echo "install-whitesur: icons already installed"
fi

if [ "$ICONS_ONLY" = 1 ]; then
  echo "install-whitesur: icons only, keeping the user cursor"
elif need_cursors; then
  rm -rf "$TMP/WhiteSur-cursors"
  echo "install-whitesur: cloning cursor theme"
  git clone --depth=1 https://github.com/vinceliuice/WhiteSur-cursors.git \
    "$TMP/WhiteSur-cursors"
  ( cd "$TMP/WhiteSur-cursors" && ./install.sh )
else
  echo "install-whitesur: cursors already installed"
fi

echo "install-whitesur: done"
