#!/usr/bin/env bash
# Dream OS - Phase 1: COSMIC theme seeds (Dark "Obsidian" + Light "Titan").
# Pure-grayscale base, single accent (user-swappable), accent focus ring, Standard density.
# User-space only. Backs up the Builder dirs before writing.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CFG="$HOME/.config/cosmic"

seed_dir()  { echo "$CFG/com.system76.CosmicTheme.$1.Builder/v1"; }

for mode in Dark Light; do
  dir="$(seed_dir "$mode")"
  if [ -d "$dir" ]; then
    bk="$CFG/com.system76.CosmicTheme.$mode.Builder.bak.$(date +%Y%m%d-%H%M%S)"
    cp -a "$CFG/com.system76.CosmicTheme.$mode.Builder" "$bk"
    echo "Backed up $mode builder -> $bk"
  fi
  mkdir -p "$dir"
done

DARK="$(seed_dir Dark)"
LIGHT="$(seed_dir Light)"

write() { # write <dir> <name> <<< content
  local dir="$1" name="$2"
  cat > "$dir/$name"
}

# ---- shared builder fields -------------------------------------------------
for pair in "Dark:$DARK" "Light:$LIGHT"; do
  mode="${pair%%:*}"; dir="${pair#*:}"
  write "$dir" corner_radii <<'EOF'
(
    radius_0: (0.0, 0.0, 0.0, 0.0),
    radius_xs: (4.0, 4.0, 4.0, 4.0),
    radius_s: (8.0, 8.0, 8.0, 8.0),
    radius_m: (16.0, 16.0, 16.0, 16.0),
    radius_l: (32.0, 32.0, 32.0, 32.0),
    radius_xl: (160.0, 160.0, 160.0, 160.0),
)
EOF
  write "$dir" spacing <<'EOF'
(
    space_none: 0,
    space_xxxs: 4,
    space_xxs: 8,
    space_xs: 12,
    space_s: 16,
    space_m: 24,
    space_l: 32,
    space_xl: 48,
    space_xxl: 64,
    space_xxxl: 128,
)
EOF
  write "$dir" gaps <<'EOF'
(0, 8)
EOF
  write "$dir" is_frosted <<'EOF'
false
EOF
  # pure grayscale: no neutral tint
  write "$dir" neutral_tint <<'EOF'
None
EOF
  # focus ring follows the accent (None = use accent)
  write "$dir" window_hint <<'EOF'
None
EOF
  write "$dir" active_hint <<'EOF'
2
EOF

  # palette = single source of truth, extracted from the repo .ron export
  lc="$(echo "$mode" | tr '[:upper:]' '[:lower:]')"
  sed -n '/^    palette: /,/^    )),$/p' "$REPO/theme/dream-os-$lc.ron" \
    | sed '1s/^    palette: //' \
    | sed '$s/,$//' \
    | sed 's/^    //' > "$dir/palette"
done

# ---- dark (Obsidian) -------------------------------------------------------
write "$DARK" accent <<'EOF'
Some((
    red: 0.29803923,
    green: 0.5529412,
    blue: 1.0,
))
EOF
write "$DARK" bg_color <<'EOF'
Some((
    red: 0.0,
    green: 0.0,
    blue: 0.0,
    alpha: 1.0,
))
EOF
write "$DARK" primary_container_bg <<'EOF'
Some((
    red: 0.050980393,
    green: 0.050980393,
    blue: 0.050980393,
    alpha: 1.0,
))
EOF
write "$DARK" secondary_container_bg <<'EOF'
Some((
    red: 0.09019608,
    green: 0.09019608,
    blue: 0.09019608,
    alpha: 1.0,
))
EOF
write "$DARK" text_tint <<'EOF'
Some((
    red: 0.9490196,
    green: 0.9490196,
    blue: 0.9490196,
))
EOF
write "$DARK" success <<'EOF'
Some((
    red: 0.29803923,
    green: 0.6039216,
    blue: 0.36862746,
))
EOF
write "$DARK" warning <<'EOF'
Some((
    red: 0.78039217,
    green: 0.6039216,
    blue: 0.22745098,
))
EOF
write "$DARK" destructive <<'EOF'
Some((
    red: 0.78039217,
    green: 0.36078432,
    blue: 0.36078432,
))
EOF

# ---- light (Titan) ---------------------------------------------------------
write "$LIGHT" accent <<'EOF'
Some((
    red: 0.18431373,
    green: 0.43529412,
    blue: 0.8784314,
))
EOF
write "$LIGHT" bg_color <<'EOF'
Some((
    red: 1.0,
    green: 1.0,
    blue: 1.0,
    alpha: 1.0,
))
EOF
write "$LIGHT" primary_container_bg <<'EOF'
Some((
    red: 0.96862745,
    green: 0.96862745,
    blue: 0.96862745,
    alpha: 1.0,
))
EOF
write "$LIGHT" secondary_container_bg <<'EOF'
Some((
    red: 0.9372549,
    green: 0.9372549,
    blue: 0.9372549,
    alpha: 1.0,
))
EOF
write "$LIGHT" text_tint <<'EOF'
Some((
    red: 0.039215688,
    green: 0.039215688,
    blue: 0.039215688,
))
EOF
write "$LIGHT" success <<'EOF'
Some((
    red: 0.18039216,
    green: 0.49019608,
    blue: 0.30980393,
))
EOF
write "$LIGHT" warning <<'EOF'
Some((
    red: 0.6509804,
    green: 0.4862745,
    blue: 0.101960786,
))
EOF
write "$LIGHT" destructive <<'EOF'
Some((
    red: 0.70980394,
    green: 0.2509804,
    blue: 0.2509804,
))
EOF

# ---- density (Standard) ----------------------------------------------------
TK="$CFG/com.system76.CosmicTk/v1"
if [ -d "$TK" ]; then
  [ -f "$TK/interface_density" ] && echo "Standard" > "$TK/interface_density"
  [ -f "$TK/header_size" ]       && echo "Standard" > "$TK/header_size"
  echo "Density set to Standard."
fi

# ---- apply (materialise the resolved v2 theme) -----------------------------
# The Settings CLI imports a .ron ThemeBuilder and writes the derived theme.
if command -v cosmic-settings >/dev/null 2>&1; then
  for lc in dark light; do
    if cosmic-settings appearance import "$REPO/theme/dream-os-$lc.ron" >/dev/null 2>&1; then
      echo "Imported $lc theme."
    else
      echo "WARN: import of $lc theme failed (apply manually via Settings > Appearance)." >&2
    fi
  done
  echo "true" > "$CFG/com.system76.CosmicTheme.Mode/v1/is_dark"
  pkill -x cosmic-panel 2>/dev/null || true
  echo "Dream OS theme applied (Dark default). If UI looks stale, restart the session."
else
  echo "cosmic-settings not found; seeds written only. Import theme/*.ron manually."
fi
