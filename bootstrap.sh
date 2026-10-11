#!/usr/bin/env bash
# Dream OS bootstrap - reproduces the theme + desktop setup.
set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cat <<EOF
Dream OS bootstrap
==================
Repo: $REPO

Step 1 (once, needs sudo):
  sudo bash $REPO/install/00-system-apt.sh

Step 2 (user-space, no sudo): this script
EOF

read -r -p "Run user-space phases now? [y/N] " ans
[[ "$ans" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }

for s in "$REPO"/install/0[1-9]-*.sh; do
  bash "$s"
done

echo
echo "Bootstrap complete. Run 'just doctor' to verify."
