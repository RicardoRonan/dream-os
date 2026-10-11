set shell := ["bash", "-uc"]

# Run every user-space phase
install:
    bash install/01-theme.sh

# Apply the Dream OS COSMIC theme (Dark Obsidian + Light Titan)
theme:
    bash install/01-theme.sh

# Verify installed tooling and applied theme
doctor:
    bash scripts/doctor.sh

# System packages (requires sudo)
system:
    sudo bash install/00-system-apt.sh

# Show available recipes
default:
    @just --list
