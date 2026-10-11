#!/usr/bin/env bash
# Dream OS - hot corners via waycorner (top-left -> overview, bottom-right -> launcher).
# User-space only. Idempotent.
set -euo pipefail

BIN="$HOME/.local/bin/waycorner"
mkdir -p "$HOME/.local/bin"

if [ ! -x "$BIN" ]; then
  echo "Downloading waycorner..."
  curl -fsSL -o "$BIN" \
    https://github.com/AndreasBackx/waycorner/releases/download/0.2.3/waycorner
  chmod +x "$BIN"
fi

mkdir -p "$HOME/.config/waycorner"
cat > "$HOME/.config/waycorner/config.toml" <<'EOF'
# Dream OS hot corners (macOS-like). Preview: waycorner --config ~/.config/waycorner/config.toml --preview

[workspaces]
enter_command = ["cosmic-workspaces"]
locations = ["top_left"]
size = 10
timeout_ms = 250
color = "#FF4C8DFF"

[launcher]
enter_command = ["cosmic-launcher"]
locations = ["bottom_right"]
size = 10
timeout_ms = 250
color = "#FF4C8DFF"
EOF

mkdir -p "$HOME/.config/autostart"
cat > "$HOME/.config/autostart/waycorner.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Waycorner (Dream OS hot corners)
Exec=$BIN
OnlyShowIn=COSMIC;
X-GNOME-Autostart-enabled=true
EOF

pkill -x waycorner 2>/dev/null || true
sleep 1
setsid "$BIN" >/dev/null 2>&1 &
sleep 1
if pgrep -x waycorner >/dev/null; then
  echo "Hot corners running (top-left: overview, bottom-right: launcher)."
else
  echo "WARN: waycorner did not start (it needs the session; will autostart on login)." >&2
fi
