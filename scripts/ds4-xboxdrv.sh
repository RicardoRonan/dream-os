#!/usr/bin/env bash
# Dream OS - install the DualShock 4 -> virtual Xbox 360 pad bridge.
#
# ds4-xboxdrv.sh keeps a virtual Microsoft Xbox 360 pad available whenever the
# DS4 is connected, so every game, native or Proton, sees a standard
# controller. The DS4 keeps priority; when it disconnects the virtual pad
# stays until the DS4 is back, so games do not lose the device mid-session.
#
# Requires the xboxdrv binary:  sudo apt install -y xboxdrv
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ASSET="$ROOT/assets/ds4-xboxdrv"
BIN="$HOME/.local/bin/ds4-xboxdrv.sh"
UNIT="$HOME/.config/systemd/user/ds4-xboxdrv.service"

say() { printf '%s\n' "$*"; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }

check_xboxdrv() {
  command -v xboxdrv >/dev/null 2>&1 || die "xboxdrv is required (sudo apt install -y xboxdrv)"
}

install_unit() {
  mkdir -p "$(dirname "$UNIT")"
  install -m755 "$ASSET/ds4-xboxdrv.sh" "$BIN"

  cat > "$UNIT" <<'EOF'
[Unit]
Description=Dream OS DS4 to virtual Xbox 360 pad bridge
PartOf=graphical-session.target

[Service]
Type=simple
ExecStart=%h/.local/bin/ds4-xboxdrv.sh
Restart=always
RestartSec=5

[Install]
WantedBy=graphical-session.target
EOF

  if command -v systemctl >/dev/null 2>&1 && systemctl --user show-environment >/dev/null 2>&1; then
    systemctl --user daemon-reload
    systemctl --user enable --now ds4-xboxdrv.service
    say "ds4-xboxdrv installed and running."
  else
    say "ds4-xboxdrv installed; log in to start ds4-xboxdrv.service."
  fi
  say "Windows controls: BTN_SOUTH=a BTN_EAST=b BTN_NORTH=y BTN_WEST=x (see assets/ds4-xboxdrv/ds4-xboxdrv.sh)."
}

remove_unit() {
  pkill -f ds4-xboxdrv.sh 2>/dev/null || true
  if command -v systemctl >/dev/null 2>&1 && systemctl --user show-environment >/dev/null 2>&1; then
    systemctl --user disable --now ds4-xboxdrv.service 2>/dev/null || true
  fi
  rm -f "$UNIT" "$BIN"
  say "ds4-xboxdrv removed."
}

status_xboxdrv() {
  say "binary: $([ -x "$BIN" ] && echo "$BIN" || echo missing)"
  say "unit: $(systemctl --user is-active ds4-xboxdrv.service 2>/dev/null || echo unknown)"
  say "xboxdrv: $(pgrep -c -f 'xboxdrv --evdev' 2>/dev/null || echo none) running"
}

case "${1:-status}" in
  install) check_xboxdrv; install_unit ;;
  remove) remove_unit ;;
  status) status_xboxdrv ;;
  *) echo "usage: ds4-xboxdrv.sh [install|remove|status]" >&2; exit 2 ;;
esac
