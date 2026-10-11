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
check "Vimix cursors"       "test -d $HOME/.local/share/icons/Vimix-cursors -o -d $HOME/.icons/Vimix-cursors"

echo "-- features --"
check "clipboard (cliphist)" "command -v cliphist"
check "clipboard picker (wofi)" "command -v wofi"
check "clip-pick bound"      "grep -q clip-pick '$CFG/com.system76.CosmicSettings.Shortcuts/v1/custom'"
check "libinput-gestures"   "command -v libinput-gestures"
check "kdeconnect"          "command -v kdeconnect-cli"
check "ydotool"             "command -v ydotool"

echo
echo "$pass passed, $fail missing"
[ "$fail" -eq 0 ]
