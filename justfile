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

# macOS-like hot corners (waycorner)
corners:
    bash install/06-hotcorners.sh

# Keyboard shortcuts (Super+L lock, window arrangement)
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
