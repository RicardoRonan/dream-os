#!/usr/bin/env bash
# Dream OS - keep GTK 3/4 corner radii on the 16px theme token.
#
# COSMIC rewrites ~/.config/gtk-{3,4}.0/gtk.css whenever the theme or accent
# changes, and those files only contain colours. This script appends a marked
# override block and can install a systemd user timer that re-applies it after
# a rewrite. User-space only. Idempotent.
#
# Usage:
#   scripts/gtk-radius.sh apply          # append/update the block
#   scripts/gtk-radius.sh install-watch  # apply + install the path unit
#   scripts/gtk-radius.sh remove         # drop the block and the unit
set -euo pipefail

SELF="$(readlink -f "${BASH_SOURCE[0]}")"
HERE="$(dirname "$SELF")"
if [ -f "$HERE/gtk-radius.css" ]; then
  CSS="$HERE/gtk-radius.css"
else
  CSS="$(cd "$HERE/.." && pwd)/configs/gtk/gtk-radius.css"
fi

BEGIN='/* >>> dream-os-radius (managed by scripts/gtk-radius.sh) >>> */'
END='/* <<< dream-os-radius <<< */'
TARGETS=(
  "$HOME/.config/gtk-3.0/gtk.css"
  "$HOME/.config/gtk-4.0/gtk.css"
)
UNIT_DIR="$HOME/.config/systemd/user"
STATE_DIR="$HOME/.local/share/dream-os"
QUIET=0

say() { [ "$QUIET" = 1 ] || printf '%s\n' "$*"; }

strip_block() {
  awk -v b="$BEGIN" -v e="$END" '
    $0 == b { skip = 1; next }
    $0 == e { skip = 0; next }
    !skip
  ' "$1"
}

apply_one() {
  local file="$1" current stripped body expected
  mkdir -p "$(dirname "$file")"
  touch "$file"

  body="$(cat "$CSS")"
  current="$(cat "$file")"
  stripped="$(strip_block "$file")"

  if [ -n "$stripped" ]; then
    expected="$(printf '%s\n\n%s\n%s\n%s' "$stripped" "$BEGIN" "$body" "$END")"
  else
    expected="$(printf '%s\n%s\n%s' "$BEGIN" "$body" "$END")"
  fi

  if [ "$expected" = "$current" ]; then
    return 0
  fi
  printf '%s\n' "$expected" > "$file"
  say "gtk-radius: updated $file"
}

apply_all() {
  [ -f "$CSS" ] || { echo "gtk-radius: missing $CSS" >&2; exit 1; }
  local f
  for f in "${TARGETS[@]}"; do
    apply_one "$f"
  done
}

install_watch() {
  mkdir -p "$UNIT_DIR" "$STATE_DIR"
  cp -f "$SELF" "$STATE_DIR/gtk-radius.sh"
  cp -f "$CSS" "$STATE_DIR/gtk-radius.css"
  chmod +x "$STATE_DIR/gtk-radius.sh"

  cat > "$UNIT_DIR/dream-os-gtk-radius.service" <<'EOF'
[Unit]
Description=Dream OS - restore GTK corner radii

[Service]
Type=oneshot
ExecStart=/usr/bin/env bash %h/.local/share/dream-os/gtk-radius.sh apply --quiet
EOF

  # A timer, not a path unit. The path unit watched the same files the service
  # writes, which could hit systemd's start limit and leave the block missing.
  cat > "$UNIT_DIR/dream-os-gtk-radius.timer" <<'EOF'
[Unit]
Description=Dream OS - periodically restore GTK corner radii

[Timer]
OnBootSec=1min
OnUnitActiveSec=2min
Unit=dream-os-gtk-radius.service

[Install]
WantedBy=timers.target
EOF

  if command -v systemctl >/dev/null 2>&1 && systemctl --user show-environment >/dev/null 2>&1; then
    systemctl --user daemon-reload
    systemctl --user disable --now dream-os-gtk-radius.path 2>/dev/null || true
    rm -f "$UNIT_DIR/dream-os-gtk-radius.path"
    systemctl --user enable --now dream-os-gtk-radius.timer
    say "gtk-radius: timer enabled (dream-os-gtk-radius.timer)"
  else
    say "gtk-radius: no user systemd session; run 'scripts/gtk-radius.sh apply' after theme changes"
  fi
}

remove_all() {
  local f
  for f in "${TARGETS[@]}"; do
    [ -f "$f" ] || continue
    local stripped
    stripped="$(strip_block "$f")"
    printf '%s\n' "$stripped" > "$f"
    say "gtk-radius: cleaned $f"
  done
  if command -v systemctl >/dev/null 2>&1 && systemctl --user show-environment >/dev/null 2>&1; then
    systemctl --user disable --now dream-os-gtk-radius.path 2>/dev/null || true
    systemctl --user disable --now dream-os-gtk-radius.timer 2>/dev/null || true
    systemctl --user daemon-reload
  fi
  rm -f "$UNIT_DIR/dream-os-gtk-radius.path" "$UNIT_DIR/dream-os-gtk-radius.timer" "$UNIT_DIR/dream-os-gtk-radius.service"
  rm -f "$STATE_DIR/gtk-radius.sh" "$STATE_DIR/gtk-radius.css"
  rmdir "$STATE_DIR" 2>/dev/null || true
  say "gtk-radius: watch removed"
}

cmd="apply"
for arg in "$@"; do
  case "$arg" in
    --quiet|-q) QUIET=1 ;;
    apply|install-watch|remove) cmd="$arg" ;;
    *) echo "gtk-radius: unknown argument: $arg" >&2; exit 2 ;;
  esac
done

case "$cmd" in
  apply) apply_all ;;
  install-watch) apply_all; install_watch ;;
  remove) remove_all ;;
esac
