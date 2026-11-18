#!/usr/bin/env bash
# Dream OS - install the WhiteSur icon and cursor themes (user-space).
# WhiteSur is GPL-3.0 and is fetched from upstream rather than vendored.
# Idempotent: existing themes are left alone unless --force is passed.
set -euo pipefail

FORCE=0
[ "${1:-}" = "--force" ] && FORCE=1
DEST="$HOME/.local/share/icons"
TMP="${TMPDIR:-/tmp/opencode}/dream-os-whitesur"

need_icons() {
  [ "$FORCE" = 1 ] || [ ! -d "$DEST/WhiteSur-grey-dark" ]
}
need_cursors() {
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

if need_cursors; then
  rm -rf "$TMP/WhiteSur-cursors"
  echo "install-whitesur: cloning cursor theme"
  git clone --depth=1 https://github.com/vinceliuice/WhiteSur-cursors.git \
    "$TMP/WhiteSur-cursors"
  ( cd "$TMP/WhiteSur-cursors" && ./install.sh )
else
  echo "install-whitesur: cursors already installed"
fi

echo "install-whitesur: done"
