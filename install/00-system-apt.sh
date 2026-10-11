#!/usr/bin/env bash
# Dream OS - system packages that require root.
# Usage: sudo bash install/00-system-apt.sh
set -euo pipefail

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
  echo "This script needs root. Re-run with: sudo bash install/00-system-apt.sh" >&2
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update

# papirus-folders may live in the Papirus PPA; add it if the package is absent.
if ! apt-cache show papirus-folders >/dev/null 2>&1; then
  apt-get install -y software-properties-common
  add-apt-repository -y ppa:papirus/papirus
  apt-get update
fi

apt-get install -y \
  papirus-icon-theme papirus-folders \
  libinput-gestures \
  kdeconnect \
  ydotool

echo "System packages installed."
echo "Note: SF Mono is Apple-licensed and must be installed manually (see docs/fonts.md)."
