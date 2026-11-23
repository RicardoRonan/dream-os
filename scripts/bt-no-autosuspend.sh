#!/usr/bin/env bash
# Dream OS - keep the Intel AX201 Bluetooth adapter out of USB autosuspend.
#
# Autosuspend can cause periodic Bluetooth audio ticks and dropouts. This
# installs a udev rule and powers the adapter on immediately. The stock
# behaviour is restored by "remove".
set -euo pipefail

RULE="/etc/udev/rules.d/50-bluetooth-no-autosuspend.rules"
VENDOR="8087"
PRODUCT="0026"

say() { printf '%s\n' "$*"; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }

devices() {
  for d in /sys/bus/usb/devices/*; do
    [ -f "$d/idVendor" ] || continue
    [ "$(cat "$d/idVendor" 2>/dev/null)" = "$VENDOR" ] || continue
    [ "$(cat "$d/idProduct" 2>/dev/null)" = "$PRODUCT" ] || continue
    printf '%s\n' "$d"
  done
}

apply_power() {
  local value="$1" d
  while IFS= read -r d; do
    printf '%s\n' "$value" > "$d/power/control" 2>/dev/null || true
  done < <(devices)
}

install_root() {
  [ "$(id -u)" -eq 0 ] || die "root is required"
  cat > "$RULE" <<'EOF'
# Dream OS: keep the Intel AX201 Bluetooth adapter powered while audio is active.
ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="8087", ATTR{idProduct}=="0026", ATTR{power/control}="on"
EOF
  udevadm control --reload-rules
  udevadm trigger --subsystem-match=usb --attr-match=idVendor="$VENDOR" --attr-match=idProduct="$PRODUCT" 2>/dev/null || true
  apply_power on
  say "Bluetooth autosuspend disabled."
}

remove_root() {
  [ "$(id -u)" -eq 0 ] || die "root is required"
  rm -f "$RULE"
  udevadm control --reload-rules
  apply_power auto
  say "Bluetooth autosuspend restored to auto."
}

as_root() {
  if [ "$(id -u)" -eq 0 ]; then
    "$1"
  elif command -v pkexec >/dev/null 2>&1; then
    pkexec "$0" "$1"
  else
    die "run as root: sudo $0 $1"
  fi
}

status_bt() {
  local d
  while IFS= read -r d; do
    say "$d control=$(cat "$d/power/control" 2>/dev/null || echo unknown) autosuspend=$(cat "$d/power/autosuspend_delay_ms" 2>/dev/null || echo unknown)"
  done < <(devices)
  say "rule: $([ -f "$RULE" ] && echo "$RULE" || echo missing)"
}

case "${1:-status}" in
  install) as_root _install-root ;;
  remove) as_root _remove-root ;;
  _install-root) install_root ;;
  _remove-root) remove_root ;;
  status) status_bt ;;
  *) echo "usage: bt-no-autosuspend.sh [install|remove|status]" >&2; exit 2 ;;
esac
