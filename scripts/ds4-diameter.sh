#!/usr/bin/env bash
# Dream OS - set the DS4 tray pin icon diameter (1-10 of the dock icon).
# Dock icons are 48px, so the default 5 gives a 24px pin icon.
#
# Usage: ds4-diameter [n]    (n in 1..10; default 5)
set -euo pipefail

SCHEMA_DIR="$HOME/.local/share/glib-2.0/schemas"
SCHEMA="$SCHEMA_DIR/io.github.kvaynwahey.Ds4BatteryTray.gschema.xml"
value="${1:-5}"

[ -f "$SCHEMA" ] || { echo "error: DS4 tray schema not installed" >&2; exit 1; }
[ "$value" -eq "$value" ] 2>/dev/null || { echo "error: diameter must be a number 1-10" >&2; exit 2; }
[ "$value" -ge 1 ] && [ "$value" -le 10 ] || { echo "error: diameter must be 1-10" >&2; exit 2; }

gsettings --schemadir "$SCHEMA_DIR" set io.github.kvaynwahey.Ds4BatteryTray diameter "$value"
glib-compile-schemas "$SCHEMA_DIR"
systemctl --user restart ds4-battery-tray.service 2>/dev/null || true
echo "DS4 tray pin diameter: $value of 10 (dock icons are 48px -> $(python3 -c "print(int(48 * $value / 10))")px)."
