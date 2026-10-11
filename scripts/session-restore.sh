#!/usr/bin/env bash
# Dream OS - relaunch the apps saved in ~/.config/dream-os/session-apps.
# Runs at login (autostart). Skips apps that are already running.
set -uo pipefail

LIST="$HOME/.config/dream-os/session-apps"
[ -f "$LIST" ] || { echo "no session list at $LIST"; exit 0; }

# give the session a moment to settle
sleep 3

while read -r id; do
  [ -z "$id" ] && continue
  case "$id" in \#*) continue ;; esac
  # already running? (match by desktop id)
  if pgrep -f -- "$id" >/dev/null 2>&1; then
    continue
  fi
  if command -v gtk-launch >/dev/null 2>&1; then
    gtk-launch "$id" >/dev/null 2>&1 &
  elif command -v gio >/dev/null 2>&1; then
    gio launch "$id" >/dev/null 2>&1 &
  fi
  sleep 0.4
done < "$LIST"
