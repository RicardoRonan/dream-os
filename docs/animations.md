# Panel animations

COSMIC 1.11 has no setting for launcher or App Library open animation. Dream OS
builds local patched binaries from pinned upstream commits. The system binaries
in `/usr/bin` stay untouched.

| Surface | Trigger | Motion | Binary |
| --- | --- | --- | --- |
| Launcher | `Super`, `/`, `Super+Space` | 200ms fade + 8px upward slide | `~/.local/bin/cosmic-launcher` |
| Alt+Tab switcher | `Alt+Tab`, `Shift+Alt+Tab` | 140ms fade + settle | same launcher binary |
| App Library | `Super+A` | 200ms fade + 8px upward slide | `~/.local/bin/cosmic-app-library` |

Both animations use an ease-out cubic curve. Frame ticks run only while the
transition is active, so an idle desktop pays no extra cost.

## Install

```bash
just panel-open-animation       # both surfaces
just launcher-alt-tab           # launcher only
just app-library-open-animation # App Library only
```

Each script checks the installed package version against its pinned commit.

## Check and remove

```bash
bash scripts/launcher-alt-tab-animation.sh status
bash scripts/app-library-open-animation.sh status
just panel-open-animation-off
```

Rollback removes only the local binaries and marker files. Next launch uses the
stock binaries again.

## Pinned commits

- `cosmic-launcher`: `29c1bac`
- `cosmic-app-library`: `90c399d`

When Pop!_OS updates either package, rebase the matching patch and update the
commit in its script.
