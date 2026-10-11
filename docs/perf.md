# Performance

Dream OS aims to stay smooth on integrated GPUs (ThinkPad P15: Intel UHD +
Quadro T1000). The main cost in COSMIC is **frosted-glass blur**, which is
recomputed per frame.

## Current posture

| Setting | Value | Why |
|---------|-------|-----|
| `frosted` (strength) | **Low** | cheapest visible blur |
| `frosted_panel` | on | the dock/panel glass (visible only when the dock shows) |
| `frosted_system_interface` | **off** | the workspace overview / launcher blur the whole desktop each frame — the main lag source |
| `frosted_applets` | **off** | popups don't need blur |
| `frosted_windows` | off | windows are opaque |
| Panel opacity | 1.0 | top bar is opaque (no blur needed) |
| Dock opacity | 0.5 | translucent; shows the wallpaper through it |

So blur is limited to the dock, and only while it is visible (it auto-hides on
overlap). The workspace overview (Super+W) no longer blurs.

## If it still stutters

Turn blur off entirely (keeps the dock translucent, just unblurred):

```bash
# in theme/dream-os-{dark,light}.ron set:
#   is_frosted: false,
#   frosted_panel: false,
# then:
cd ~/Projects/dream-os && just theme
```

Or via Settings -> Desktop -> Appearance -> Frosted glass (uncheck all).

## Other notes

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
