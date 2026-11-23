#!/bin/bash
# Keep a virtual Microsoft Xbox 360 pad available whenever the DS4 is connected.
# This makes every game, native or Proton, see a standard controller.
#
# The previous version ran xboxdrv in the foreground and never noticed when the
# DS4 reconnected with a different event node. xboxdrv then stayed on the dead
# node forever, holding a silent virtual pad that games picked as player 1.
# This version watches the node and restarts xboxdrv when it disappears.

set -u

# only one instance
exec 9>/tmp/ds4-xboxdrv.lock
flock -n 9 || exit 0

find_ds4_event() {
    for namefile in /sys/class/input/event*/device/name; do
        [ -r "$namefile" ] || continue
        if [ "$(cat "$namefile" 2>/dev/null)" = "Wireless Controller" ]; then
            basename "$(dirname "$(dirname "$namefile")")"
            return 0
        fi
    done
    return 1
}

while true; do
    event="$(find_ds4_event || true)"
    if [ -z "${event:-}" ] || [ ! -e "/dev/input/$event" ]; then
        sleep 3
        continue
    fi

    xboxdrv \
        --evdev "/dev/input/$event" \
        --evdev-absmap ABS_X=x1,ABS_Y=y1,ABS_RX=x2,ABS_RY=y2,ABS_Z=lt,ABS_RZ=rt \
        --evdev-keymap BTN_SOUTH=a,BTN_EAST=b,BTN_NORTH=y,BTN_WEST=x,BTN_TL=lb,BTN_TR=rb,BTN_SELECT=back,BTN_START=start,BTN_THUMBL=tl,BTN_THUMBR=tr,BTN_MODE=guide \
        --mimic-xpad --silent &
    pid=$!

    while kill -0 "$pid" 2>/dev/null; do
        if [ ! -e "/dev/input/$event" ]; then
            kill "$pid" 2>/dev/null
            break
        fi
        sleep 1
    done
    wait "$pid" 2>/dev/null
    sleep 2
done
