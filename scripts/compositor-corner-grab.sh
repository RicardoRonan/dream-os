#!/usr/bin/env bash
# Dream OS - build a local cosmic-comp with wider window corner grab zones.
#
# Stock COSMIC 1.11 hardcodes a 10px resize border and has no setting for the
# corner hit area. This patch keeps the border at 10px but extends each corner
# zone 28px along the edges, so the diagonal resize cursor appears earlier.
#
# This replaces the compositor on the next login. Keep a TTY available.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PATCH="$ROOT/patches/cosmic-comp-corner-grab.patch"
COMMIT="6968c5d81901f110911aaa526af1a46fc9f360ed"
VERSION="1.11.0"
SRC="${XDG_CACHE_HOME:-$HOME/.cache}/dream-os/cosmic-comp"
LOG="${XDG_CACHE_HOME:-$HOME/.cache}/dream-os/cosmic-comp-build.log"
BIN="$HOME/.local/bin/cosmic-comp"

say() { printf '%s\n' "$*"; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }

check_version() {
  command -v dpkg-query >/dev/null 2>&1 || return 0
  local installed
  installed="$(dpkg-query -W -f='${Version}' cosmic-comp 2>/dev/null || true)"
  case "$installed" in
    *"$COMMIT"*) ;;
    "") ;;
    *) die "cosmic-comp is $installed, patch is pinned to commit $COMMIT. Rebase the patch first." ;;
  esac
}

fetch_source() {
  command -v git >/dev/null 2>&1 || die "git is required"
  if [ ! -d "$SRC/.git" ]; then
    rm -rf "$SRC"
    git clone --filter=blob:none https://github.com/pop-os/cosmic-comp "$SRC" >/dev/null
  fi
  git -C "$SRC" fetch --depth 1 origin "$COMMIT" >/dev/null
  git -C "$SRC" checkout -q -f FETCH_HEAD
}

build_compositor() {
  command -v cargo >/dev/null 2>&1 || die "cargo is required (rustup default stable)"
  fetch_source
  git -C "$SRC" apply --check "$PATCH" 2>/dev/null \
    || die "patch does not apply to $COMMIT; update patches/cosmic-comp-corner-grab.patch"
  git -C "$SRC" apply "$PATCH"

  mkdir -p "$(dirname "$LOG")"
  say "Building cosmic-comp $VERSION (about 7 minutes)..."
  if ! cargo build --release -p cosmic-comp --manifest-path "$SRC/Cargo.toml" >"$LOG" 2>&1; then
    tail -30 "$LOG" >&2
    die "build failed; install libseat-dev libdisplay-info-dev libegl-dev libgles-dev and see $LOG"
  fi
  [ -x "$SRC/target/release/cosmic-comp" ] || die "build produced no binary"
  mkdir -p "$(dirname "$BIN")"
  install -m755 "$SRC/target/release/cosmic-comp" "$BIN"
}

install_patch() {
  check_version
  build_compositor
  say "Installed: $BIN"
  say "The current session is still using the running compositor."
  say "Log out and back in to apply it."
  say ""
  say "If the session fails to start, switch to a TTY (Ctrl+Alt+F3) and run:"
  say "  rm -f $BIN"
  say "Then log back in or reboot."
}

remove_patch() {
  rm -f "$BIN"
  say "Removed: $BIN"
  say "Log out and back in to return to the stock compositor."
}

status_patch() {
  say "patched binary: $([ -x "$BIN" ] && echo "$BIN" || echo missing)"
  say "running exe:    $(readlink -f /proc/$(pgrep -x cosmic-comp | head -1)/exe 2>/dev/null || echo unknown)"
  command -v dpkg-query >/dev/null 2>&1 \
    && say "package:        $(dpkg-query -W -f='${Version}' cosmic-comp 2>/dev/null || true)"
}

case "${1:-status}" in
  install) install_patch ;;
  remove) remove_patch ;;
  status) status_patch ;;
  *) echo "usage: compositor-corner-grab.sh [install|remove|status]" >&2; exit 2 ;;
esac
