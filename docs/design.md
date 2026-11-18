# Design

Dream OS is a **monochrome** theme: a pure grayscale base, with a **single**
color (the accent) as the only chroma. Depth comes from hairlines and flat
surface steps, not shadows.

## Principles

- **One color.** Everything is neutral except the accent, so any accent the user
  picks stays in harmony.
- **Lines, not shadows.** Windows use a 1px hairline border and 16px corners,
  not drop shadows. Tiled and maximized windows stay square.
- **Two independent faces.** Obsidian (dark) and Titan (light) are tuned
  separately, not a naive inversion.
- **Legibility first.** SF Pro Text for UI, SF Mono for code.

## Tokens

### Obsidian (dark)

| Token | Value | Role |
|-------|-------|------|
| background | `#000000` | true black base |
| primary container | `#0D0D0D` | cards / panels |
| secondary container | `#171717` | higher elevation |
| text tint | `#F2F2F2` | near-white text |
| accent | `#4C8DFF` | default (Signal blue) |
| success / warning / destructive | `#4C9A5E` / `#C79A3A` / `#C75C5C` | muted, functional |

### Titan (light)

| Token | Value | Role |
|-------|-------|------|
| background | `#FFFFFF` | true white base |
| primary container | `#F7F7F7` | cards / panels |
| secondary container | `#EFEFEF` | higher elevation |
| text tint | `#0A0A0A` | near-black text |
| accent | `#2F6FE0` | default (light-mode blue) |

### Shape & density (both)

| Token | Value |
|-------|-------|
| corner radii | 6px xs / 8px s / 12px m / 16px l; 0 for flush edges; 160px pills |
| dock | 12px (matches window corners) |
| spacing | Standard density (`space_m` = 24) |
| active window hint | grey, 1px |
| tiled gaps | (0, 8) |

### Radius

The radius scale is concentric, not one value everywhere:

- `6px` for checkboxes, icon buttons and tags.
- `8px` for inputs, menu items and small cards.
- `12px` for windows, popovers, dialogs, cards and the floating dock.
- `16px` for large sheets.
- `0` for the full-width top bar and for tiled, maximized and fullscreen windows.
- `160px` (`radius_xl`) for pill controls.

GTK apps do not read the COSMIC theme, so `configs/gtk/gtk-radius.css` is appended
to `~/.config/gtk-{3,4}.0/gtk.css` by `scripts/gtk-radius.sh`. COSMIC rewrites
those files whenever the theme or accent changes, so a systemd user timer
re-applies the block every two minutes. Re-run it by hand with `just gtk-radius`.
A path unit was tried first, but it watched the same files the service writes
and could hit systemd's start limit.

### macOS profile

`scripts/appearance.sh` is the single source of truth for the macOS-structure
profile. It writes the same tokens to COSMIC, CosmicTk, the panel, the dock,
GTK 3/4, Flatpak and gsettings:

- Top bar: full width, flush, XS, opaque, clock at the far right.
- Dock: 48px icons (size L), 12px radius, 0.5 opacity, 8px spacing, 8px padding,
  auto-hide always, 4px margin and an 8px reveal handle. With the optional
  patched panel the handle is 16px and stays invisible until hover. It does not
  reserve space, so maximized windows fill the screen behind it. The top bar
  still reserves its 32px menu bar.
- Icons: DreamOS overrides inherit `WhiteSur-grey-dark`, then Papirus and
  hicolor. COSMIC app IDs are mapped to WhiteSur squircles in
  `configs/icons/cosmic-app-map.tsv`.
- Cursor: `Vimix-cursors` at 24px, kept from the base theme.
- Fonts: SF Pro Text 10.5 (about 14px), JetBrainsMono Nerd Font 10.5.
- Header bars: `Compact` density; interface density stays `Standard`.
- Floating windows are clipped to the 12px theme radius, so app-drawn
  borders (Firefox, OpenCode, Electron) follow the same corners. Tiled
  windows stay square.
- A two-minute user timer resyncs the theme font/icon fields after COSMIC
  regenerates the resolved theme on login or accent changes.

Apply with `just macos`; revert the live settings with `just macos-revert`.
The full profile is optional. The base theme still works without it.

## How it is applied

Authoring happens in `configs/cosmic/dream-os-{dark,light}.ron` (a COSMIC `ThemeBuilder`).
COSMIC expands these into the resolved theme and writes it to
`~/.config/cosmic/com.system76.CosmicTheme.{Dark,Light}/v2/` using hex color
strings. The apply step is:

```bash
cosmic-settings appearance import configs/cosmic/dream-os-dark.ron
cosmic-settings appearance import configs/cosmic/dream-os-light.ron
```

Colors are derived by COSMIC from a few seeds via OKLCH (hover, pressed,
disabled, on-text), so the `.ron` only carries seeds. To change the look, edit the
seeds and re-import; both faces stay in sync.

## Accent

`accent` is the one user-swappable seed. Users change it in Settings -> Desktop ->
Appearance (curated palette + custom picker); the change re-derives the whole
theme while preserving contrast.
