# Features

Dream OS pairs the theme with a small, curated set of OS-like features. Nothing
here touches the bootloader or drivers.

## Clipboard history (Windows-style)

Already wired: `Super+V` runs `~/.local/bin/clip-pick` (cliphist + wofi), which
shows history and pastes the selection.

For a closer Windows feel (popup near the cursor, click-to-paste), use the COSMIC
clipboard applet (`io.github.cosmic_utils.cosmic-ext-applet-clipboard-manager`):

- Add it in Settings -> Desktop -> Panel -> Applets.
- Bind `Super+V` to `cosmic-ext-applet-clipboard-manager --toggle`.
- Direct click-to-paste additionally needs `ydotool` + `ydotoold`
  (`systemctl --user enable --now ydotool`).
- COSMIC 1.9 cannot yet pop the panel menu open at the cursor without a click,
  so the shortcut uses a top-anchored overlay. A known upstream limitation.

## 3-finger gestures

COSMIC handles 4-finger workspace gestures natively. `install/04-features.sh`
adds 3-finger up/down -> workspace overview via `libinput-gestures`
(`~/.config/libinput-gestures.conf`). Reload with:

```bash
libinput-gestures-setup restart
```

`libinput-gestures` needs read access to `/dev/input`. Add yourself to the
`input` group once, then log out and back in:

```bash
sudo usermod -aG input "$USER"
```

Without that, the autostart unit fails with `Permission denied` and the
three-finger gestures do nothing. `install/04-features.sh` now prints this
instead of claiming the service started.

## Mouse back/forward buttons

`scripts/mouse-buttons.sh` installs `dream-os-mouse-buttons.service`. It reads
the Lenovo Gaming Mouse evdev device and maps:

- `BTN_SIDE` / `BTN_BACK` -> `Alt+Left` (back)
- `BTN_EXTRA` / `BTN_FORWARD` -> `Alt+Right` (forward)

Reading `/dev/input` needs the `input` group, the same requirement as the
three-finger gestures:

```bash
sudo usermod -aG input "$USER"
```

Log out and back in. The service starts automatically. Check it with:

```bash
journalctl --user -u dream-os-mouse-buttons -f
```

The mapping happens before the app sees the input, so every app receives the
same chords. Apps that use Alt+Left/Right (Firefox, Thunar, most browsers and
file managers) navigate. Apps that do not use those shortcuts ignore them.
If your mouse reports a different name, set `DREAM_OS_MOUSE_NAME` in the unit's
`Environment=` line, or edit the default in `scripts/mouse-buttons.py`.

## Bluetooth SBC-XQ

`scripts/bt-sbc-xq.sh` installs `dream-os-bt-sbc-xq.service`. It watches BlueZ
cards and switches the active profile to `a2dp-sink-sbc_xq` when the card
offers it. It runs at login and again when a device reconnects.

```bash
systemctl --user status dream-os-bt-sbc-xq
journalctl --user -u dream-os-bt-sbc-xq -f
```

Manual profile changes are left alone until the device reconnects. To stop the
preference:

```bash
systemctl --user disable --now dream-os-bt-sbc-xq.service
```

SBC-XQ uses more bandwidth than standard SBC. If a device crackles or drops out
on a weak link, switch that device back to SBC in Settings, or stop the service.

## Status tray (Status Hub)

The panel uses **Status Hub** instead of the stock status area. It collects app
tray icons behind one button on every display, which avoids the COSMIC 1.11 bug
that leaves duplicate grey gear placeholders when tray clients reconnect.

- Installed by `install/04-features.sh` from the COSMIC flatpak remote.
- `scripts/appearance.sh` uses it for both monitors when the flatpak export
  exists, and falls back to `com.system76.CosmicAppletStatusArea` otherwise.
- To use the stock tray again, replace the applet in
  Settings -> Desktop -> Panel -> Applets, or remove the Status Hub flatpak and
  run `just macos`.

## Hot corners (macOS-like)

`install/06-hotcorners.sh` installs waycorner with top-left overview,
bottom-right launcher and bottom-left lock. Other options:

- **cosmic-hotcorners** (native libcosmic daemon) -
  <https://github.com/boloto1979/cosmic-hotcorners>. Build with a Rust toolchain:

  ```bash
  rustup default stable            # if not installed
  git clone https://github.com/boloto1979/cosmic-hotcorners
  cd cosmic-hotcorners && ./build.sh
  ```

  Then assign corner actions (top-left -> workspaces, etc.) in its settings GUI.

- **waycorner** (single binary) - a lighter alternative; trigger
  `cosmic-workspaces` / `cosmic-launcher` on corner entry.

## Utility applets

Installed from the COSMIC flatpak remote by `install/04-features.sh`:

| Applet | App ID |
|--------|--------|
| Status Hub | `io.github.marcelogomes90.cosmic-ext-applet-status-hub` |
| Caffeine | `com.github.codevardhan.caffeine-applet` |
| System Monitor | `io.github.cosmic_utils.sysinfo-applet` |
| Privacy Indicator | `dev.DBrox.CosmicPrivacyIndicator` |
| Pomodoro | `com.github.bgub.CosmicExtAppletPomodoro` |

Status Hub is the default tray on both displays. Add Caffeine, privacy, sysinfo
or Pomodoro in Settings -> Desktop -> Panel -> Applets when you want them.

## Night light + auto light/dark

- **Night light:** Settings -> Displays -> Night Light (schedule sunset/sunrise).
- **Auto theme:** Settings -> Desktop -> Appearance -> toggle automatic
  light/dark switching (follows sunrise/sunset).

## Phone (KDE Connect)

Install the Connected applet and KDE Connect, then pair your phone for SMS,
notifications, file sharing, clipboard sync, and find-my-phone. Requires
`kdeconnect` (system) from `install/00-system-apt.sh`.
