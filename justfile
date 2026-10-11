set shell := ["bash", "-uc"]

# Run every user-space phase
install:
    bash install/01-theme.sh
    bash install/02-identity.sh
    bash install/03-desktop.sh
    bash install/04-features.sh

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

# Verify installed tooling and applied theme
doctor:
    bash scripts/doctor.sh

# System packages (requires sudo)
system:
    sudo bash install/00-system-apt.sh

# Show available recipes
default:
    @just --list
