#!/usr/bin/env bash
# Dream OS doctor - verify installed tooling and applied theme.
set -u

CFG="$HOME/.config/cosmic"
pass=0; fail=0
check() {
  local name="$1" cmd="$2"
  if eval "$cmd" >/dev/null 2>&1; then
    printf "  \033[32mOK\033[0m   %s\n" "$name"; pass=$((pass+1))
  else
    printf "  \033[31mMISS\033[0m %s\n" "$name"; fail=$((fail+1))
  fi
}

echo "Dream OS doctor"

echo "-- theme --"
check "cosmic-settings"     "command -v cosmic-settings"
check "dark theme applied"  "grep -q 'dream-os-dark' '$CFG/com.system76.CosmicTheme.Dark/v2/name'"
check "light theme applied" "grep -q 'dream-os-light' '$CFG/com.system76.CosmicTheme.Light/v2/name'"
check "dark bg is #000000"  "grep -q '#000000FF' '$CFG/com.system76.CosmicTheme.Dark/v2/background'"
check "light bg is #FFFFFF" "grep -q '#FFFFFFFF' '$CFG/com.system76.CosmicTheme.Light/v2/background'"

echo "-- fonts --"
check "SF Pro Text"         "fc-list | grep -qi 'SF Pro Text'"
check "SF Mono"             "fc-list | grep -qi 'SF Mono'"
check "JetBrains Mono (fallback)" "fc-list | grep -qi 'JetBrainsMono'"

echo "-- identity --"
check "Papirus icons"       "test -d /usr/share/icons/Papirus"
check "cursor theme installed" "test -d $HOME/.local/share/icons/WhiteSur-cursors -o -d $HOME/.local/share/icons/Vimix-cursors"
check "icon theme is DreamOS" "gsettings get org.gnome.desktop.interface icon-theme | grep -q DreamOS"
check "DreamOS theme installed" "test -f $HOME/.local/share/icons/DreamOS/index.theme"
check "hicolor index complete" "grep -q '^\[scalable/apps\]' $HOME/.local/share/icons/hicolor/index.theme"

echo "-- appearance --"
check "header Compact" "grep -q Compact '$CFG/com.system76.CosmicTk/v1/header_size'"
check "theme applied globally" "grep -q true '$CFG/com.system76.CosmicTk/v1/apply_theme_global'"
check "WhiteSur icons" "test -d $HOME/.local/share/icons/WhiteSur-grey-dark"
check "WhiteSur cursor" "test -d $HOME/.local/share/icons/WhiteSur-cursors"
check "dock L / 24px" "grep -qx L '$CFG/com.system76.CosmicPanel.Dock/v1/size' && grep -qx 24 '$CFG/com.system76.CosmicPanel.Dock/v1/border_radius'"
check "dock always hides" "grep -qx Always '$CFG/com.system76.CosmicPanel.Dock/v1/autohide'"
check "dock overlays windows" "grep -qx false '$CFG/com.system76.CosmicPanel.Dock/v1/exclusive_zone'"
check "panel full width / flush" "grep -qx true '$CFG/com.system76.CosmicPanel.Panel/v1/expand_to_edges' && grep -qx 0 '$CFG/com.system76.CosmicPanel.Panel/v1/margin'"
check "clock on the right" "grep -q CosmicAppletTime '$CFG/com.system76.CosmicPanel.Panel/v1/plugins_wings' && ! grep -q CosmicAppletTime '$CFG/com.system76.CosmicPanel.Panel/v1/plugins_center'"
check "radius scale 6/8/12/16" "grep -q 'radius_xs: (6.0' '$CFG/com.system76.CosmicTheme.Dark/v2/corner_radii' && grep -q 'radius_m: (12.0' '$CFG/com.system76.CosmicTheme.Dark/v2/corner_radii'"
check "GTK radius block" "grep -q 'dream-os-radius' $HOME/.config/gtk-4.0/gtk.css"
check "radius timer" "systemctl --user is-enabled dream-os-gtk-radius.timer"

echo "-- features --"
check "clipboard (cliphist)" "command -v cliphist"
check "clipboard picker (wofi)" "command -v wofi"
check "clip-pick bound"      "grep -q clip-pick '$CFG/com.system76.CosmicSettings.Shortcuts/v1/custom'"
check "libinput-gestures"   "command -v libinput-gestures"
check "kdeconnect"          "command -v kdeconnect-cli"
check "ydotool"             "command -v ydotool"

echo "-- notifications --"
check "cosmic-notifications owns Notifications" "busctl --user status org.freedesktop.Notifications 2>/dev/null | grep -q cosmic-notifications"
check "no mako conflict"    "! systemctl --user is-active mako.service 2>/dev/null"

echo
echo "$pass passed, $fail missing"
[ "$fail" -eq 0 ]
