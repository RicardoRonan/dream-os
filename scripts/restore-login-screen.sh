#!/usr/bin/env bash
# Dream OS - restore the graphical login screen for COSMIC.
# Fixes "the machine boots to a bare TTY" caused by a missing display-manager alias.
# Safe + idempotent. Needs root.
#
#   sudo bash scripts/restore-login-screen.sh
set -uo pipefail

if [ "${EUID:-$(id -u)}" -ne 0 ]; then
  echo "Run with sudo: sudo bash $0" >&2
  exit 1
fi

GREETER=/usr/lib/systemd/system/cosmic-greeter.service
LINK=/etc/systemd/system/display-manager.service

if [ ! -e "$GREETER" ]; then
  echo "cosmic-greeter.service not found ($GREETER). Is COSMIC installed?" >&2
  exit 1
fi

if [ -e "$LINK" ] || [ -L "$LINK" ]; then
  echo "display-manager.service already present -> $(readlink -f "$LINK" 2>/dev/null)"
else
  ln -sf "$GREETER" "$LINK"
  echo "Created $LINK -> $GREETER"
fi

systemctl daemon-reload
systemctl enable cosmic-greeter >/dev/null 2>&1 || true
systemctl restart cosmic-greeter 2>/dev/null || systemctl start cosmic-greeter 2>/dev/null || true

echo "cosmic-greeter: $(systemctl is-active cosmic-greeter 2>/dev/null)"
echo "Login screen restored and enabled (persists across reboots)."
echo "If it still doesn't appear, check: journalctl -b -u cosmic-greeter -n 50 --no-pager"
