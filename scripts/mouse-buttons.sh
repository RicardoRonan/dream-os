#!/usr/bin/env bash
# Dream OS - install and enable the mouse back/forward button mapper.
# User-space service. Reading /dev/input needs the input group, so the service
# starts at the next login after: sudo usermod -aG input "$USER".
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN="$HOME/.local/bin/dream-os-mouse-buttons"
UNIT="$HOME/.config/systemd/user/dream-os-mouse-buttons.service"

mkdir -p "$HOME/.local/bin" "$(dirname "$UNIT")"
cp -f "$REPO/scripts/mouse-buttons.py" "$BIN"
chmod +x "$BIN"

cat > "$UNIT" <<EOF
[Unit]
Description=Dream OS - mouse back/forward buttons

[Service]
Type=simple
Environment=PYTHONUNBUFFERED=1
ExecStart=$BIN
Restart=on-failure
RestartSec=3

[Install]
WantedBy=default.target
EOF

if command -v systemctl >/dev/null 2>&1 && systemctl --user show-environment >/dev/null 2>&1; then
  systemctl --user daemon-reload
  systemctl --user enable dream-os-mouse-buttons.service >/dev/null 2>&1 || true
  if id -nG "$USER" | grep -qw input; then
    systemctl --user restart dream-os-mouse-buttons.service
    echo "Mouse buttons: service started (Alt+Left / Alt+Right)."
  else
    echo "Mouse buttons: service installed, but it needs input group access."
    echo "  sudo usermod -aG input $USER"
    echo "Then log out and back in. The service starts automatically."
  fi
else
  echo "Mouse buttons: service installed; no user systemd session to enable it."
fi
