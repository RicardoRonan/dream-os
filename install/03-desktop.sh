#!/usr/bin/env bash
# Dream OS - Phase 3: macOS-like layout.
# Top bar as a menu bar (left: app/workspaces/clipboard, right: status + clock).
# Bottom dock: always-visible, centered, translucent, rounded.
# User-space only. Idempotent.
set -euo pipefail

CFG="$HOME/.config/cosmic"
PANEL="$CFG/com.system76.CosmicPanel.Panel/v1"
DOCK="$CFG/com.system76.CosmicPanel.Dock/v1"

for d in "$PANEL" "$DOCK"; do
  if [ -d "$d" ]; then
    cp -a "$d" "$d.bak.$(date +%Y%m%d-%H%M%S)"
  fi
done
mkdir -p "$PANEL" "$DOCK"

# ---- top bar (menu bar) ----------------------------------------------------
printf 'Top\n' > "$PANEL/anchor"
printf 'XS\n'  > "$PANEL/size"
printf 'Some([])\n' > "$PANEL/plugins_center"
cat > "$PANEL/plugins_wings" <<'EOF'
Some((
    [
        "com.system76.CosmicPanelWorkspacesButton",
        "com.system76.CosmicPanelAppButton",
        "io.github.cosmic_utils.cosmic-ext-applet-clipboard-manager",
    ],
    [
        "com.system76.CosmicAppletStatusArea",
        "com.system76.CosmicAppletAudio",
        "com.system76.CosmicAppletBluetooth",
        "com.system76.CosmicAppletNetwork",
        "com.system76.CosmicAppletBattery",
        "com.system76.CosmicAppletNotifications",
        "com.system76.CosmicAppletPower",
        "com.system76.CosmicAppletTime",
    ],
))
EOF

# ---- dock (macOS-like) -----------------------------------------------------
printf 'Bottom\n' > "$DOCK/anchor"
printf 'Never\n'  > "$DOCK/autohide"
printf '0.5\n'    > "$DOCK/opacity"
printf '160\n'    > "$DOCK/border_radius"
printf 'false\n'  > "$DOCK/expand_to_edges"
printf 'M\n'      > "$DOCK/size"
printf '12\n'     > "$DOCK/margin"
printf 'true\n'   > "$DOCK/exclusive_zone"
printf 'None\n'   > "$DOCK/plugins_wings"
cat > "$DOCK/plugins_center" <<'EOF'
Some([
    "com.system76.CosmicPanelAppButton",
    "com.system76.CosmicAppList",
    "com.system76.CosmicAppletMinimize",
])
EOF

pkill -x cosmic-panel 2>/dev/null || true
echo "Panel + dock set to macOS-like layout."
