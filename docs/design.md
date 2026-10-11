# Design

Dream OS is a **monochrome** theme: a pure grayscale base, with a **single**
color (the accent) as the only chroma. Depth comes from hairlines and flat
surface steps, not shadows.

## Principles

- **One color.** Everything is neutral except the accent, so any accent the user
  picks stays in harmony.
- **Lines, not shadows.** Windows use a 1px hairline border and rounded corners
  (`clip_floating_windows` on) instead of drop shadows.
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
| corner radii | 8px small / 16px medium / 32px large |
| spacing | Standard density (`space_m` = 24) |
| focus ring | accent, 2px |
| tiled gaps | (0, 8) |

## How it is applied

Authoring happens in `theme/dream-os-{dark,light}.ron` (a COSMIC `ThemeBuilder`).
COSMIC expands these into the resolved theme and writes it to
`~/.config/cosmic/com.system76.CosmicTheme.{Dark,Light}/v2/` using hex color
strings. The apply step is:

```bash
cosmic-settings appearance import theme/dream-os-dark.ron
cosmic-settings appearance import theme/dream-os-light.ron
```

Colors are derived by COSMIC from a few seeds via OKLCH (hover, pressed,
disabled, on-text), so the `.ron` only carries seeds. To change the look, edit the
seeds and re-import; both faces stay in sync.

## Accent

`accent` is the one user-swappable seed. Users change it in Settings -> Desktop ->
Appearance (curated palette + custom picker); the change re-derives the whole
theme while preserving contrast.
