#!/usr/bin/env bash
# Dream OS - Phase 3: macOS-like layout.
# The geometry lives in scripts/appearance.sh so panel, dock and clock cannot
# drift between installers. User-space only. Idempotent.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CFG="$HOME/.config/cosmic"
PANEL="$CFG/com.system76.CosmicPanel.Panel/v1"
DOCK="$CFG/com.system76.CosmicPanel.Dock/v1"

for d in "$PANEL" "$DOCK"; do
  if [ -d "$d" ]; then
    cp -a "$d" "$d.bak.$(date +%Y%m%d-%H%M%S)"
  fi
done
mkdir -p "$PANEL" "$DOCK"

bash "$REPO/scripts/appearance.sh" panel
bash "$REPO/scripts/appearance.sh" comp

pkill -x cosmic-panel 2>/dev/null || true
echo "Panel + dock set to the macOS-profile layout."
