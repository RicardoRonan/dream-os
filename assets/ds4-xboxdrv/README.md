# DS4 -> virtual Xbox 360 pad

A background script that keeps a virtual Microsoft Xbox 360 pad available
whenever the DualShock 4 is connected, so every game, native or Proton,
sees a standard controller. Install with `xboxdrv` and run
`scripts/ds4-xboxdrv.sh install`; it runs as the `ds4-xboxdrv` systemd
user service.

Controller to virtual pad mapping (DS4 wirelessly):

| DS4 button | Xbox pad |
|-----------|----------|
| Cross     | A        |
| Circle    | B        |
| Square    | X        |
| Triangle  | Y        |
| L1        | LB       |
| R1        | RB       |
| L2        | LT       |
| R2        | RT       |
| Touchpad  | Start    |
| PS        | Guide    |
| Share     | Back     |
| Options   | Start    |

If the DS4 disconnects, the virtual pad stays so games do not lose it.

Reinstall requirement: `sudo apt install -y xboxdrv` before running install.
