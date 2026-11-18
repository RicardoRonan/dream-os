#!/usr/bin/env bash
# Dream OS - build a local cosmic-panel with an invisible auto-hide handle.
#
# The stock panel exposes `handle_size` pixels of the dock when it is hidden.
# Those pixels are both the hover target and the visible strip. This patch keeps
# the hover target but makes the hidden strip transparent, so the dock does not
# paint a tab over the window behind it.
#
# The patch is pinned to the cosmic-panel commit shipped in COSMIC 1.11.0.
# Re-run install after a cosmic-panel update.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PATCH="$ROOT/patches/cosmic-panel-invisible-handle.patch"
COMMIT="160a951c8c050a327bb04a7ca22d62e573338c90"
VERSION="1.11.0"
SRC="${XDG_CACHE_HOME:-$HOME/.cache}/dream-os/cosmic-panel"
LOG="${XDG_CACHE_HOME:-$HOME/.cache}/dream-os/cosmic-panel-build.log"
BIN="$HOME/.local/bin/cosmic-panel"
DOCK="$HOME/.config/cosmic/com.system76.CosmicPanel.Dock/v1"

say() { printf '%s\n' "$*"; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }

panel_pid() {
  pgrep -x cosmic-panel | head -1
}

panel_exe() {
  local pid
  pid="$(panel_pid)"
  [ -n "$pid" ] && readlink -f "/proc/$pid/exe" 2>/dev/null || true
}

restart_panel() {
  pkill -x cosmic-panel 2>/dev/null || true
  for _ in $(seq 1 50); do
    [ -z "$(panel_pid)" ] && break
    sleep 0.1
  done
  for _ in $(seq 1 50); do
    [ -n "$(panel_pid)" ] && break
    sleep 0.1
  done
  sleep 1
}

apply_handle() {
  bash "$ROOT/scripts/appearance.sh" panel >/dev/null
}

check_version() {
  command -v dpkg-query >/dev/null 2>&1 || return 0
  local installed
  installed="$(dpkg-query -W -f='${Version}' cosmic-panel 2>/dev/null || true)"
  case "$installed" in
    "$VERSION"*) ;;
    "") ;;
    *) die "cosmic-panel is $installed; the patch is pinned to $VERSION. Rebase patches/cosmic-panel-invisible-handle.patch first." ;;
  esac
}

fetch_source() {
  command -v git >/dev/null 2>&1 || die "git is required"
  if [ ! -d "$SRC/.git" ]; then
    rm -rf "$SRC"
    git clone --filter=blob:none https://github.com/pop-os/cosmic-panel "$SRC" >/dev/null
  fi
  git -C "$SRC" fetch --depth 1 origin "$COMMIT" >/dev/null
  git -C "$SRC" checkout -q -f FETCH_HEAD
}

build_panel() {
  command -v cargo >/dev/null 2>&1 || die "cargo is required (rustup default stable)"
  fetch_source
  git -C "$SRC" apply --check "$PATCH" 2>/dev/null \
    || die "patch does not apply to $COMMIT; update patches/cosmic-panel-invisible-handle.patch"
  git -C "$SRC" apply "$PATCH"

  mkdir -p "$(dirname "$LOG")"
  say "Building cosmic-panel $VERSION (about 3 minutes)..."
  if ! cargo build --release -p cosmic-panel-bin --manifest-path "$SRC/Cargo.toml" >"$LOG" 2>&1; then
    tail -30 "$LOG" >&2
    die "build failed; full log: $LOG"
  fi
  [ -x "$SRC/target/release/cosmic-panel" ] || die "build produced no binary"
  mkdir -p "$(dirname "$BIN")"
  install -m755 "$SRC/target/release/cosmic-panel" "$BIN"
}

install_panel() {
  check_version
  build_panel
  apply_handle
  restart_panel
  say "panel: $(panel_exe)"
  say "dock handle: $(grep -o 'handle_size: [0-9]*' "$DOCK/autohide_behavior" 2>/dev/null || echo unknown)"
  say "Installed. The strip is invisible but still receives pointer input."
  say "Remove with: just panel-handle-off"
}

remove_panel() {
  rm -f "$BIN"
  apply_handle
  restart_panel
  say "panel: $(panel_exe)"
  say "dock handle: $(grep -o 'handle_size: [0-9]*' "$DOCK/autohide_behavior" 2>/dev/null || echo unknown)"
  say "Restored the stock panel and the visible 8px handle."
}

status_panel() {
  say "patched binary: $([ -x "$BIN" ] && echo "$BIN" || echo missing)"
  say "running panel:  $(panel_exe)"
  say "dock handle:    $(grep -o 'handle_size: [0-9]*' "$DOCK/autohide_behavior" 2>/dev/null || echo unknown)"
  command -v dpkg-query >/dev/null 2>&1 \
    && say "package version: $(dpkg-query -W -f='${Version}' cosmic-panel 2>/dev/null || true)"
}

case "${1:-status}" in
  install) install_panel ;;
  remove) remove_panel ;;
  status) status_panel ;;
  *) echo "usage: panel-handle.sh [install|remove|status]" >&2; exit 2 ;;
esac
