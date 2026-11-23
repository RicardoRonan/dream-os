#!/usr/bin/env bash
# Dream OS - setup wizard: migrate to the Dream OS theme.
#
# Walks the user-space install phases that make the desktop look like Dream OS:
# COSMIC theme seeds, identity, panel/dock layout, cross-app sync, and the
# macOS structure (WhiteSur icons + appearance profile). Ends with doctor.
#
# Usage:
#   scripts/theme-wizard.sh [--yes] [--step N]
#   scripts/theme-wizard.sh --list
#
# --yes    skip all confirmation prompts
# --step N run only step N
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
YES=0
STEP=""

say()  { printf '%s\n' "$*"; }
note() { printf '   %s\n' "$*"; }

# ---------------------------------------------------------------------------
# Step definitions: name|description|command
# ---------------------------------------------------------------------------
step_count=8
step_name()    { local n="$1"; case "$n" in
    1) echo "theme" ;; 2) echo "identity" ;; 3) echo "desktop" ;; 4) echo "crossapp" ;;
    5) echo "system-pkgs" ;; 6) echo "macos" ;; 7) echo "gtk-radii" ;; 8) echo "verify" ;;
  esac; }
step_desc()    { local n="$1"; case "$n" in
    1) echo "COSMIC theme seeds + Dark Obsidian / Light Titan import" ;;
    2) echo "wallpaper, Vimix cursors, icons, bundled fonts" ;;
    3) echo "panel + dock geometry (macOS structure)" ;;
    4) echo "GTK/Qt/font sync, SBC-XQ, radius watch" ;;
    5) echo "system packages (Papirus, WhiteSur, WhiteSur-cursors) [needs sudo]" ;;
    6) echo "WhiteSur icons + stock COSMIC grid for app/settings icons (macOS structure)" ;;
    7) echo "GTK corner radii after theme change" ;;
    8) echo "final doctor verification" ;;
  esac; }
step_cmd()     { local n="$1"; case "$n" in
    1) echo "bash \"$ROOT/install/01-theme.sh\"" ;;
    2) echo "bash \"$ROOT/install/02-identity.sh\"" ;;
    3) echo "bash \"$ROOT/install/03-desktop.sh\"" ;;
    4) echo "bash \"$ROOT/install/05-crossapp.sh\"" ;;
    5) echo "sudo bash \"$ROOT/install/00-system-apt.sh\"" ;;
    6) echo "bash \"$ROOT/scripts/install-whitesur.sh\" --icons-only && bash \"$ROOT/scripts/appearance.sh\" apply" ;;
    7) echo "bash \"$ROOT/scripts/gtk-radius.sh\" apply" ;;
    8) echo "bash \"$ROOT/scripts/doctor.sh\"" ;;
  esac; }

list_steps() {
  say "Dream OS theme migration wizard — steps:"
  local n
  for n in 1 2 3 4 5 6 7; do
    say "  $n. $(step_name "$n") — $(step_desc "$n")"
  done
  say "  8. verify — final doctor verification"
}

run_step() {
  local n="$1"
  local name cmd
  name="$(step_name "$n")"
  cmd="$(step_cmd "$n")"
  say ""
  say "── $n. $name — $(step_desc "$n")"
  if [ "$n" = "5" ] && ! sudo -n true 2>/dev/null; then
    note "Skipped: system packages need sudo with a password (run: sudo bash install/00-system-apt.sh)."
    return 0
  fi
  if [ "$n" != "8" ]; then
    if ! confirm "   Run $name?"; then
      note "Skipped."
      return 0
    fi
  fi
  note "running: $cmd"
  if eval "$cmd"; then
    note "OK: $name"
  elif [ "$name" = "verify" ]; then
    # doctor marks advisory items (e.g. a missing optional font) as MISS;
    # the wizard is not a pass/fail gate on those.
    note "verify reported issues above (advisory)."
  else
    printf '   FAILED: %s (exit %s)\n' "$name" "$?" >&2
    WIZARD_FAIL=1
  fi
}

confirm() {
  [ "$YES" = 1 ] && return 0
  read -rp "   Continue? [Y/n] " ans || true
  case "${ans:-Y}" in
    [nN]) return 1 ;;
    *) return 0 ;;
  esac
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
while [ $# -gt 0 ]; do
  case "$1" in
    --yes|-y) YES=1; shift ;;
    --step) STEP="${2:?--step requires a number}"; shift 2 ;;
    --list) list_steps; exit 0 ;;
    *) printf 'error: unknown option: %s\n' "$1" >&2; list_steps >&2; exit 2 ;;
  esac
done

if ! command -v cosmic-settings >/dev/null 2>&1; then
  note "warning: cosmic-settings is not installed; theme import will not apply."
fi

say "Dream OS theme migration wizard"
note "Migrating to the Dream OS theme (COSMIC seeds, WhiteSur icons, macOS structure)."
note "Existing user-space changes are backed up by the steps themselves."
say ""
note "Current live appearance:"
bash "$ROOT/scripts/appearance.sh" doctor 2>/dev/null || true
say ""

if [ -n "$STEP" ]; then
  [ "$STEP" -ge 1 ] && [ "$STEP" -le "$step_count" ] || { printf 'error: step must be 1-%s\n' "$step_count" >&2; exit 2; }
  run_step "$STEP"
  exit 0
fi

WIZARD_FAIL=0
for n in 1 2 3 4 5 6 7 8; do
  run_step "$n"
done

say ""
[ "$WIZARD_FAIL" = 0 ] && note "Migration wizard finished cleanly." || note "Migration wizard finished with failures (see above)."
exit "$WIZARD_FAIL"
