# Changelog

All notable changes to Dream OS are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **macOS-structure profile**: `scripts/appearance.sh` applies one set of
  geometry, type, icon and cursor values to COSMIC, CosmicTk, the panel, the
  dock, GTK 3/4, Flatpak and gsettings. Apply with `just macos`, revert with
  `just macos-revert`.
- WhiteSur icon theme via `scripts/install-whitesur.sh`, with
  `configs/icons/cosmic-app-map.tsv` mapping COSMIC app IDs to squircle icons.
  The cursor stays Vimix.
- **Rice flavour** scaffold (`rice/`) — niri + DankMaterialShell (+ Matugen), running
  alongside COSMIC with Dank Greeter. See `rice/`.
- Distro-detection library for the installer (`install/lib/distro.sh`) covering
  apt, dnf, pacman and zypper.
- Bundled fallback font (Inter) under `assets/fonts/`, installed to `~/.local/share/fonts`.
- `screenshots/` gallery directory.
- **Mouse back/forward buttons**: `scripts/mouse-buttons.sh` installs a user
  service that maps `BTN_SIDE`/`BTN_BACK` to Alt+Left and
  `BTN_EXTRA`/`BTN_FORWARD` to Alt+Right. Needs the `input` group.
- **Bluetooth SBC-XQ**: `scripts/bt-sbc-xq.sh` installs a user service that
  selects `a2dp-sink-sbc_xq` on any BlueZ card that offers it, at login and on
  reconnect. Standard SBC remains available for manual selection.
- **Status Hub tray**: the panel uses
  `io.github.marcelogomes90.cosmic-ext-applet-status-hub` on both displays
  instead of the stock status area, clearing duplicate grey placeholder icons
  left by the COSMIC 1.11 tray bug. Falls back to the stock applet when Status
  Hub is not installed.

### Changed
- Replaced "16 px everywhere" with a concentric radius scale: 6 px small
  controls, 8 px inputs, 12 px windows and cards, 16 px large sheets, 24 px dock.
  The top bar and tiled/maximized windows stay square.
- Panel: full width and flush, XS height, opaque, clock at the far right.
- Dock: 48 px icons (size L), 24 px radius, 0.5 opacity, 8 px padding and
  spacing. The 4 px margin and 16 px reveal handle are kept for stacked displays.
- Header bars: `Compact`; interface density stays `Standard`. Monospace is now
  JetBrainsMono Nerd Font or SF Mono, not Ubuntu Mono.
- Enabled `apply_theme_global` so COSMIC colours, fonts and icons reach GTK,
  Qt, VS Code and Flatpak.
- `scripts/gtk-radius.sh` now installs a two-minute systemd timer instead of a
  path unit. The path unit watched the files its own service writes and could
  hit systemd's start limit.
- Cursor: kept **Vimix-cursors** instead of switching to WhiteSur. The macOS
  profile uses WhiteSur for icons only; `just macos` passes `--icons-only`.
- Documented the upstream multi-monitor dock reveal limitation
  (`pop-os/cosmic-panel#656`) in `docs/perf.md`.

### Fixed
- COSMIC regenerated the resolved theme on login and reset its font/icon
  fields to Open Sans and `Cosmic`, which also reset gsettings. Added a
  two-minute `dream-os-appearance.timer` that restores the SF Pro Text,
  JetBrainsMono and DreamOS values only when they drift.
- Applications icon showed a gear because the COSMIC App Library was mapped
  to WhiteSur's `applications-system` gear. Removed that mapping and added
  stale-link cleanup, so the App Library uses its stock grid icon and Settings
  keeps the gear.
- Floating window borders had square or mismatched corners on Firefox and
  OpenCode because the compositor did not clip floating windows. Set
  `clip_floating_windows=true` so the window and its own border are clipped to
  the 12px theme radius. Tiled windows stay square.
- Maximized windows stopped short of the bottom edge because the hidden dock
  still reserved its height (`exclusive_zone=true`). The dock now overlays
  windows (`exclusive_zone=false`); only the top bar reserves space.
- Dock stayed visible when no window overlapped it and could cover window tabs.
  Dock autohide is now `Always`, so it hides when the pointer leaves and only
  the 16px reveal handle remains.
- Icons: GTK apps read the `Cosmic` theme while COSMIC read `DreamOS`, and a
  two-directory `hicolor` index in `~/.local/share/icons` hid fallback icons
  such as MDViewer. `02-identity.sh` now installs the override theme, restores
  the full hicolor index, and syncs the GTK portal. Thunar and the COSMIC app
  IDs are mapped to WhiteSur squircle icons.
- Theme font and icon fields in `CosmicTheme.{Dark,Light}/v2/` were still
  Open Sans, Noto Sans Mono and `Cosmic`, which overwrote gsettings whenever
  `apply_theme_global` ran. `appearance.sh` now writes the same SF Pro Text,
  JetBrainsMono and DreamOS values into the resolved theme.
- Notifications applet missing from the top panel: the rice's packaged
  `mako.service` is enabled for every graphical session and held
  `org.freedesktop.Notifications`, so `cosmic-notifications` could not start and
  the panel never received the applet fd. The installer and the rice now mask
  `mako.service` (Sway starts mako itself) and restart the daemon.

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
