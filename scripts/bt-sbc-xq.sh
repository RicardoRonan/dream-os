#!/usr/bin/env bash
# Dream OS - prefer the SBC-XQ A2DP profile on Bluetooth cards that offer it.
# Runs as a systemd user service, watches for new BlueZ cards, and switches the
# active profile to a2dp-sink-sbc_xq when it exists. Manual profile changes are
# left alone until the device reconnects.
set -euo pipefail

# Trail of BTXQ (BT audio/bluetooth profile) events: journal + ~/.local/share/dream-os/bt-xq-trail.log
TRAIL="$HOME/.local/share/dream-os/bt-xq-trail.log"
trail() {
  local msg="$1"
  mkdir -p "$(dirname "$TRAIL")" 2>/dev/null || true
  logger -t dream-os-bt-xq "$msg" 2>/dev/null || true
  printf '%s %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$msg" >> "$TRAIL" 2>/dev/null || true
}

apply_card() {
  local card="$1" info active
  info="$(pactl list cards 2>/dev/null | awk -v card="$card" '
    $1 == "Name:" && $2 == card { inside = 1; print; next }
    inside && $1 == "Name:" { exit }
    inside { print }
  ')"
  printf '%s\n' "$info" | grep -q 'a2dp-sink-sbc_xq:' || return 0
  active="$(printf '%s\n' "$info" | sed -n 's/^[[:space:]]*Active Profile: //p' | head -1)"
  [ "$active" = "a2dp-sink-sbc_xq" ] && return 0
  if pactl set-card-profile "$card" a2dp-sink-sbc_xq 2>/dev/null; then
    echo "bt-sbc-xq: $card -> a2dp-sink-sbc_xq"
    trail "switched $card -> a2dp-sink-sbc_xq"
  fi
}

apply_all() {
  local card
  trail "apply_all"
  for card in $(pactl list short cards 2>/dev/null | awk '/bluez_card/ {print $2}'); do
    apply_card "$card"
  done
}

install_self() {
  local self bin unit
  self="$(readlink -f "${BASH_SOURCE[0]}")"
  bin="$HOME/.local/bin/dream-os-bt-sbc-xq"
  unit="$HOME/.config/systemd/user/dream-os-bt-sbc-xq.service"
  mkdir -p "$HOME/.local/bin" "$(dirname "$unit")"
  cp -f "$self" "$bin"
  chmod +x "$bin"
  cat > "$unit" <<EOF
[Unit]
Description=Dream OS - prefer SBC-XQ on Bluetooth audio devices
After=pipewire.service wireplumber.service

[Service]
Type=simple
ExecStart=$bin
Restart=on-failure
RestartSec=3

[Install]
WantedBy=default.target
EOF
  if command -v systemctl >/dev/null 2>&1 && systemctl --user show-environment >/dev/null 2>&1; then
    systemctl --user daemon-reload
    systemctl --user enable --now dream-os-bt-sbc-xq.service
    echo "bt-sbc-xq: service enabled"
  else
    echo "bt-sbc-xq: service installed; no user systemd session to start it"
  fi
}

watch() {
  apply_all
  while read -r line; do
    case "$line" in
      *"'new' on card"*) sleep 1; apply_all ;;
    esac
  done < <(pactl subscribe 2>/dev/null)
}

case "${1:-}" in
  install) install_self ;;
  *) watch ;;
esac
