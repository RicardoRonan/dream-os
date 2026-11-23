#!/usr/bin/env bash
# Dream OS - install the DualShock 4 battery tray.
#
# The tray app is an AppIndicator, shown by Status Hub in the COSMIC panel. It
# reads the controller battery from UPower, adds a low-battery notification,
# and provides Connect/Disconnect controller menu actions.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ASSET="$ROOT/assets/ds4-battery-tray"
BIN="$HOME/.local/bin/ds4-battery-tray"
SCHEMA_DIR="$HOME/.local/share/glib-2.0/schemas"
SCHEMA="$SCHEMA_DIR/io.github.kvaynwahey.Ds4BatteryTray.gschema.xml"
UNIT="$HOME/.config/systemd/user/ds4-battery-tray.service"
AUTOSTART="$HOME/.config/autostart/ds4-battery-tray.desktop"

say() { printf '%s\n' "$*"; }

check_gir() {
  if ! python3 -c 'import gi; gi.require_version("AyatanaAppIndicator3","0.1")' >/dev/null 2>&1; then
    say "Missing Ayatana AppIndicator typelib. Install it with:"
    say "  sudo apt install -y gir1.2-ayatanaappindicator3-0.1"
    exit 1
  fi
}

install_tray() {
  check_gir
  mkdir -p "$HOME/.local/bin" "$SCHEMA_DIR" "$(dirname "$UNIT")"
  install -m755 "$ASSET/ds4-battery-tray.py" "$BIN"
  install -m644 "$ASSET/io.github.kvaynwahey.Ds4BatteryTray.gschema.xml" "$SCHEMA"
  glib-compile-schemas "$SCHEMA_DIR"

  # The service is the single source of startup. Do not keep an XDG duplicate.
  rm -f "$AUTOSTART"

  cat > "$UNIT" <<'EOF'
[Unit]
Description=Dream OS DS4 battery tray
After=graphical-session.target
PartOf=graphical-session.target

[Service]
Type=simple
ExecStart=%h/.local/bin/ds4-battery-tray
Restart=always
RestartSec=5

[Install]
WantedBy=graphical-session.target
EOF

  if command -v systemctl >/dev/null 2>&1 && systemctl --user show-environment >/dev/null 2>&1; then
    systemctl --user daemon-reload
    systemctl --user enable ds4-battery-tray.service
    systemctl --user restart ds4-battery-tray.service
    gsettings --schemadir "$SCHEMA_DIR" set io.github.kvaynwahey.Ds4BatteryTray autostart true 2>/dev/null || true
    say "DS4 tray installed and running."
  else
    say "DS4 tray installed; log in to start ds4-battery-tray.service."
  fi
  say "Low-battery notification: 20%."
}

remove_tray() {
  if command -v systemctl >/dev/null 2>&1 && systemctl --user show-environment >/dev/null 2>&1; then
    systemctl --user disable --now ds4-battery-tray.service 2>/dev/null || true
  fi
  rm -f "$UNIT" "$BIN" "$AUTOSTART"
  rm -f "$SCHEMA"
  [ -d "$SCHEMA_DIR" ] && glib-compile-schemas "$SCHEMA_DIR" 2>/dev/null || true
  say "DS4 tray removed."
}

status_tray() {
  say "binary:  $([ -x "$BIN" ] && echo "$BIN" || echo missing)"
  say "schema:  $([ -f "$SCHEMA" ] && echo "$SCHEMA" || echo missing)"
  if command -v systemctl >/dev/null 2>&1; then
    say "enabled: $(systemctl --user is-enabled ds4-battery-tray.service 2>/dev/null || echo unknown)"
    say "active:  $(systemctl --user is-active ds4-battery-tray.service 2>/dev/null || echo unknown)"
  fi
  say "autostart: $(gsettings --schemadir "$SCHEMA_DIR" get io.github.kvaynwahey.Ds4BatteryTray autostart 2>/dev/null || echo unknown)"
}

case "${1:-status}" in
  install) install_tray ;;
  remove) remove_tray ;;
  status) status_tray ;;
  *) echo "usage: ds4-battery-tray.sh [install|remove|status]" >&2; exit 2 ;;
esac
