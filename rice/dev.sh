#!/usr/bin/env bash
# Dream OS rice - DEV MODE
# Runs Sway NESTED inside a window on your current session, so you can iterate on the
# look & feel with no logout, no DRM, and no NVIDIA "unsupported GPU" trouble.
#
#   bash rice/dev.sh
#
# It symlinks ~/.config/{sway,waybar,mako,wofi} to the repo so edits here are live.
#   - reload Sway :  $mod+Shift+C
#   - reload bar  :  pkill -SIGUSR2 waybar   (or just close the window and rerun)
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

link_dir() {
  local name="$1" src="$REPO/rice/$1" dst="$HOME/.config/$1"
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    mv "$dst" "$dst.bak.$(date +%Y%m%d-%H%M%S)"
    echo "backed up existing $dst"
  fi
  ln -sfn "$src" "$dst"
  echo "linked $dst -> $src"
}

link_dir sway
link_dir waybar
link_dir mako
link_dir wofi

echo
echo "Starting nested Sway (dev preview). Edit files in rice/ and reload with \$mod+Shift+C."
echo "Close the preview window to exit."
echo

exec env WLR_BACKENDS=wayland WLR_LIBINPUT_NO_DEVICES=1 \
  sway --unsupported-gpu -c "$REPO/rice/sway/config"
