#!/usr/bin/env bash
# Dream OS - build / install / rollback the centered-login greeter patch.
#   scripts/greeter-center.sh build     # compile (user-space, long)
#   scripts/greeter-center.sh install   # back up + install (needs sudo)
#   scripts/greeter-center.sh rollback  # restore the original binary (needs sudo)
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD="$HOME/.cache/dream-os/build/cosmic-greeter"
COMMIT="98df07d"           # must match the packaged cosmic-greeter version
PATCH="$REPO/patches/cosmic-greeter-center-login.patch"
BAK="/usr/bin/cosmic-greeter.dream-os.bak"

cmd="${1:-}"

case "$cmd" in
  build)
    export PATH="$HOME/.cargo/bin:$PATH"
    command -v cargo >/dev/null 2>&1 || { echo "Install rustup first (see docs/greeter.md)"; exit 1; }
    mkdir -p "$(dirname "$BUILD")"
    [ -d "$BUILD" ] || git clone https://github.com/pop-os/cosmic-greeter "$BUILD"
    cd "$BUILD"
    git fetch --quiet origin && git checkout --quiet "$COMMIT"
    git apply "$PATCH" 2>/dev/null || echo "(patch already applied?)"
    cargo build --release --locked
    echo "Built: $BUILD/target/release/cosmic-greeter"
    ;;
  install)
    BIN="$BUILD/target/release/cosmic-greeter"
    [ -x "$BIN" ] || { echo "No build at $BIN - run: $0 build"; exit 1; }
    echo "Backing up /usr/bin/cosmic-greeter -> $BAK"
    sudo cp /usr/bin/cosmic-greeter "$BAK"
    sudo install -m 755 "$BIN" /usr/bin/cosmic-greeter
    echo "Installed. Log out to test. If it fails, run: $0 rollback"
    echo "(From a TTY: Ctrl+Alt+F3, log in, then: sudo cp $BAK /usr/bin/cosmic-greeter)"
    ;;
  rollback)
    [ -f "$BAK" ] || { echo "No backup at $BAK"; exit 1; }
    sudo cp "$BAK" /usr/bin/cosmic-greeter
    echo "Restored original greeter."
    ;;
  *)
    echo "usage: $0 {build|install|rollback}"; exit 1 ;;
esac
