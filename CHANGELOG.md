# Changelog

All notable changes to Dream OS are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Rice flavour** scaffold (`rice/`) — niri + DankMaterialShell (+ Matugen), running
  alongside COSMIC with Dank Greeter. See `rice/`.
- Distro-detection library for the installer (`install/lib/distro.sh`) covering
  apt, dnf, pacman and zypper.
- Bundled fallback font (Inter) under `assets/fonts/`, installed to `~/.local/share/fonts`.
- `screenshots/` gallery directory.

## [0.1.0] - 2026-10-12

### Added
- **Theme core** — pure-grayscale base with a single user-swappable accent:
  - Obsidian (dark, `#000000`) and Titan (light, `#FFFFFF`), tuned independently.
  - Default accent Signal blue `#4C8DFF`; curated accent palette + custom picker.
  - Muted functional semantics; accent-coloured 2px focus ring.
  - Standard density; corner radius standardised to 16 across all tiers.
- **macOS-like layout** — thin top menu bar + centred translucent dock.
  - Bar: Logo Menu · Workspaces · Clipboard · [centred clock] · WiFi · Bluetooth ·
    quick-settings · battery · notifications.
  - Dock: auto-hide, centred, 0.5 opacity, 16px radius.
- **Identity** — Papirus icons with grey folders; Vimix cursors; procedural
  hairline-grid wallpapers (dark + light); SF Pro Text UI font.
- **Features** — Logo Menu (hamburger icon) with launcher + power actions; clipboard
  history (Super+V); hot corners (waycorner); 3-finger gestures (libinput-gestures);
  utility applets (caffeine, privacy, sysinfo, pomodoro).
- **Session persistence** — systemd timer snapshots running apps; autostart restores
  them at login (`~/.config/dream-os/session-apps`).
- **Shortcuts** — Super+L locks; full window-arrangement set (Super+arrows, Shift+arrows,
  M/G/Y/X, workspaces 1-9).
- **Cross-app sync** — GTK font/cursor/icon settings; Qt platform theme; COSMIC
  auto-exports GTK/Qt colours.
- **Icon overrides** — DreamOS theme (inherits Papirus) with clearer lock/log-out/
  suspend/reboot/shutdown and bold window-control glyphs.
- **Greeter patch** (`patches/cosmic-greeter-center-login.patch`) — centres the login
  block on the greeter **and** the lock screen (Pop/apt source build).
- **Docs** — `docs/` design, features, fonts, perf, greeter.
- **Tooling** — `justfile`, `bootstrap.sh`, `scripts/doctor.sh`,
  `scripts/greeter-center.sh` (build/install/rollback).

### Changed
- Corner radius unified to 16 (was 8/16/32); OSD toasts and window controls match.
- Clock/calendar moved to the centre of the menu bar.
- Active-window ring changed from the accent to a neutral grey (accent was too harsh).

### Fixed
- Papirus folder colour now set as root (system install).
- System package script no longer aborts on a single unavailable package;
  `libinput-gestures` installed from source where unpackaged.
- Logo Menu custom icon loads (SVG placed inside the sandboxed applet's config dir).

### Performance
- Frosted glass reduced: System-interface + applet blur off, strength Low, dock-only.
  Fixes workspace-overview lag on the Intel iGPU.

[Unreleased]: https://github.com/RicardoRonan/dream-os/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/RicardoRonan/dream-os/releases/tag/v0.1.0
