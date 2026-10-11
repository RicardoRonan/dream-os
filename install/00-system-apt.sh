#!/usr/bin/env bash
# Dream OS - system packages that require root.
# Usage: sudo bash install/00-system-apt.sh
# Robust: a missing package no longer aborts the whole run.
set -uo pipefail

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
  echo "This script needs root. Re-run with: sudo bash install/00-system-apt.sh" >&2
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update || true

install_pkg() {
  local p="$1"
  if dpkg -s "$p" >/dev/null 2>&1; then
    echo "already installed: $p"
  else
    echo "installing: $p"
    apt-get install -y "$p" || echo "WARN: could not install $p"
  fi
}

# papirus-folders lives in the Papirus PPA on noble; add it if absent.
if ! apt-cache show papirus-folders >/dev/null 2>&1; then
  echo "Adding Papirus PPA..."
  apt-get install -y software-properties-common || true
  add-apt-repository -y ppa:papirus/papirus || true
  apt-get update || true
fi

for p in papirus-icon-theme papirus-folders kdeconnect ydotool libinput-tools; do
  install_pkg "$p"
done

# libinput-gestures is not packaged on noble; install from source.
if ! command -v libinput-gestures >/dev/null 2>&1; then
  echo "Installing libinput-gestures from source..."
  tmp="$(mktemp -d)"
  if git clone --depth 1 https://github.com/bulletmark/libinput-gestures "$tmp/libinput-gestures" >/dev/null 2>&1; then
    make -C "$tmp/libinput-gestures" install >/dev/null 2>&1 && echo "libinput-gestures installed" \
      || echo "WARN: libinput-gestures make install failed"
  else
    echo "WARN: could not fetch libinput-gestures (3-finger gestures unavailable)"
  fi
  rm -rf "$tmp"
fi
if command -v libinput-gestures-setup >/dev/null 2>&1; then
  libinput-gestures-setup autostart start >/dev/null 2>&1 || true
fi

echo "System packages done."
echo "Note: SF Mono is Apple-licensed and must be installed manually (see docs/fonts.md)."
