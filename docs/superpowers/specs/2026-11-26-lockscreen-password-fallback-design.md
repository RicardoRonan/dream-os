# Lock screen password fallback

Status: approved for planning. Date: 2026-11-26.

## Problem

COSMIC uses one PAM conversation on the lock screen. With `pam_fprintd.so`
before `pam_unix.so`, the fingerprint module emits `PAM_TEXT_INFO`, which
replaces the password input until the fingerprint attempt succeeds, fails, or
times out. There is no supported toggle to switch to password immediately.
This is upstream `pop-os/cosmic-greeter#173`.

## Goals

- Add a `Use password instead` button to the lock screen fingerprint prompt.
- Click it to cancel the fingerprint attempt and immediately get a clean
  password field.
- Keep fingerprint unlock working on later lock cycles.
- Keep GNOME keyring unlock working on the password path.
- Keep the change durable in the Dream OS greeter patch and installer.

## Non-goals

- No change to the boot login greeter or its PAM service.
- No concurrent password and fingerprint PAM workers.
- No change to fingerprint enrollment in COSMIC Settings.
- No upstream merge.

## Architecture

All greeter source changes are new hunks in
`patches/cosmic-greeter-center-login.patch`. The login-screen hunks stay
unchanged. New hunks affect only `src/locker.rs`.

`Conversation::message()` sends a new locker-only `Message::AuthInfo(String)`
instead of `common::Message::Prompt(text, false, None)`. This distinguishes a
fingerprint/status message from a real password prompt without matching
localized text.

`App` gains:

- `auth_info_opt: Option<String>` for the current fingerprint/status message.
- `password_only: bool`, set by the fallback button.
- `auth_generation: u64`, incremented whenever the PAM task restarts.

A scoped wrapper, `Message::Scoped(u64, Box<Message>)`, carries the generation
on every PAM task message, including `Channel`, `Error`, `Unlock`, `AuthInfo`,
and prompt messages. `update` unwraps only messages whose generation matches
the current one. A blocked `pam_fprintd` thread from an aborted task therefore
cannot alter the UI or unlock the session.

`pam_thread()` takes a PAM service name. Normal locks use `cosmic-greeter`.
After the fallback button, the restarted task uses
`cosmic-greeter-password`.

The existing lock task stream is extracted into a helper so it can be started
again without recreating lock surfaces. The helper creates a fresh value
channel, sends `Message::Channel`, and spawns `pam_thread` with the service
selected by `password_only`.

## UI behavior

- The info text and button render only while `auth_info_opt` is set.
- Button label: `Use password instead`.
- The button sits directly below the info text. Normal prompts keep the
  existing `secure_input` widget.
- Clicking the button clears `auth_info_opt`, `error_opt`, `prompt_opt`, and
  `value_tx_opt`, sets `authenticating` to false, increments the generation,
  aborts the current task, and starts the password-only task.
- The new prompt is a normal secret `secure_input` from `pam_unix.so`.
- Keyboard focus and activation use the standard button widget. No global
  shortcut is added.
- With multiple monitors, each lock surface may show the button. The
  `password_only` guard prevents more than one restart.
- English text goes in `i18n/en/cosmic_greeter.ftl`. Missing translations fall
  back to English.

## Password-only PAM service

Dream OS installs `/etc/pam.d/cosmic-greeter-password`.

It is copied from `/etc/pam.d/cosmic-greeter` at install time. Only the auth
section changes: replace `@include common-auth` with an explicit
`pam_unix.so nullok try_first_pass`, followed by `pam_deny.so` and
`pam_permit.so`. Keep `pam_gnome_keyring.so` in the auth stack and keep all
account, session, and password directives verbatim.

The file starts with a `# Managed by Dream OS` marker. Installation refuses to
overwrite an existing file without that marker.

`/etc/pam.d/cosmic-greeter` is never edited.

## Packaging

- Rebase the greeter patch from pinned commit `98df07d` to `20af063`, the
  source commit behind installed `cosmic-greeter 1.11.0`.
- Update `COMMIT` in `scripts/greeter-center.sh` and the pinned commit note in
  `docs/greeter.md`.
- Extend `scripts/greeter-center.sh install` to install the PAM service after
  the patched binary. Extend `rollback` to remove only the Dream OS PAM file.
- `just fix-login` remains the single entrypoint.
- `scripts/doctor.sh` checks for the PAM file marker and a patched-binary
  marker string.

## Verification

1. `bash -n` on changed shell scripts.
2. Clean build in the cached clone:
   `git apply` the patch at `20af063`, then `cargo build --release --locked`.
3. `bash scripts/doctor.sh` after install.
4. Manual lock test on this machine:
   - lock, see fingerprint prompt, confirm password field is absent;
   - click `Use password instead`, confirm a password field appears at once;
   - type password, confirm unlock and keyring unlock;
   - lock again, confirm fingerprint still works.
5. Journal check for the generation and PAM service names, with no stale
   unlock after aborted fingerprint attempts.

## Rollback

`scripts/greeter-center.sh rollback` restores
`/usr/bin/cosmic-greeter.dream-os.bak` and removes
`/etc/pam.d/cosmic-greeter-password` only when the Dream OS marker is present.

## Acceptance criteria

- Fingerprint prompt shows the button.
- Button produces a password field without waiting for the fingerprint
  timeout.
- Password unlock also unlocks the login keyring.
- Next lock still offers fingerprint.
- Boot login is unchanged.
- Doctor passes with no new missing checks.
