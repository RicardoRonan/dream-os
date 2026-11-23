# DS4 Battery Tray

Vendored from <https://github.com/kvaynwahey/DS4BatteryTray> under the MIT
licence. The local copy adds:

- a separate `Power:` menu row for charging, discharging and full states
- a charging/full suffix on the panel label
- systemd user-service autostart via `scripts/ds4-battery-tray.sh`
- a local GSettings schema, because the upstream script expects one but does
  not ship it
