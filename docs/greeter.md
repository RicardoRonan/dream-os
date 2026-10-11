# Centered login (greeter patch)

COSMIC's greeter (`cosmic-greeter`) draws a **fixed** layout: a centered
866px-wide panel containing a **row** of *clock + status + buttons* (left) and
the *login block* (right). The login therefore sits ~200px right of screen
center, and there is **no setting** to change it (the greeter config only stores
`users` and `last_user`).

Dream OS patches it to a **centered column**: clock/buttons on top, login below,
both centered, in a compact 420px panel. See
`patches/cosmic-greeter-center-login.patch`.

## Build

```bash
# toolchain (user-space)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
export PATH="$HOME/.cargo/bin:$PATH"

mkdir -p ~/.cache/dream-os/build && cd ~/.cache/dream-os/build
git clone https://github.com/pop-os/cosmic-greeter.git
cd cosmic-greeter
git checkout 98df07d            # must match the packaged version (1.10.0)

# apply the patch
git apply /path/to/dream-os/patches/cosmic-greeter-center-login.patch

# build (long; pulls git deps)
cargo build --release --locked
# -> target/release/cosmic-greeter
```

Build deps that may be needed (root): `pkg-config libxkbcommon-dev libwayland-dev
libpam0g-dev libssl-dev libdbus-1-dev libudev-dev cmake`.

## Install (with rollback)

```bash
sudo cp /usr/bin/cosmic-greeter /usr/bin/cosmic-greeter.dream-os.bak
sudo install -m 755 target/release/cosmic-greeter /usr/bin/cosmic-greeter
```

Then **log out to test**. If the greeter fails, switch to a TTY (Ctrl+Alt+F3),
log in, and restore:

```bash
sudo cp /usr/bin/cosmic-greeter.dream-os.bak /usr/bin/cosmic-greeter
```

## Caveats

- Overwritten by COSMIC updates. Re-apply after upgrading (re-pin the new commit).
- The greeter also cannot be translucent yet (upstream TODO) — frosted glass may
  not show on the *greeter*, only on the lock screen / launcher / overview.
- Tracked per COSMIC version; the patch targets the `greeter.rs` view layout.
