# Dream OS Rice

A second flavour of Dream OS: a **rice** (you own the shell) built on **niri** (scrolling
tiling compositor) + **DankMaterialShell (DMS)** + **Matugen** for global app theming.
It runs **alongside COSMIC** — pick the session at login.

## Why this stack

- **niri** — smooth scrolling tiling, per-monitor dynamic workspaces, written in Rust.
- **DankMaterialShell** — complete shell: bar, launcher, control center, notifications, lock,
  OSD, CLI/IPC, plugins. Quickshell-based, works on niri/Hyprland/Sway/etc.
- **Matugen** — themes GTK, Qt, Firefox, terminal to one palette, so the whole desktop matches.
- **Dank Greeter** — greetd login screen that lists both COSMIC and niri.

### Why not Noctalia v5 here

Noctalia v5 is not packaged for Pop!_OS 24.04 (noble) and needs `sdbus-c++ >= 2.x` (noble has
1.4.0). It stays the target for Arch/Fedora/openSUSE/Ubuntu 26.04 installs.

## Install

```bash
bash rice/install-rice.sh          # deps (sudo) + configs (user-space)
bash rice/install-rice.sh configs  # only re-copy configs
```

Per-distro package sources:

| Distro | niri | DMS | Matugen |
|---|---|---|---|
| Debian/Ubuntu | `ppa:avengemedia/danklinux` | `ppa:avengemedia/dms` | apt |
| Fedora | `dnf copr avengemedia/dms` → `niri` | `dms` | dnf |
| Arch | `pacman -S niri` | `dms-shell-niri` | pacman |
| openSUSE | OBS | DMS OBS repo | zypper |

## Login screen (Dank Greeter) — read this first

COSMIC's greeter **is** greetd-based: `cosmic-greeter.service` is aliased as
`display-manager.service`. **Disabling it removes your login screen** and drops you to a TTY.

**Never disable `cosmic-greeter` until the replacement is installed and confirmed working.**

If you lose the login screen, recover from a TTY (Ctrl+Alt+F3):

```bash
sudo systemctl enable cosmic-greeter
sudo systemctl start cosmic-greeter
# if the alias is missing:
sudo ln -sf /usr/lib/systemd/system/cosmic-greeter.service /etc/systemd/system/display-manager.service
sudo systemctl daemon-reload
sudo systemctl start cosmic-greeter
```

Once `dms-greeter` is installed **and tested**, switch greetd's config (not by disabling
cosmic-greeter): set the `[general] service` / `[default_session]` in `/etc/greetd/*.toml` to the
DMS greeter, and keep the COSMIC session listed.

## Config locations

- niri: `~/.config/niri/config.kdl` (source: `rice/niri/config.kdl`)
- DMS: `~/.config/DankMaterialShell` (edit via the shell UI)
- Matugen templates: `~/.config/matugen` (DMS manages)

## Dream OS identity

- Palette: set DMS to the Dream OS scheme (pure grayscale + Signal-blue `#4C8DFF`).
- Wallpaper: `assets/wallpapers/dream-os-dark.svg` / `-light.svg`.
- Terminal: Ghostty, themed to match.

## Caveats

- **niri has no window blur** (DMS gives shell blur only). Window blur needs Hyprland/Umbriel.
- niri/DMS packages on some distros are community-maintained — keep **COSMIC as the fallback
  session** so a bad update can't lock you out.
- DMS + plugins add resource use; lighter than Caelestia/end-4.

## Keybinds (default)

| Key | Action |
|---|---|
| `Super+Enter` | terminal (ghostty) |
| `Super+D` | launcher |
| `Super+Q` | close window |
| `Super+H/J/K/L` | focus column / window |
| `Super+Shift+H/J/K/L` | move column / window |
| `Super+1…9` | workspace |
| `Super+Shift+1…9` | move to workspace |
| `Super+O` | overview |
| `Super+Shift+E` | quit niri |
