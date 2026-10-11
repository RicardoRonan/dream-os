#!/usr/bin/env bash
# Dream OS - keyboard shortcuts. Adds Super+L lock and a full window-management set.
# User-space only. Backs up the previous custom bindings.
set -euo pipefail

DIR="$HOME/.config/cosmic/com.system76.CosmicSettings.Shortcuts/v1"
mkdir -p "$DIR"
[ -f "$DIR/custom" ] && cp -a "$DIR/custom" "$DIR/custom.bak.$(date +%Y%m%d-%H%M%S)"

cat > "$DIR/custom" <<EOF
{
    // Session / system
    (modifiers: [Super, Alt], key: "Escape"): Terminate,
    (modifiers: [Super, Shift], key: "Escape"): System(LogOut),
    (modifiers: [Super], key: "Escape"): System(LockScreen),
    (modifiers: [Super], key: "l", description: Some("Lock Screen")): System(LockScreen),
    (modifiers: [Super], key: "q"): Close,
    (modifiers: [Alt], key: "F4"): Close,

    // Focus / move windows
    (modifiers: [Super], key: "Left"): Focus(Left),
    (modifiers: [Super], key: "Right"): Focus(Right),
    (modifiers: [Super], key: "Up"): Focus(Up),
    (modifiers: [Super], key: "Down"): Focus(Down),
    (modifiers: [Super, Shift], key: "Left"): Move(Left),
    (modifiers: [Super, Shift], key: "Right"): Move(Right),
    (modifiers: [Super, Shift], key: "Up"): Move(Up),
    (modifiers: [Super, Shift], key: "Down"): Move(Down),

    // Workspaces
    (modifiers: [Super], key: "1"): Workspace(1),
    (modifiers: [Super], key: "2"): Workspace(2),
    (modifiers: [Super], key: "3"): Workspace(3),
    (modifiers: [Super], key: "4"): Workspace(4),
    (modifiers: [Super], key: "5"): Workspace(5),
    (modifiers: [Super], key: "6"): Workspace(6),
    (modifiers: [Super], key: "7"): Workspace(7),
    (modifiers: [Super], key: "8"): Workspace(8),
    (modifiers: [Super], key: "9"): Workspace(9),
    (modifiers: [Super], key: "0"): LastWorkspace,
    (modifiers: [Super, Shift], key: "1"): MoveToWorkspace(1),
    (modifiers: [Super, Shift], key: "2"): MoveToWorkspace(2),
    (modifiers: [Super, Shift], key: "3"): MoveToWorkspace(3),
    (modifiers: [Super, Shift], key: "4"): MoveToWorkspace(4),
    (modifiers: [Super, Shift], key: "5"): MoveToWorkspace(5),
    (modifiers: [Super, Shift], key: "6"): MoveToWorkspace(6),
    (modifiers: [Super, Shift], key: "7"): MoveToWorkspace(7),
    (modifiers: [Super, Shift], key: "8"): MoveToWorkspace(8),
    (modifiers: [Super, Shift], key: "9"): MoveToWorkspace(9),
    (modifiers: [Super, Shift], key: "0"): MoveToLastWorkspace,
    (modifiers: [Super, Ctrl], key: "Left"): PreviousWorkspace,
    (modifiers: [Super, Ctrl], key: "Right"): NextWorkspace,

    // Window arrangement
    (modifiers: [Super], key: "o"): ToggleOrientation,
    (modifiers: [Super], key: "s"): ToggleStacking,
    (modifiers: [Super], key: "y"): ToggleTiling,
    (modifiers: [Super], key: "g"): ToggleWindowFloating,
    (modifiers: [Super], key: "x"): SwapWindow,
    (modifiers: [Super], key: "m"): Maximize,
    (modifiers: [Super], key: "F11"): Fullscreen,
    (modifiers: [Super], key: "r"): Resizing(Outwards),
    (modifiers: [Super, Shift], key: "r"): Resizing(Inwards),

    // Windows / overview / apps
    (modifiers: [Super], key: "a"): System(AppLibrary),
    (modifiers: [Super], key: "w"): System(WorkspaceOverview),
    (modifiers: [Super], key: "slash"): System(Launcher),
    (modifiers: [Super]): System(Launcher),
    (modifiers: [Alt], key: "Tab"): System(WindowSwitcher),
    (modifiers: [Alt, Shift], key: "Tab"): System(WindowSwitcherPrevious),
    (modifiers: [Super], key: "Tab"): System(WindowSwitcher),
    (modifiers: [Super, Shift], key: "Tab"): System(WindowSwitcherPrevious),
    (modifiers: [Super], key: "b"): System(WebBrowser),
    (modifiers: [Super], key: "f"): System(HomeFolder),
    (modifiers: [Super], key: "t"): System(Terminal),
    (modifiers: [Super], key: "space"): System(InputSourceSwitch),

    // Dream OS
    (modifiers: [Super], key: "v", description: Some("Clipboard History")): Spawn("$HOME/.local/bin/clip-pick"),

    // Media / hardware keys
    (modifiers: [], key: "Print"): System(Screenshot),
    (modifiers: [], key: "XF86AudioRaiseVolume"): System(VolumeRaise),
    (modifiers: [], key: "XF86AudioLowerVolume"): System(VolumeLower),
    (modifiers: [], key: "XF86AudioMute"): System(Mute),
    (modifiers: [], key: "XF86AudioMicMute"): System(MuteMic),
    (modifiers: [], key: "XF86MonBrightnessUp"): System(BrightnessUp),
    (modifiers: [], key: "XF86MonBrightnessDown"): System(BrightnessDown),
    (modifiers: [], key: "XF86AudioPlay"): System(PlayPause),
    (modifiers: [], key: "XF86AudioPrev"): System(PlayPrev),
    (modifiers: [], key: "XF86AudioNext"): System(PlayNext),
    (modifiers: [], key: "XF86PowerOff"): System(PowerOff),
}
EOF
echo "Shortcuts written (Super+L = lock; window arrangement enabled)."
