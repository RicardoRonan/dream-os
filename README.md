# Dream OS

A clean, monochrome COSMIC desktop theme with a single, user-swappable accent —
plus a **rice flavour** (niri + DankMaterialShell) for those who want to own the shell.

Pure grayscale base (true black `#000` / true white `#FFF`), hairline borders, one signal
color, and a curated set of OS-like features. User-space first: nothing touches the
bootloader, kernel, or drivers.

## Screenshots

| Obsidian (dark) | Titan (light) |
|---|---|
| ![Dark](screenshots/dark.png) | ![Light](screenshots/light.png) |

> Gallery screenshots live in `screenshots/`. (dark, light, menu + launcher,
> overview + app grid, settings + lock.)

## Two flavours

| Flavour | Stack | Runs on |
|---|---|---|
| **Theme** (default) | COSMIC desktop (RON theme + configs) | Pop!_OS / any distro with COSMIC |
| **Rice** (`rice/`) | niri + DankMaterialShell + Matugen | any distro, alongside COSMIC |

See [`rice/README.md`](rice/README.md) for the rice.

## Theme

- **Obsidian** (dark, `#000000`) and **Titan** (light, `#FFFFFF`), tuned as two independent
  faces rather than a naive inversion.
- Pure neutral grayscale (no color cast); the accent is the only chroma.
- Accent default **Signal blue `#4C8DFF`**; changed in Settings → Desktop → Appearance
  (curated palette + custom picker).
- **Concentric radius scale** 6 / 8 / 12 / 16 px, 24 px dock; Standard density;
  hairlines instead of shadows; **neutral-grey** active-window ring.
- Frosted glass limited to the dock (perf-first on integrated GPUs).
- Fonts: **SF Pro Text** (UI, falls back to bundled **Inter**), **JetBrains Mono
  Nerd Font** or **SF Mono** (terminal).

## What it installs

| Phase | Script | Contents |
|-------|--------|----------|
| 00 system | `install/00-system-apt.sh` | Papirus icons + grey folders, Vimix cursors, libinput-gestures, kdeconnect, ydotool |
| 01 theme | `install/01-theme.sh` | Obsidian/Titan seeds + `.ron` import, density |
| 02 identity | `install/02-identity.sh` | wallpaper, cursors, icons, bundled fonts |
| 03 desktop | `install/03-desktop.sh` | full-width top bar, clock right, 48px dock |
| 04 features | `install/04-features.sh` | Logo Menu, applets, gestures, mouse buttons, panel |
| 05 crossapp | `install/05-crossapp.sh` | GTK/Qt font + theme sync |
| 06 hotcorners | `install/06-hotcorners.sh` | waycorner hot corners |
| 07 shortcuts | `install/07-shortcuts.sh` | launcher, lock, window arrangement, screenshots |
| 08 session | `install/08-session.sh` | restore apps after login |
| 09 icons | `install/09-power-icons.sh` | DreamOS icon overrides |
| 10 uninstall | `install/10-uninstall.sh` | remove Dream OS user files |

## Usage

```bash
# 1. system packages (once, needs sudo)
sudo bash install/00-system-apt.sh

# 2. user-space phases
just install          # or: bash bootstrap.sh

# theme only / verify
just theme
just doctor

# rice flavour (niri + DankMaterialShell)
just rice
```

## macOS profile

The macOS-structure profile is optional and reversible. It installs WhiteSur
icons (keeping the Vimix cursor), then applies one set of geometry, type and
toolkit values:

```bash
just macos          # install WhiteSur icons if needed + apply the profile
just appearance     # show the live values
just macos-revert   # restore the last live backup
```

`scripts/appearance.sh` is the single source of truth. It writes the COSMIC
theme radii, CosmicTk, panel, dock, GTK 3/4, Flatpak and gsettings in one pass.
The core Dream OS theme still works without it.

## Layout

```
bootstrap.sh         entrypoint
justfile             install / theme / macos / rice / uninstall / doctor / system
install/             phased installers + lib/
configs/cosmic/      Dream OS .ron theme exports (source of truth)
configs/icons/       COSMIC app ID -> WhiteSur icon map
scripts/             appearance, icon map, gtk radius, doctor, greeter
assets/              wallpapers, icons, bundled fonts (Inter)
rice/                niri + DankMaterialShell flavour
screenshots/         README gallery
docs/                design, features, fonts, perf, greeter
patches/             cosmic-greeter center patch (Pop)
CHANGELOG.md
```

## Notes

- **User-space first.** Backups land beside originals as `<name>.bak.<ts>`, with a full
  pre-change snapshot in `~/.dotfiles-backup-<ts>/`.
- Everything is idempotent; re-running is safe.
- Themes are authored by importing `configs/cosmic/*.ron` via `cosmic-settings appearance import`.
- `just uninstall` removes Dream OS user files (backups kept).

## Distro support

- **Theme:** requires COSMIC installed. The installer is currently apt/Pop-centric;
  a distro-agnostic version (apt/dnf/pacman/zypper) is planned.
- **Rice:** distro-agnostic — see `rice/`.

## Changelog

See [CHANGELOG.md](CHANGELOG.md).
