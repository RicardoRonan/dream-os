#!/usr/bin/env bash
# Dream OS - macOS-structure appearance profile.
#
# One command applies the same geometry, type, icon and cursor values to every
# layer: COSMIC theme, CosmicTk, panel, dock, GTK 3/4, Flatpak and gsettings.
# User-space only. Backs up before writing. Revert with:
#   scripts/appearance.sh revert
set -euo pipefail

SELF="$(readlink -f "${BASH_SOURCE[0]}")"
REPO="$(cd "$(dirname "$SELF")/.." && pwd)"
CFG="$HOME/.config/cosmic"
TK="$CFG/com.system76.CosmicTk/v1"
PANEL="$CFG/com.system76.CosmicPanel.Panel/v1"
DOCK="$CFG/com.system76.CosmicPanel.Dock/v1"
COMP="$CFG/com.system76.CosmicComp/v1"
BACKUP_ROOT="$HOME/.config/dream-os/backups"
UNIT_DIR="$HOME/.config/systemd/user"
STATE_DIR="$HOME/.local/share/dream-os"

# ---- tokens ---------------------------------------------------------------
UI_FONT="SF Pro Text"
UI_SIZE="10.5"
MONO_FONT="JetBrainsMono Nerd Font"
MONO_SIZE="10.5"
HEADER_SIZE="Compact"
DENSITY="Standard"
ICON_THEME="DreamOS"
CURSOR_THEME="Vimix-cursors"
CURSOR_SIZE="24"
RADIUS_XS=6
RADIUS_S=8
RADIUS_M=12
RADIUS_L=16
RADIUS_XL=160
PANEL_SIZE="XS"
PANEL_OPACITY="1.0"
DOCK_SIZE="L"
DOCK_RADIUS=24
DOCK_OPACITY="0.5"
DOCK_MARGIN=4
DOCK_PADDING=8
DOCK_SPACING=8

say() { printf '%s\n' "$*"; }

backup() {
  local ts dir
  ts="$(date +%Y%m%d-%H%M%S)"
  dir="$BACKUP_ROOT/$ts"
  mkdir -p "$dir"
  for pair in \
    "$PANEL:panel" "$DOCK:dock" "$TK:cosmic-tk" \
    "$CFG/com.system76.CosmicSettings.Shortcuts/v1:shortcuts" \
    "$HOME/.config/gtk-3.0:gtk-3.0" "$HOME/.config/gtk-4.0:gtk-4.0" \
    "$HOME/.config/waycorner:waycorner" \
    "$HOME/.local/share/icons/DreamOS:DreamOS-icons" \
    "$HOME/.icons/default:icons-default"; do
    local src="${pair%%:*}" name="${pair##*:}"
    [ -e "$src" ] && cp -a "$src" "$dir/$name"
  done
  [ -e "$HOME/.config/libinput-gestures.conf" ] && cp -a "$HOME/.config/libinput-gestures.conf" "$dir/libinput-gestures.conf"
  [ -e "$HOME/.config/environment.d/dream-os.conf" ] && cp -a "$HOME/.config/environment.d/dream-os.conf" "$dir/environment.d.conf"
  cp -a "$CFG/com.system76.CosmicTheme.Dark/v2/corner_radii" "$dir/corner-radii-dark" 2>/dev/null || true
  cp -a "$CFG/com.system76.CosmicTheme.Light/v2/corner_radii" "$dir/corner-radii-light" 2>/dev/null || true
  [ -e "$COMP/appearance_settings" ] && cp -a "$COMP/appearance_settings" "$dir/appearance_settings"
  for k in font-name monospace-font-name icon-theme cursor-theme cursor-size gtk-theme color-scheme; do
    gsettings get "org.gnome.desktop.interface" "$k" > "$dir/gsettings-$k.txt" 2>/dev/null || true
  done
  ln -sfn "$dir" "$BACKUP_ROOT/latest"
  say "Backup: $dir"
}

theme_radii() {
  local body mode_file mode_before
  mode_file="$CFG/com.system76.CosmicTheme.Mode/v1/is_dark"
  mode_before="$(cat "$mode_file" 2>/dev/null || echo true)"
  body="(
    radius_0: (0.0, 0.0, 0.0, 0.0),
    radius_xs: ($RADIUS_XS.0, $RADIUS_XS.0, $RADIUS_XS.0, $RADIUS_XS.0),
    radius_s: ($RADIUS_S.0, $RADIUS_S.0, $RADIUS_S.0, $RADIUS_S.0),
    radius_m: ($RADIUS_M.0, $RADIUS_M.0, $RADIUS_M.0, $RADIUS_M.0),
    radius_l: ($RADIUS_L.0, $RADIUS_L.0, $RADIUS_L.0, $RADIUS_L.0),
    radius_xl: ($RADIUS_XL.0, $RADIUS_XL.0, $RADIUS_XL.0, $RADIUS_XL.0),
)"
  mkdir -p "$CFG/com.system76.CosmicTheme.Dark/v2" "$CFG/com.system76.CosmicTheme.Light/v2"
  printf '%s\n' "$body" > "$CFG/com.system76.CosmicTheme.Dark/v2/corner_radii"
  printf '%s\n' "$body" > "$CFG/com.system76.CosmicTheme.Light/v2/corner_radii"
  for mode in Dark Light; do
    local seed="$CFG/com.system76.CosmicTheme.$mode.Builder/v1"
    [ -d "$seed" ] && printf '%s\n' "$body" > "$seed/corner_radii"
  done
  if command -v cosmic-settings >/dev/null 2>&1; then
    cosmic-settings appearance import "$REPO/configs/cosmic/dream-os-dark.ron" >/dev/null 2>&1 || true
    cosmic-settings appearance import "$REPO/configs/cosmic/dream-os-light.ron" >/dev/null 2>&1 || true
  fi
  # Importing both themes can flip the active mode; restore it.
  mkdir -p "$(dirname "$mode_file")"
  printf '%s\n' "$mode_before" > "$mode_file"
}

apply_theme_fonts() {
  local mode dir
  for mode in Dark Light; do
    dir="$CFG/com.system76.CosmicTheme.$mode/v2"
    mkdir -p "$dir"
    cat > "$dir/font" <<EOF
(
    family: "$UI_FONT",
    weight: Normal,
    stretch: Normal,
    style: Normal,
)
EOF
    cat > "$dir/mono_font" <<EOF
(
    family: "$MONO_FONT",
    weight: Normal,
    stretch: Normal,
    style: Normal,
)
EOF
    printf '"%s"\n' "$ICON_THEME" > "$dir/icon_theme"
  done
}

sync() {
  local mode v2 drift=0 tk_drift=0
  for mode in Dark Light; do
    v2="$CFG/com.system76.CosmicTheme.$mode/v2"
    grep -q "family: \"$UI_FONT\"" "$v2/font" 2>/dev/null || drift=1
    grep -q "family: \"$MONO_FONT\"" "$v2/mono_font" 2>/dev/null || drift=1
    [ "$(cat "$v2/icon_theme" 2>/dev/null)" = "\"$ICON_THEME\"" ] || drift=1
  done
  if [ "$drift" = 1 ]; then
    apply_theme_fonts
    say "sync: restored theme font/icon fields"
  fi

  grep -q "family: \"$UI_FONT\"" "$TK/interface_font" 2>/dev/null || tk_drift=1
  grep -q "family: \"$MONO_FONT\"" "$TK/monospace_font" 2>/dev/null || tk_drift=1
  [ "$(cat "$TK/icon_theme" 2>/dev/null)" = "\"$ICON_THEME\"" ] || tk_drift=1
  [ "$(cat "$TK/header_size" 2>/dev/null)" = "$HEADER_SIZE" ] || tk_drift=1
  [ "$(cat "$TK/apply_theme_global" 2>/dev/null)" = "true" ] || tk_drift=1
  if [ "$tk_drift" = 1 ]; then
    apply_tk
    say "sync: restored CosmicTk values"
  fi

  [ "$(gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null | tr -d "'")" = "$ICON_THEME" ] || \
    gsettings set org.gnome.desktop.interface icon-theme "$ICON_THEME" 2>/dev/null || true
  [ "$(gsettings get org.gnome.desktop.interface font-name 2>/dev/null | tr -d "'")" = "$UI_FONT $UI_SIZE" ] || \
    gsettings set org.gnome.desktop.interface font-name "$UI_FONT $UI_SIZE" 2>/dev/null || true
  [ "$(gsettings get org.gnome.desktop.interface monospace-font-name 2>/dev/null | tr -d "'")" = "$MONO_FONT $MONO_SIZE" ] || \
    gsettings set org.gnome.desktop.interface monospace-font-name "$MONO_FONT $MONO_SIZE" 2>/dev/null || true

  # A theme export can rewrite gtk.css after the sync; re-apply the radius block.
  if [ "$drift" = 1 ] || [ "$tk_drift" = 1 ]; then
    local radius_script="$STATE_DIR/gtk-radius.sh"
    if [ -x "$radius_script" ]; then
      sleep 1
      bash "$radius_script" apply --quiet
    fi
  fi
}

apply_tk() {
  mkdir -p "$TK"
  printf '%s\n' "$HEADER_SIZE" > "$TK/header_size"
  printf '%s\n' "$DENSITY" > "$TK/interface_density"
  cat > "$TK/interface_font" <<EOF
(
    family: "$UI_FONT",
    weight: Normal,
    stretch: Normal,
    style: Normal,
)
EOF
  cat > "$TK/monospace_font" <<EOF
(
    family: "$MONO_FONT",
    weight: Normal,
    stretch: Normal,
    style: Normal,
)
EOF
  printf '"%s"\n' "$ICON_THEME" > "$TK/icon_theme"
  printf 'true\n' > "$TK/apply_theme_global"
}

panel_wings() {
  local status="com.system76.CosmicAppletStatusArea"
  local hub="io.github.marcelogomes90.cosmic-ext-applet-status-hub"
  if [ -f "$HOME/.local/share/flatpak/exports/share/applications/$hub.desktop" ] \
     || [ -f "/var/lib/flatpak/exports/share/applications/$hub.desktop" ]; then
    status="$hub"
  fi
  cat <<EOF
Some((
    [
        "dev.cappsy.CosmicExtAppletLogoMenu",
        "com.system76.CosmicPanelWorkspacesButton",
        "io.github.cosmic_utils.weather-applet",
    ],
    [
        "$status",
        "com.system76.CosmicAppletBattery",
        "com.system76.CosmicAppletNetwork",
        "com.system76.CosmicAppletBluetooth",
        "com.system76.CosmicAppletAudio",
        "com.system76.CosmicAppletNotifications",
        "com.system76.CosmicAppletTime",
    ],
))
EOF
}

apply_panel() {
  mkdir -p "$PANEL" "$DOCK"

  printf 'Top\n' > "$PANEL/anchor"
  printf 'false\n' > "$PANEL/anchor_gap"
  printf 'Never\n' > "$PANEL/autohide"
  cat > "$PANEL/autohide_behavior" <<'EOF'
(
    wait_time: 1000,
    transition_time: 200,
    handle_size: 4,
    unhide_delay: 200,
)
EOF
  printf 'ThemeDefault\n' > "$PANEL/background"
  printf '0\n' > "$PANEL/border_radius"
  printf '0.0\n' > "$PANEL/border_width"
  printf 'true\n' > "$PANEL/expand_to_edges"
  printf 'true\n' > "$PANEL/exclusive_zone"
  printf 'true\n' > "$PANEL/keep_style_on_maximize"
  printf 'OnDemand\n' > "$PANEL/keyboard_interactivity"
  printf 'Top\n' > "$PANEL/layer"
  printf '0\n' > "$PANEL/margin"
  printf '"Panel"\n' > "$PANEL/name"
  printf '%s\n' "$PANEL_OPACITY" > "$PANEL/opacity"
  printf 'All\n' > "$PANEL/output"
  printf '0\n' > "$PANEL/padding"
  printf '0.5\n' > "$PANEL/padding_overlap"
  printf 'Some(500)\n' > "$PANEL/autohover_delay_ms"
  printf 'None\n' > "$PANEL/plugins_center"
  panel_wings > "$PANEL/plugins_wings"
  printf '%s\n' "$PANEL_SIZE" > "$PANEL/size"
  printf 'None\n' > "$PANEL/size_center"
  printf 'None\n' > "$PANEL/size_wings"
  printf '4\n' > "$PANEL/spacing"

  printf 'Bottom\n' > "$DOCK/anchor"
  printf 'true\n' > "$DOCK/anchor_gap"
  printf 'Always\n' > "$DOCK/autohide"
  cat > "$DOCK/autohide_behavior" <<'EOF'
(
    wait_time: 350,
    transition_time: 200,
    handle_size: 8,
    unhide_delay: 0,
)
EOF
  printf 'ThemeDefault\n' > "$DOCK/background"
  printf '%s\n' "$DOCK_RADIUS" > "$DOCK/border_radius"
  printf '0.0\n' > "$DOCK/border_width"
  printf 'false\n' > "$DOCK/expand_to_edges"
  printf 'false\n' > "$DOCK/exclusive_zone"
  printf 'false\n' > "$DOCK/keep_style_on_maximize"
  printf 'OnDemand\n' > "$DOCK/keyboard_interactivity"
  printf 'Top\n' > "$DOCK/layer"
  printf '%s\n' "$DOCK_MARGIN" > "$DOCK/margin"
  printf '"Dock"\n' > "$DOCK/name"
  printf '%s\n' "$DOCK_OPACITY" > "$DOCK/opacity"
  printf 'All\n' > "$DOCK/output"
  printf '%s\n' "$DOCK_PADDING" > "$DOCK/padding"
  printf '0.5\n' > "$DOCK/padding_overlap"
  printf 'Some(500)\n' > "$DOCK/autohover_delay_ms"
  printf 'None\n' > "$DOCK/plugins_wings"
  cat > "$DOCK/plugins_center" <<'EOF'
Some([
    "com.system76.CosmicPanelAppButton",
    "com.system76.CosmicAppList",
    "com.system76.CosmicAppletMinimize",
])
EOF
  printf '%s\n' "$DOCK_SIZE" > "$DOCK/size"
  printf 'None\n' > "$DOCK/size_center"
  printf 'None\n' > "$DOCK/size_wings"
  printf '%s\n' "$DOCK_SPACING" > "$DOCK/spacing"
}

apply_comp() {
  mkdir -p "$COMP"
  cat > "$COMP/appearance_settings" <<'EOF'
(
    clip_floating_windows: true,
    clip_tiled_windows: true,
    shadow_tiled_windows: false,
)
EOF
}

apply_gtk() {
  local icon="$ICON_THEME" cursor="$CURSOR_THEME" gtk_theme="adw-gtk3-dark"
  if [ ! -d "$HOME/.local/share/icons/$icon" ]; then
    icon="Adwaita"
    [ -d /usr/share/icons/Papirus-Dark ] && icon="Papirus-Dark"
  fi
  if [ ! -d "$HOME/.local/share/icons/$cursor" ]; then
    if [ -d "$HOME/.local/share/icons/Vimix-cursors" ]; then
      cursor="Vimix-cursors"
    else
      cursor="Adwaita"
    fi
  fi
  [ -d /usr/share/themes/adw-gtk3-dark ] || gtk_theme="Adwaita"
  for dir in "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"; do
    mkdir -p "$dir"
    cat > "$dir/settings.ini" <<EOF
[Settings]
gtk-font-name=$UI_FONT $UI_SIZE
gtk-cursor-theme-name=$cursor
gtk-icon-theme-name=$icon
gtk-theme-name=$gtk_theme
gtk-application-prefer-dark-theme=1
EOF
  done

  gsettings set org.gnome.desktop.interface font-name "$UI_FONT $UI_SIZE" 2>/dev/null || true
  gsettings set org.gnome.desktop.interface monospace-font-name "$MONO_FONT $MONO_SIZE" 2>/dev/null || true
  gsettings set org.gnome.desktop.interface icon-theme "$ICON_THEME" 2>/dev/null || true
  gsettings set org.gnome.desktop.interface cursor-theme "$CURSOR_THEME" 2>/dev/null || true
  gsettings set org.gnome.desktop.interface cursor-size "$CURSOR_SIZE" 2>/dev/null || true
  gsettings set org.gnome.desktop.interface gtk-theme "$gtk_theme" 2>/dev/null || true
  gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
  gsettings set org.gnome.desktop.wm.preferences button-layout ':minimize,maximize,close' 2>/dev/null || true

  if command -v flatpak >/dev/null 2>&1; then
    for fs in xdg-config/gtk-3.0:ro xdg-config/gtk-4.0:ro \
              xdg-data/icons:ro xdg-config/kdeglobals:ro xdg-data/color-schemes:ro; do
      flatpak override --user --filesystem="$fs" >/dev/null 2>&1 || true
    done
  fi

  bash "$REPO/scripts/gtk-radius.sh" apply --quiet
}

apply_icons() {
  mkdir -p "$HOME/.local/share/icons/DreamOS"
  cp -a "$REPO/assets/icons/DreamOS/." "$HOME/.local/share/icons/DreamOS/"
  if [ -d "$HOME/.local/share/icons/WhiteSur-grey-dark" ]; then
    bash "$REPO/scripts/icon-map.sh"
  else
    say "WARN: WhiteSur-grey-dark not installed; run scripts/install-whitesur.sh"
  fi
  gtk-update-icon-cache -f -t "$HOME/.local/share/icons/DreamOS" >/dev/null 2>&1 || true
  printf '"%s"\n' "$ICON_THEME" > "$TK/icon_theme"
  gsettings set org.gnome.desktop.interface icon-theme "$ICON_THEME" 2>/dev/null || true
}

apply_cursor() {
  local cursor="$CURSOR_THEME"
  if [ ! -d "$HOME/.local/share/icons/$cursor" ]; then
    if [ -d "$HOME/.local/share/icons/Vimix-cursors" ]; then
      cursor="Vimix-cursors"
    else
      cursor="Adwaita"
    fi
  fi
  mkdir -p "$HOME/.icons/default" "$HOME/.config/environment.d"
  cat > "$HOME/.icons/default/index.theme" <<EOF
[Icon Theme]
Inherits=$cursor
EOF
  cat > "$HOME/.config/environment.d/dream-os.conf" <<EOF
QT_QPA_PLATFORMTHEME=qt5ct
XCURSOR_THEME=$cursor
XCURSOR_SIZE=$CURSOR_SIZE
EOF
}

restart_panel() {
  pkill -x cosmic-panel 2>/dev/null || true
  pkill -f '^cosmic-app-library$' 2>/dev/null || true
  sleep 2
  # cosmic-session respawns both; this fallback only matters outside a session.
  if ! pgrep -f '^cosmic-app-library$' >/dev/null 2>&1 && [ -n "${WAYLAND_DISPLAY:-}" ]; then
    setsid cosmic-app-library >/dev/null 2>&1 < /dev/null &
  fi
}

install_sync() {
  mkdir -p "$UNIT_DIR" "$STATE_DIR"
  cp -f "$SELF" "$STATE_DIR/appearance.sh"
  chmod +x "$STATE_DIR/appearance.sh"

  cat > "$UNIT_DIR/dream-os-appearance.service" <<'EOF'
[Unit]
Description=Dream OS - keep theme fonts and icons in sync

[Service]
Type=oneshot
ExecStart=/usr/bin/env bash %h/.local/share/dream-os/appearance.sh sync
EOF

  cat > "$UNIT_DIR/dream-os-appearance.timer" <<'EOF'
[Unit]
Description=Dream OS - periodically resync theme fonts and icons

[Timer]
OnBootSec=1min
OnUnitActiveSec=2min
Unit=dream-os-appearance.service

[Install]
WantedBy=timers.target
EOF

  if command -v systemctl >/dev/null 2>&1 && systemctl --user show-environment >/dev/null 2>&1; then
    systemctl --user daemon-reload
    systemctl --user enable --now dream-os-appearance.timer
    say "appearance: sync timer enabled (dream-os-appearance.timer)"
  else
    say "appearance: no user systemd session; run 'scripts/appearance.sh sync' after theme changes"
  fi
}

remove_sync() {
  if command -v systemctl >/dev/null 2>&1 && systemctl --user show-environment >/dev/null 2>&1; then
    systemctl --user disable --now dream-os-appearance.timer 2>/dev/null || true
    systemctl --user daemon-reload
  fi
  rm -f "$UNIT_DIR/dream-os-appearance.timer" "$UNIT_DIR/dream-os-appearance.service"
  say "appearance: sync timer removed"
}

apply_all() {
  backup
  theme_radii
  apply_theme_fonts
  apply_tk
  apply_panel
  apply_comp
  apply_gtk
  apply_icons
  apply_cursor
  restart_panel
  # COSMIC can rewrite gtk.css while the panel restarts; apply the block last.
  sleep 1
  bash "$REPO/scripts/gtk-radius.sh" apply --quiet
  say "Applied: radii $RADIUS_XS/$RADIUS_S/$RADIUS_M/$RADIUS_L, header $HEADER_SIZE, dock $DOCK_SIZE/$DOCK_RADIUS, icons $ICON_THEME, cursor $CURSOR_THEME."
  say "Log out and in once if an already-open app still shows its old icon or cursor."
}

doctor() {
  say "CosmicTk: header=$(cat "$TK/header_size" 2>/dev/null) density=$(cat "$TK/interface_density" 2>/dev/null) icons=$(cat "$TK/icon_theme" 2>/dev/null) global=$(cat "$TK/apply_theme_global" 2>/dev/null)"
  say "gsettings: font=$(gsettings get org.gnome.desktop.interface font-name 2>/dev/null) mono=$(gsettings get org.gnome.desktop.interface monospace-font-name 2>/dev/null) icons=$(gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null) cursor=$(gsettings get org.gnome.desktop.interface cursor-theme 2>/dev/null) size=$(gsettings get org.gnome.desktop.interface cursor-size 2>/dev/null)"
  say "panel: size=$(cat "$PANEL/size") margin=$(cat "$PANEL/margin") expand=$(cat "$PANEL/expand_to_edges") opacity=$(cat "$PANEL/opacity") clock_right=$(grep -c CosmicAppletTime "$PANEL/plugins_wings" 2>/dev/null || true)"
  say "dock: size=$(cat "$DOCK/size") radius=$(cat "$DOCK/border_radius") opacity=$(cat "$DOCK/opacity") spacing=$(cat "$DOCK/spacing") padding=$(cat "$DOCK/padding") autohide=$(cat "$DOCK/autohide")"
  say "comp: $(grep -o 'clip_floating_windows: [a-z]*' "$COMP/appearance_settings" 2>/dev/null)"
  say "icons: WhiteSur=$(test -d "$HOME/.local/share/icons/WhiteSur-grey-dark" && echo yes || echo no) mapped=$(find "$HOME/.local/share/icons/DreamOS/scalable/apps" -type l 2>/dev/null | wc -l)"
  say "gtk-radius marker: $(grep -c 'dream-os-radius' "$HOME/.config/gtk-4.0/gtk.css" 2>/dev/null || true)"
}

revert() {
  local dir="$BACKUP_ROOT/latest"
  if [ ! -e "$dir" ]; then
    say "No backup found under $BACKUP_ROOT" >&2
    exit 1
  fi
  say "Restoring $dir"
  for pair in \
    "$dir/panel:$PANEL" "$dir/dock:$DOCK" "$dir/cosmic-tk:$TK" \
    "$dir/shortcuts:$CFG/com.system76.CosmicSettings.Shortcuts/v1" \
    "$dir/gtk-3.0:$HOME/.config/gtk-3.0" "$dir/gtk-4.0:$HOME/.config/gtk-4.0" \
    "$dir/waycorner:$HOME/.config/waycorner" \
    "$dir/DreamOS-icons:$HOME/.local/share/icons/DreamOS" \
    "$dir/icons-default:$HOME/.icons/default"; do
    local src="${pair%%:*}" dst="${pair##*:}"
    [ -e "$src" ] || continue
    rm -rf "$dst"
    cp -a "$src" "$dst"
  done
  for f in libinput-gestures.conf environment.d.conf; do
    [ -e "$dir/$f" ] || continue
    case "$f" in
      libinput-gestures.conf) cp -a "$dir/$f" "$HOME/.config/$f" ;;
      environment.d.conf) cp -a "$dir/$f" "$HOME/.config/environment.d/dream-os.conf" ;;
    esac
  done
  [ -e "$dir/corner-radii-dark" ] && cp -a "$dir/corner-radii-dark" "$CFG/com.system76.CosmicTheme.Dark/v2/corner_radii"
  [ -e "$dir/corner-radii-light" ] && cp -a "$dir/corner-radii-light" "$CFG/com.system76.CosmicTheme.Light/v2/corner_radii"
  [ -e "$dir/appearance_settings" ] && cp -a "$dir/appearance_settings" "$COMP/appearance_settings"
  for k in font-name monospace-font-name icon-theme cursor-theme cursor-size gtk-theme color-scheme; do
    [ -e "$dir/gsettings-$k.txt" ] || continue
    val="$(cat "$dir/gsettings-$k.txt")"
    gsettings set org.gnome.desktop.interface "$k" "$val" 2>/dev/null || true
  done
  # Keep the resolved theme font/icon fields in step with the restored
  # gsettings, otherwise the settings daemon syncs the old profile back.
  local font_val mono_val icon_val font_family mono_family
  font_val="$(gsettings get org.gnome.desktop.interface font-name 2>/dev/null || true)"
  mono_val="$(gsettings get org.gnome.desktop.interface monospace-font-name 2>/dev/null || true)"
  icon_val="$(gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null || true)"
  font_val="${font_val#\'}"; font_val="${font_val%\'}"; font_family="${font_val% *}"
  mono_val="${mono_val#\'}"; mono_val="${mono_val%\'}"; mono_family="${mono_val% *}"
  icon_val="${icon_val//\'/}"
  for mode in Dark Light; do
    local v2="$CFG/com.system76.CosmicTheme.$mode/v2"
    [ -d "$v2" ] || continue
    [ -n "$font_family" ] && cat > "$v2/font" <<EOF
(
    family: "$font_family",
    weight: Normal,
    stretch: Normal,
    style: Normal,
)
EOF
    [ -n "$mono_family" ] && cat > "$v2/mono_font" <<EOF
(
    family: "$mono_family",
    weight: Normal,
    stretch: Normal,
    style: Normal,
)
EOF
    [ -n "$icon_val" ] && printf '"%s"\n' "$icon_val" > "$v2/icon_theme"
  done
  bash "$REPO/scripts/gtk-radius.sh" apply --quiet
  restart_panel
  say "Reverted live appearance."
}

case "${1:-apply}" in
  apply) apply_all ;;
  sync) sync ;;
  install-sync) sync; install_sync ;;
  remove-sync) remove_sync ;;
  panel) apply_panel ;;
  comp) apply_comp ;;
  gtk) apply_gtk ;;
  tk) apply_theme_fonts; apply_tk ;;
  icons) apply_icons ;;
  cursor) apply_cursor ;;
  revert) revert ;;
  doctor) doctor ;;
  tokens) printf '%s\n' "ui=$UI_FONT $UI_SIZE mono=$MONO_FONT $MONO_SIZE radii=$RADIUS_XS/$RADIUS_S/$RADIUS_M/$RADIUS_L dock=$DOCK_SIZE/$DOCK_RADIUS/$DOCK_OPACITY cursor=$CURSOR_THEME" ;;
  *) echo "usage: appearance.sh [apply|panel|gtk|tk|icons|cursor|revert|doctor|tokens]" >&2; exit 2 ;;
esac
