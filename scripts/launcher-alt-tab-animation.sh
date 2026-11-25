#!/usr/bin/env bash
# Dream OS - build a local cosmic-launcher with subtle open and Alt+Tab animations.
#
# COSMIC 1.11 shows both surfaces instantly. This patch adds a 200ms ease-out
# fade and upward slide for normal opens, and keeps the 140ms Alt+Tab settle.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PATCH="$ROOT/patches/cosmic-launcher-alt-tab-animation.patch"
COMMIT="29c1bac5e8f9f83b9e2cef03bb0259a04ffd7f2a"
SRC="${XDG_CACHE_HOME:-$HOME/.cache}/dream-os/cosmic-launcher"
LOG="${XDG_CACHE_HOME:-$HOME/.cache}/dream-os/cosmic-launcher-build.log"
BIN="$HOME/.local/bin/cosmic-launcher"
MARKER="${XDG_DATA_HOME:-$HOME/.local/share}/dream-os/launcher-animation"

say() { printf '%s\n' "$*"; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }

check_version() {
  command -v dpkg-query >/dev/null 2>&1 || return 0
  local installed
  installed="$(dpkg-query -W -f='${Version}' cosmic-launcher 2>/dev/null || true)"
  case "$installed" in
    *"${COMMIT:0:7}"*) ;;
    "") ;;
    *) die "cosmic-launcher is $installed, patch is pinned to $COMMIT. Rebase the patch first." ;;
  esac
}

fetch_source() {
  command -v git >/dev/null 2>&1 || die "git is required"
  if [ ! -d "$SRC/.git" ]; then
    rm -rf "$SRC"
    git clone --filter=blob:none https://github.com/pop-os/cosmic-launcher "$SRC" >/dev/null
  fi
  git -C "$SRC" fetch --depth 1 origin "$COMMIT" >/dev/null
  git -C "$SRC" checkout -q -f FETCH_HEAD
}

build_launcher() {
  command -v cargo >/dev/null 2>&1 || die "cargo is required (rustup default stable)"
  fetch_source
  git -C "$SRC" apply --unidiff-zero --check "$PATCH" 2>/dev/null \
    || die "patch does not apply to $COMMIT; update patches/cosmic-launcher-alt-tab-animation.patch"
  git -C "$SRC" apply --unidiff-zero "$PATCH"

  mkdir -p "$(dirname "$LOG")"
  say "Building cosmic-launcher (about 3 minutes)..."
  if ! cargo build --release --locked -p cosmic-launcher --manifest-path "$SRC/Cargo.toml" >"$LOG" 2>&1; then
    tail -30 "$LOG" >&2
    die "build failed; full log: $LOG"
  fi
  [ -x "$SRC/target/release/cosmic-launcher" ] || die "build produced no binary"
  mkdir -p "$(dirname "$BIN")"
  # Rename over a running binary instead of failing with ETXTBSY.
  install -m755 "$SRC/target/release/cosmic-launcher" "$BIN.new"
  mv -f "$BIN.new" "$BIN"
  mkdir -p "$(dirname "$MARKER")"
  printf '%s\n' "$COMMIT" >"$MARKER"
}

restart_launcher() {
  pkill -x cosmic-launcher 2>/dev/null || true
  sleep 2
  if pgrep -x cosmic-launcher >/dev/null 2>&1; then
    say "cosmic-launcher restarted."
  else
    say "cosmic-launcher is not running; it will start on the next Super or Alt+Tab."
  fi
}

install_animation() {
  check_version
  build_launcher
  restart_launcher
  say "Installed: $BIN"
  say "Launcher opens use a 200ms fade and upward slide. Alt+Tab keeps its 140ms settle."
}

remove_animation() {
  rm -f "$BIN" "$MARKER"
  restart_launcher
  say "Removed the local cosmic-launcher override."
}

status_animation() {
  say "patched binary: $([ -x "$BIN" ] && echo "$BIN" || echo missing)"
  say "marker:         $([ -f "$MARKER" ] && echo "$MARKER" || echo missing)"
  say "running exe:    $(readlink -f /proc/$(pgrep -x cosmic-launcher | head -1)/exe 2>/dev/null || echo unknown)"
  command -v dpkg-query >/dev/null 2>&1 \
    && say "package:        $(dpkg-query -W -f='${Version}' cosmic-launcher 2>/dev/null || true)"
}

case "${1:-status}" in
  install) install_animation ;;
  remove) remove_animation ;;
  status) status_animation ;;
  *) echo "usage: launcher-alt-tab-animation.sh [install|remove|status]" >&2; exit 2 ;;
esac
