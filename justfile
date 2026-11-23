set shell := ["bash", "-uc"]

# Run every user-space phase
install:
    bash install/01-theme.sh
    bash install/02-identity.sh
    bash install/03-desktop.sh
    bash install/04-features.sh
    bash install/05-crossapp.sh
    bash install/06-hotcorners.sh
    bash install/07-shortcuts.sh
    bash install/08-session.sh
    bash install/09-power-icons.sh

# Apply the Dream OS COSMIC theme (Dark Obsidian + Light Titan)
theme:
    bash install/01-theme.sh

# Wallpaper, cursors, icons
identity:
    bash install/02-identity.sh

# macOS-like panel + dock
desktop:
    bash install/03-desktop.sh

# Applets, gestures, features
features:
    bash install/04-features.sh

# GTK/Qt/font sync for third-party apps
crossapp:
    bash install/05-crossapp.sh

# Apply the macOS-structure appearance profile (WhiteSur icons, keep cursor)
macos:
    bash scripts/install-whitesur.sh --icons-only
    bash scripts/appearance.sh apply

# Revert the live appearance to the last backup
macos-revert:
    bash scripts/appearance.sh revert

# Show the live appearance values
appearance:
    bash scripts/appearance.sh doctor

# Re-apply the theme GTK corner radii after a theme change
gtk-radius:
    bash scripts/gtk-radius.sh apply

# macOS-like hot corners (waycorner)
corners:
    bash install/06-hotcorners.sh

# Map mouse back/forward buttons (needs the input group)
mouse:
    bash scripts/mouse-buttons.sh

# Prefer SBC-XQ on Bluetooth devices that offer the profile
bt-xq:
    bash scripts/bt-sbc-xq.sh install

# DualShock 4 battery tray ( tray icon, charging label, low-battery notify )
ds4:
    bash scripts/ds4-battery-tray.sh install
ds4-off:
    bash scripts/ds4-battery-tray.sh remove

# Local cosmic-launcher with a subtle Alt+Tab fade/settle animation
launcher-alt-tab:
    bash scripts/launcher-alt-tab-animation.sh install
launcher-alt-tab-off:
    bash scripts/launcher-alt-tab-animation.sh remove

# Disable USB autosuspend on the Intel AX201 Bluetooth adapter
bt-autosuspend:
    bash scripts/bt-no-autosuspend.sh install
bt-autosuspend-off:
    bash scripts/bt-no-autosuspend.sh remove

# Build a local cosmic-panel that hides the auto-hide handle until hover
panel-handle:
    bash scripts/panel-handle.sh install

# Restore the stock cosmic-panel and the visible 8px handle
panel-handle-off:
    bash scripts/panel-handle.sh remove

# Wider window corner grab zones (patched compositor; log out/in to apply)
compositor-corners:
    bash scripts/compositor-corner-grab.sh install

# Remove the local cosmic-comp override
compositor-corners-off:
    bash scripts/compositor-corner-grab.sh remove

# Keyboard shortcuts (Super+Space launcher, lock, window arrangement)
shortcuts:
    bash install/07-shortcuts.sh

# Session persistence (restore apps after login)
session:
    bash install/08-session.sh

# Clearer power/session icons
icons:
    bash install/09-power-icons.sh

# Install the rice flavour (niri + DankMaterialShell, needs sudo for deps)
rice:
    bash rice/install-rice.sh

# Only (re)copy the rice configs (user-space)
rice-configs:
    bash rice/install-rice.sh configs

# Dev mode: run the rice nested in a window (no logout, no GPU issues)
rice-dev:
    bash rice/dev.sh

# Remove Dream OS files (keeps backups)
uninstall:
    bash install/10-uninstall.sh

# Restore the login screen if the machine boots to a TTY (needs sudo)
fix-login:
    sudo bash scripts/restore-login-screen.sh

# Verify installed tooling and applied theme
doctor:
    bash scripts/doctor.sh

# System packages (requires sudo)
system:
    sudo bash install/00-system-apt.sh

# Show available recipes
default:
    @just --list
