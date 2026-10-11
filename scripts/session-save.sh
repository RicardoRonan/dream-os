#!/usr/bin/env bash
# Dream OS - snapshot the currently running GUI apps to ~/.config/dream-os/session-apps
# Heuristic: match running processes against .desktop Exec entries.
set -uo pipefail

OUT="$HOME/.config/dream-os/session-apps"
mkdir -p "$(dirname "$OUT")"
tmp="$(mktemp)"

SKIP='^(cosmic-|gnome-|gjs|gdbus|xdg-|at-spi|pulseaudio|pipewire|wireplumber|dbus|systemd|gvfs|gnome-keyring|polkit|xdg-desktop-portal|im-launch|nm-applet|nvidia|orca|malcontent|tracker|ibus|fcitx|xembedsniproxy|kdeconnectd|kded)'

dirs="/usr/share/applications $HOME/.local/share/applications /var/lib/flatpak/exports/share/applications $HOME/.local/share/flatpak/exports/share/applications"

for d in $dirs; do
  [ -d "$d" ] || continue
  for f in "$d"/*.desktop; do
    [ -f "$f" ] || continue
    id="$(basename "$f" .desktop)"
    grep -qiE '^(NoDisplay|Hidden)=true' "$f" && continue
    grep -qE '^Type=Application' "$f" || continue
    exec_line="$(grep -m1 '^Exec=' "$f" | sed 's/^Exec=//')"
    [ -z "$exec_line" ] && continue
    exec_clean="$(printf '%s' "$exec_line" | sed 's/%[a-zA-Z]//g')"
    first="$(printf '%s' "$exec_clean" | awk '{print $1}')"
    [ -z "$first" ] && continue
    base="$(basename "$first")"
    if [ "$base" = "flatpak" ]; then
      app="$(printf '%s' "$exec_clean" | grep -oE '[a-z0-9]+\.[A-Za-z0-9._]+' | head -1)"
      [ -z "$app" ] && continue
      pgrep -f "$app" >/dev/null 2>&1 && echo "$id" >> "$tmp"
    else
      printf '%s' "$base" | grep -qE "$SKIP" && continue
      pgrep -x "$base" >/dev/null 2>&1 && echo "$id" >> "$tmp"
    fi
  done
done

sort -u "$tmp" > "$OUT"
rm -f "$tmp"
echo "Saved $(wc -l < "$OUT") running app(s) to $OUT"
