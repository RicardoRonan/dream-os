# Dream OS

A clean, monochrome COSMIC desktop theme with a single, user-swappable accent.
Pure grayscale base (true black `#000` / true white `#FFF`), hairline borders,
and one signal color. Plus a curated set of OS-like features (clipboard history,
hot corners, spotlight launcher).

Built for Pop!_OS 24.04 / COSMIC (Wayland). User-space first: nothing touches the
bootloader, kernel, or drivers.

## Screenshots

| Obsidian (dark) | Titan (light) |
|---|---|
| ![Dark](assets/screenshots/dark.png) | ![Light](assets/screenshots/light.png) |

## Theme

- **Obsidian** (dark, `#000000`) and **Titan** (light, `#FFFFFF`), tuned as two
  independent faces rather than a naive inversion.
- Pure neutral grayscale (no color cast); the accent is the only chroma.
- Accent default **Signal blue `#4C8DFF`**; users change it in
  Settings -> Desktop -> Appearance (curated palette + custom picker).
- Accent-colored 2px focus ring; hairlines instead of shadows; Standard density;
  8-16px corners.
- Fonts: **SF Pro Text** (UI), **SF Mono** (terminal/code).

## What it installs

| Phase | Script | Contents |
|-------|--------|----------|
| 00 system | `install/00-system-apt.sh` | Papirus icons + grey folders, Vimix cursors, libinput-gestures, kdeconnect, ydotool (needs sudo) |
| 01 theme | `install/01-theme.sh` | Obsidian/Titan theme seeds, `.ron` import, density |

More phases (identity, desktop layout, features, cross-app sync) land here as
they are built.

## Usage

```bash
# 1. system packages (once, needs sudo)
sudo bash install/00-system-apt.sh

# 2. user-space phases
bash bootstrap.sh
# or:
just install

# just the theme
just theme

# verify
just doctor
```

## Layout

```
bootstrap.sh                 entrypoint
justfile                     install / theme / doctor / system
install/                     phased installers
theme/                       Dream OS .ron theme exports (source of truth)
assets/                      wallpapers, cursors
scripts/doctor.sh            pass/fail verification
```

## Notes

- **User-space only.** Backups land beside originals as `<name>.bak.<ts>`, with a
  full pre-change snapshot in `~/.dotfiles-backup-<ts>/`.
- Everything is idempotent; re-running is safe.
- Themes are authored by importing `theme/*.ron` via
  `cosmic-settings appearance import`.

## Rollback

Restore `~/.config/cosmic/` from the `~/.dotfiles-backup-<ts>/` snapshot, then
restart the session.
