#!/usr/bin/env python3
"""Dream OS - map mouse back/forward buttons to Alt+Left / Alt+Right.

Reads the Lenovo Gaming Mouse evdev device and injects the standard browser
back/forward key chords with ydotool. Runs as a systemd user service, so it
needs read access to /dev/input (the input group).
"""
import glob
import os
import shutil
import struct
import subprocess
import sys
import time

MOUSE_NAME = os.environ.get("DREAM_OS_MOUSE_NAME", "Lenovo Gaming Mouse")
EVENT = struct.Struct("llHHi")

BTN_SIDE = 275
BTN_EXTRA = 276
BTN_FORWARD = 277
BTN_BACK = 278

ACTIONS = {
    BTN_SIDE: "alt+Left",
    BTN_BACK: "alt+Left",
    BTN_EXTRA: "alt+Right",
    BTN_FORWARD: "alt+Right",
}

YDOTOOL = shutil.which("ydotool") or "/usr/bin/ydotool"


def log(message):
    print(f"mouse-buttons: {message}", flush=True)


def find_device():
    for event in sorted(glob.glob("/dev/input/event*")):
        name_file = f"/sys/class/input/{os.path.basename(event)}/device/name"
        try:
            with open(name_file, encoding="utf-8") as fh:
                name = fh.read().strip()
        except OSError:
            continue
        if MOUSE_NAME.lower() in name.lower():
            return event, name
    return None, None


def run():
    if not os.path.exists(YDOTOOL):
        log("ydotool is missing; install ydotool")
        sys.exit(1)

    log(f"looking for a device matching {MOUSE_NAME!r}")
    while True:
        device, name = find_device()
        if not device:
            time.sleep(3)
            continue

        try:
            fd = os.open(device, os.O_RDONLY)
        except PermissionError:
            log(f"permission denied on {device}; add your user to the input group")
            time.sleep(10)
            continue
        except OSError as exc:
            log(f"cannot open {device}: {exc}")
            time.sleep(3)
            continue

        log(f"listening on {device} ({name})")
        try:
            while True:
                data = os.read(fd, EVENT.size)
                if len(data) < EVENT.size:
                    break
                _sec, _usec, etype, code, value = EVENT.unpack(data)
                if etype != 1 or value != 1:
                    continue
                chord = ACTIONS.get(code)
                if not chord:
                    continue
                log(f"button {code} -> {chord}")
                subprocess.run(
                    [YDOTOOL, "key", chord],
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                    check=False,
                )
        except OSError as exc:
            log(f"read error on {device}: {exc}")
        finally:
            os.close(fd)
        time.sleep(2)


if __name__ == "__main__":
    try:
        run()
    except KeyboardInterrupt:
        pass
