#!/usr/bin/env bash
# Dream OS - build a local cosmic-app-library with a subtle open animation.
#
# COSMIC 1.11 shows the App Library instantly. This patch adds a 200ms ease-out
# fade and upward slide when the reserved layer surface opens.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PATCH="$ROOT/patches/cosmic-app-library-open-animation.patch"
COMMIT="90c399d882e7ea7f03e344e88caac5034e4ea94c"
SRC="${XDG_CACHE_HOME:-$HOME/.cache}/dream-os/cosmic-app-library"
LOG="${XDG_CACHE_HOME:-$HOME/.cache}/dream-os/cosmic-app-library-build.log"
BIN="$HOME/.local/bin/cosmic-app-library"
MARKER="${XDG_DATA_HOME:-$HOME/.local/share}/dream-os/app-library-animation"

say() { printf '%s\n' "$*"; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }

check_version() {
  command -v dpkg-query >/dev/null 2>&1 || return 0
  local installed
  installed="$(dpkg-query -W -f='${Version}' cosmic-app-library 2>/dev/null || true)"
  case "$installed" in
    *"${COMMIT:0:7}"*) ;;
    "") ;;
    *) die "cosmic-app-library is $installed, patch is pinned to $COMMIT. Rebase the patch first." ;;
  esac
}

fetch_source() {
  command -v git >/dev/null 2>&1 || die "git is required"
  if [ ! -d "$SRC/.git" ]; then
    rm -rf "$SRC"
    git clone --filter=blob:none https://github.com/pop-os/cosmic-app-library.git "$SRC" >/dev/null
  fi
  git -C "$SRC" fetch --depth 1 origin "$COMMIT" >/dev/null
  git -C "$SRC" checkout -q -f FETCH_HEAD
}

build_app_library() {
  command -v cargo >/dev/null 2>&1 || die "cargo is required (rustup default stable)"
  fetch_source
  git -C "$SRC" apply --unidiff-zero --check "$PATCH" 2>/dev/null \
    || die "patch does not apply to $COMMIT; update patches/cosmic-app-library-open-animation.patch"
  git -C "$SRC" apply --unidiff-zero "$PATCH"

  mkdir -p "$(dirname "$LOG")"
  say "Building cosmic-app-library (about 3 minutes)..."
  if ! cargo build --release --locked -p cosmic-app-library --manifest-path "$SRC/Cargo.toml" >"$LOG" 2>&1; then
    tail -30 "$LOG" >&2
    die "build failed; full log: $LOG"
  fi
  [ -x "$SRC/target/release/cosmic-app-library" ] || die "build produced no binary"
  mkdir -p "$(dirname "$BIN")"
  # Rename over a running binary instead of failing with ETXTBSY.
  install -m755 "$SRC/target/release/cosmic-app-library" "$BIN.new"
  mv -f "$BIN.new" "$BIN"
  mkdir -p "$(dirname "$MARKER")"
  printf '%s\n' "$COMMIT" >"$MARKER"
}

restart_app_library() {
  pkill -f '^cosmic-app-library$' 2>/dev/null || true
  sleep 2
  if pgrep -f '^cosmic-app-library$' >/dev/null 2>&1; then
    say "cosmic-app-library restarted."
  else
    say "cosmic-app-library is not running; it will start on the next Super+A."
  fi
}

install_animation() {
  check_version
  build_app_library
  restart_app_library
  say "Installed: $BIN"
  say "App Library opens now use a 200ms fade and upward slide."
}

remove_animation() {
  rm -f "$BIN" "$MARKER"
  restart_app_library
  say "Removed the local cosmic-app-library override."
}

status_animation() {
  say "patched binary: $([ -x "$BIN" ] && echo "$BIN" || echo missing)"
  say "marker:         $([ -f "$MARKER" ] && echo "$MARKER" || echo missing)"
  say "running exe:    $(readlink -f /proc/$(pgrep -f '^cosmic-app-library$' | head -1)/exe 2>/dev/null || echo not running)"
  command -v dpkg-query >/dev/null 2>&1 \
    && say "package:        $(dpkg-query -W -f='${Version}' cosmic-app-library 2>/dev/null || true)"
}

case "${1:-status}" in
  install) install_animation ;;
  remove) remove_animation ;;
  status) status_animation ;;
  *) echo "usage: app-library-open-animation.sh [install|remove|status]" >&2; exit 2 ;;
esac
