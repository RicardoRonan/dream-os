#!/usr/bin/env bash
# Dream OS - remove user-space files. Backups are left in place.
# System packages (Papirus, niri, DMS, ...) are NOT removed - do that with your package manager.
set -uo pipefail

say() { printf '%s\n' "$*"; }

rm -rfv "$HOME/.config/dream-os" 2>/dev/null || true
rm -fv "$HOME/.local/bin/session-save.sh" "$HOME/.local/bin/session-restore.sh" 2>/dev/null || true
rm -fv "$HOME/.local/bin/waycorner" 2>/dev/null || true
rm -rfv "$HOME/.config/waycorner" 2>/dev/null || true
rm -rfv "$HOME/.local/share/icons/DreamOS" 2>/dev/null || true
rm -fv "$HOME/.config/environment.d/dream-os.conf" 2>/dev/null || true
rm -fv "$HOME/.config/autostart/dream-os-session.desktop" 2>/dev/null || true
rm -fv "$HOME/.config/autostart/waycorner.desktop" 2>/dev/null || true
rm -fv "$HOME/.config/systemd/user/dream-os-session-save.service" \
       "$HOME/.config/systemd/user/dream-os-session-save.timer" 2>/dev/null || true

if command -v systemctl >/dev/null 2>&1; then
  systemctl --user disable --now dream-os-session-save.timer 2>/dev/null || true
  systemctl --user daemon-reload 2>/dev/null || true
fi

say ""
say "Removed Dream OS user files."
say "COSMIC theme config and any backups under ~/.config/cosmic are left untouched."
say "To revert the COSMIC theme: pick a backup beside ~/.config/cosmic/com.system76.CosmicTheme.* ,"
say "or restore the snapshot in ~/.dotfiles-backup-<ts>/ if present."
say "To revert the greeter:  sudo cp /usr/bin/cosmic-greeter.dream-os.bak /usr/bin/cosmic-greeter"
say "To remove the rice: stop greetd/dms and uninstall niri, dms, noctalia(if any), matugen."
