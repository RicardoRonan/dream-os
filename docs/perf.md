# Performance

Dream OS aims to stay smooth on integrated GPUs (ThinkPad P15: Intel UHD +
Quadro T1000). The main cost in COSMIC is **frosted-glass blur**, which is
recomputed per frame.

## Current posture

| Setting | Value | Why |
|---------|-------|-----|
| `frosted` (strength) | **ExtremelyLow** | cheapest visible blur |
| `frosted_panel` | on | the dock glass (visible only when the dock shows) |
| `frosted_system_interface` | **off** | the workspace overview / launcher blur the whole desktop each frame — the main lag source |
| `frosted_applets` | **off** | popups don't need blur |
| `frosted_windows` | **off** | floating COSMIC windows stay opaque |
| `frosted_maximized_apps` | on | maximized COSMIC windows stay translucent |
| Panel opacity | 1.0 | top bar is opaque (no blur needed) |
| Dock opacity | 0.5 | translucent; shows the wallpaper through it |
| Dock size | L (48px icons) | macOS-like; larger icons, same blur area |

Blur therefore covers the dock, floating windows and maximized COSMIC windows.
The top bar stays opaque and the workspace overview (Super+W) does not blur.
GTK, Electron and XWayland apps decide their own window background, so many of
them stay opaque even when the theme enables frosted windows.

## Hybrid GPU buffer imports

On ThinkPad P15, `cosmic-comp` renders on NVIDIA `renderD129` while some app
buffers come from Intel `renderD128` with `I915_y_tiled_ccs`. COSMIC cannot import
those buffers and logs `Failed to render texture ... import for wrong devices`.
That drops frames independently of blur. Upstream reports:
[cosmic-comp#2782](https://github.com/pop-os/cosmic-comp/issues/2782),
[#2658](https://github.com/pop-os/cosmic-comp/issues/2658),
[#2752](https://github.com/pop-os/cosmic-comp/issues/2752).

`scripts/appearance.sh` sets `INTEL_DEBUG=noccs` in
`~/.config/environment.d/dream-os.conf` and in the user Flatpak override. This
stops Intel CCS buffers from being produced. It takes effect after logout/login.
Check with:

```bash
journalctl --user -b -o cat -g 'Failed to render texture' | wc -l
```

Panel and dock layer settings are not the bottleneck. Do not change
`exclusive_zone`, `anchor_gap`, `autohide`, fractional scaling or VRR to fix this.

## If it still stutters

Turn blur off entirely (keeps translucent surfaces, just unblurred):

```bash
# in configs/cosmic/dream-os-{dark,light}.ron set:
#   is_frosted: false,
#   frosted_panel: false,
#   frosted_windows: false,
#   frosted_maximized_apps: false,
# then:
cd ~/Projects/dream-os && just theme
```

Or via Settings -> Desktop -> Appearance -> Frosted glass (uncheck all). The
maximized-apps toggle is not exposed in COSMIC 1.11 Settings; edit the theme
file or the Builder config for that one.

## Other notes

- **macOS profile blur:** the top panel stays opaque. The dock and COSMIC
  windows are frosted. Increasing the dock to size L changes icon geometry, not
  the blur area. If large windows stutter, set `frosted_windows: false` and
  `frosted_maximized_apps: false` first; if the dock itself stutters, set
  `frosted_panel: false` and raise dock opacity to 0.85.
- **GTK radius timer:** `dream-os-gtk-radius.timer` runs every two minutes and
  exits immediately when the marked radius block is already present.

- **Applets are per-output.** With two monitors, each panel applet runs once per
  monitor (status area, clock, battery, etc.). That is normal, not a leak.
- Orphaned applets can survive a panel restart. If counts look inflated:
  ```bash
  for p in $(pgrep -f 'cosmic-applet-|cosmic-ext-applet-'); do kill "$p"; done
  pkill -x cosmic-panel   # session restarts it cleanly
  ```
  (Use `pkill -f`, not `pkill -x`: process names truncate at 15 chars.)
- **Display scale:** keep integer scaling (100%/200%). Fractional scaling costs
  more on iGPUs.
- **Wallpaper:** a raster image (JPEG/PNG) costs less than a large styled SVG.
- **Animations:** COSMIC 1.10 has no user-facing "reduced motion" switch yet.
- **Hot corners / gestures** (`waycorner`, `libinput-gestures`) are lightweight;
  disable them only if you don't use them.

## Animations

COSMIC 1.10 exposes **no user-facing animation settings** — animations are the
compositor's job and land in a later Epoch (2/3 upstream). The only tunable
transition is the dock/panel hide-show animation:

`~/.config/cosmic/com.system76.CosmicPanel.Dock/v1/autohide_behavior`
- `transition_time` (ms) — slide duration
- `wait_time` (ms) — delay before hiding
- `unhide_delay` (ms) — delay before showing
- `handle_size` (px) — height of the hidden strip that catches the pointer

Dream OS uses `transition_time: 200`, `unhide_delay: 0` and a reveal handle of
8px with the stock panel, or 16px with the optional patched panel (the strip
stays transparent until hover). It also sets `margin: 4` (and `anchor_gap: true`):
the hidden strip sits at the very bottom edge instead of 12 px above it.

### Dock reveal on multiple displays

COSMIC 1.10/1.11 can fail to reveal an auto-hidden dock on a display that is
stacked vertically, because the bottom-edge hover area is hit-tested against the
wrong output. Upstream: `pop-os/cosmic-panel#656`. A small `margin`, a larger
`handle_size` and `unhide_delay: 0` make the strip much easier to hit, but the
root cause is in cosmic-comp. The optional invisible-handle patch only removes
the visible tab; it does not change hit-testing. Moving the affected output a
few pixels vertically in Display settings is the upstream workaround.
