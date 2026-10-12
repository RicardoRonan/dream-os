# Dream OS Rice

A second flavour of Dream OS: a **rice** (you own the shell) that runs **alongside COSMIC** —
pick the session at login.

Two stacks are provided, chosen automatically by your distro:

| Distro | Stack | Because |
|---|---|---|
| Debian / Ubuntu / **Pop!_OS** / openSUSE | **Sway + Waybar** | packaged in apt/zypper |
| Fedora / Arch | **niri + DankMaterialShell (+ Matugen)** | packaged in COPR / [extra] |

## Safety (read first)

- **The rice never touches your login screen.** COSMIC's greeter is aliased as
  `display-manager.service`; removing that drops you to a bare TTY.
- `install-rice.sh` **refuses to run** if the login screen is already broken.
- If you ever boot to a TTY:
  `sudo bash scripts/restore-login-screen.sh` (or `just fix-login`).

## Install

```bash
bash rice/install-rice.sh          # deps (sudo) + configs (user-space)
bash rice/install-rice.sh configs  # only re-copy configs
```

Then log out and pick the **Sway** (or **niri**) session at the login screen.

## Sway + Waybar (this machine)

Packages: `sway swaybg swayidle swaylock waybar wofi mako-notifier grim slurp wl-clipboard
cliphist mate-polkit kitty brightnessctl pavucontrol blueman network-manager-gnome`.

Config locations (sources under `rice/`):

- Sway: `~/.config/sway/config` ← `rice/sway/config`
- Waybar: `~/.config/waybar/{config.jsonc,style.css}` ← `rice/waybar/`
- mako: `~/.config/mako/config` ← `rice/mako/config`
- wofi: `~/.config/wofi/style.css` ← `rice/wofi/style.css`

### Keybinds (Sway)

| Key | Action |
|---|---|
| `Super+Enter` | kitty |
| `Super+D` | wofi launcher |
| `Super+Q` | close window |
| `Super+arrows` / `H J K L` | focus |
| `Super+Shift+…` | move window |
| `Super+1…9` | workspace · `Super+Shift+1…9` move to workspace |
| `Super+F` | fullscreen · `Super+Shift+Space` float |
| `Super+V` | clipboard history (cliphist + wofi) |
| `Print` | region screenshot to clipboard |
| `Super+Shift+L` | lock (swaylock) |
| `Super+Shift+E` | exit Sway |

## Dream OS identity

- **Palette:** pure grayscale + Signal blue `#4C8DFF` (see `rice/waybar/style.css`).
- **Wallpaper:** `~/.local/share/backgrounds/dream-os/dream-os-dark.svg` (via swaybg).
- **Fonts:** JetBrainsMono Nerd Font for the bar; SF Pro Text / Inter for apps.

## niri + DMS (Fedora / Arch)

Config in `rice/niri/config.kdl` → `~/.config/niri/config.kdl`. DMS settings live in the shell UI.

## Caveats

- Sway is a tiling WM (not a full shell) — Waybar is CSS-themed to Dream OS.
- niri has **no window blur**; DMS gives shell blur only.
- Keep **COSMIC as the fallback session** so a bad update can't lock you out.
