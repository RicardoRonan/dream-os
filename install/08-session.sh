#!/usr/bin/env bash
# Dream OS - session persistence: restore your apps after login/reboot.
# User-space only. Idempotent.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN="$HOME/.local/bin"
mkdir -p "$BIN" "$HOME/.config/dream-os"

install -m 755 "$REPO/scripts/session-save.sh"    "$BIN/session-save.sh"
install -m 755 "$REPO/scripts/session-restore.sh" "$BIN/session-restore.sh"

# seed the list from what's running right now (only if absent)
LIST="$HOME/.config/dream-os/session-apps"
if [ ! -f "$LIST" ]; then
  "$BIN/session-save.sh" >/dev/null 2>&1 || true
  [ -f "$LIST" ] || : > "$LIST"
  echo "Seeded session list from running apps -> $LIST"
fi

# autostart: restore at login
mkdir -p "$HOME/.config/autostart"
cat > "$HOME/.config/autostart/dream-os-session.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Dream OS Session Restore
Comment=Reopen your apps after login
Exec=$BIN/session-restore.sh
OnlyShowIn=COSMIC;
X-GNOME-Autostart-enabled=true
EOF

# periodic snapshot via a systemd user timer
UD="$HOME/.config/systemd/user"
mkdir -p "$UD"
cat > "$UD/dream-os-session-save.service" <<EOF
[Unit]
Description=Dream OS session snapshot
[Service]
Type=oneshot
ExecStart=$BIN/session-save.sh
EOF
cat > "$UD/dream-os-session-save.timer" <<'EOF'
[Unit]
Description=Periodic Dream OS session snapshot

[Timer]
OnBootSec=2min
OnUnitActiveSec=5min

[Install]
WantedBy=timers.target
EOF
if command -v systemctl >/dev/null 2>&1; then
  systemctl --user daemon-reload 2>/dev/null || true
  systemctl --user enable --now dream-os-session-save.timer 2>/dev/null \
    || echo "WARN: could not enable the session-save timer (enable manually)"
fi

echo "Session persistence enabled."
echo "  list : $LIST  (one app per line, edit freely)"
echo "  save : session-save.sh   (snapshot now)"
echo "  test : session-restore.sh"
