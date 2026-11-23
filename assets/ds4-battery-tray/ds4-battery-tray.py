#!/usr/bin/env python3
"""
ds4_battery_tray.py – extended with window, notifications, and settings.

Source: https://github.com/kvaynwahey/DS4BatteryTray (MIT)
Local changes: power state line, charging label, systemd autostart.
"""

import argparse
import os
import re
import signal
import sys
import threading
import subprocess
import time

import gi
gi.require_version("Gtk", "3.0")
gi.require_version("Gio", "2.0")
gi.require_version("GLib", "2.0")

# AppIndicator imports (try both namespaces)
try:
    gi.require_version("AppIndicator3", "0.1")
    from gi.repository import AppIndicator3 as AppIndicator
except (ValueError, ImportError):
    try:
        gi.require_version("AyatanaAppIndicator3", "0.1")
        from gi.repository import AyatanaAppIndicator3 as AppIndicator
    except (ValueError, ImportError):
        sys.stderr.write("Neither AppIndicator3 nor AyatanaAppIndicator3 found.\n")
        sys.exit(1)

from gi.repository import Gtk, GLib, Gio

# ----------------------------------------------------------------------
# Constants
# ----------------------------------------------------------------------
APP_ID = "io.github.kvaynwahey.Ds4BatteryTray"
DEFAULT_POLL_INTERVAL = 12
POWER_SUPPLY_ROOT = "/sys/class/power_supply"
LOW_BATTERY_THRESHOLD = 20  # percent
CONTROLLER_MAC = "AC:FD:93:26:54:FC"  # paired Wireless Controller

# Controller detection patterns
CONTROLLER_NODE_PATTERNS = [
    re.compile(r"^sony_controller_battery_", re.IGNORECASE),
    re.compile(r"^ps-controller-battery-", re.IGNORECASE),
    re.compile(r"^ps5_controller_battery_", re.IGNORECASE),
    re.compile(r"controller.?battery", re.IGNORECASE),
]
CONTROLLER_MODEL_HINTS = (
    "wireless controller",
    "dualshock",
    "dualsense",
    "sony interactive",
)

UPOWER_BUS_NAME = "org.freedesktop.UPower"
UPOWER_OBJ_PATH = "/org/freedesktop/UPower"
UPOWER_IFACE = "org.freedesktop.UPower"
UPOWER_DEV_IFACE = "org.freedesktop.UPower.Device"

UPOWER_STATE_MAP = {
    0: "unknown", 1: "charging", 2: "discharging",
    3: "empty", 4: "full", 5: "charging", 6: "discharging",
}

# ----------------------------------------------------------------------
# BatteryReading class (unchanged)
# ----------------------------------------------------------------------
class BatteryReading:
    __slots__ = ("present", "percentage", "state", "source")
    def __init__(self, present, percentage=None, state="unknown", source=None):
        self.present = present
        self.percentage = percentage
        self.state = state
        self.source = source
    def __repr__(self):
        return f"<BatteryReading present={self.present} pct={self.percentage} state={self.state} src={self.source}>"

# ----------------------------------------------------------------------
# Backend functions (unchanged)
# ----------------------------------------------------------------------
def _looks_like_controller(native_path: str, model: str) -> bool:
    base = os.path.basename(native_path or "")
    if any(p.search(base) for p in CONTROLLER_NODE_PATTERNS):
        return True
    model_l = (model or "").lower()
    return any(hint in model_l for hint in CONTROLLER_MODEL_HINTS)

def read_via_upower(verbose=False) -> BatteryReading:
    try:
        bus = Gio.bus_get_sync(Gio.BusType.SYSTEM, None)
        upower = Gio.DBusProxy.new_sync(
            bus, Gio.DBusProxyFlags.NONE, None,
            UPOWER_BUS_NAME, UPOWER_OBJ_PATH, UPOWER_IFACE, None,
        )
        result = upower.call_sync("EnumerateDevices", None, Gio.DBusCallFlags.NONE, -1, None)
        (device_paths,) = result.unpack()
        for path in device_paths:
            dev = Gio.DBusProxy.new_sync(
                bus, Gio.DBusProxyFlags.NONE, None,
                UPOWER_BUS_NAME, path, UPOWER_DEV_IFACE, None,
            )
            def prop(name):
                v = dev.get_cached_property(name)
                return v.unpack() if v is not None else None
            native_path = prop("NativePath") or ""
            model = prop("Model") or ""
            if not _looks_like_controller(native_path, model):
                continue
            percentage = prop("Percentage")
            state_num = prop("State") or 0
            is_present = prop("IsPresent")
            is_present = True if is_present is None else is_present
            return BatteryReading(
                present=bool(is_present) and percentage is not None,
                percentage=round(percentage) if percentage is not None else None,
                state=UPOWER_STATE_MAP.get(state_num, "unknown"),
                source="upower",
            )
    except Exception as e:
        if verbose:
            print(f"[upower] error: {e}", file=sys.stderr)
    return BatteryReading(present=False, source="upower")

def _read_sysfs_value(path):
    try:
        with open(path, "r") as f:
            return f.read().strip()
    except:
        return None

def _normalize_status(raw: str) -> str:
    raw = (raw or "").strip().lower()
    if raw == "charging": return "charging"
    if raw == "discharging": return "discharging"
    if raw in ("full", "not charging"): return "full"
    return "unknown"

def read_via_sysfs(verbose=False) -> BatteryReading:
    try:
        if not os.path.isdir(POWER_SUPPLY_ROOT):
            return BatteryReading(present=False, source="sysfs")
        for entry in os.listdir(POWER_SUPPLY_ROOT):
            node = os.path.join(POWER_SUPPLY_ROOT, entry)
            model = _read_sysfs_value(os.path.join(node, "model_name")) or ""
            if not _looks_like_controller(entry, model):
                continue
            capacity = _read_sysfs_value(os.path.join(node, "capacity"))
            if capacity is None:
                continue
            status = _read_sysfs_value(os.path.join(node, "status"))
            return BatteryReading(
                present=True,
                percentage=int(capacity),
                state=_normalize_status(status),
                source="sysfs",
            )
    except Exception as e:
        if verbose:
            print(f"[sysfs] error: {e}", file=sys.stderr)
    return BatteryReading(present=False, source="sysfs")

def poll_battery(verbose=False) -> BatteryReading:
    reading = read_via_upower(verbose=verbose)
    if reading.present:
        return reading
    return read_via_sysfs(verbose=verbose)

def controller_connected(mac=CONTROLLER_MAC) -> bool:
    """Return the BlueZ Connected state for the controller."""
    try:
        result = subprocess.run(
            ["bluetoothctl", "info", mac],
            capture_output=True,
            text=True,
            timeout=5,
        )
    except Exception:
        return False
    for line in result.stdout.splitlines():
        key, sep, value = line.strip().partition(":")
        if sep and key == "Connected":
            return value.strip().lower() == "yes"
    return False

# ----------------------------------------------------------------------
# Settings (persistent)
# ----------------------------------------------------------------------
SETTINGS_SCHEMA = "io.github.kvaynwahey.Ds4BatteryTray"
SETTINGS_PATH = "/io/github/kvaynwahey/Ds4BatteryTray/"

class Settings:
    """Simple wrapper for GSettings (or fallback to a file)."""
    def __init__(self):
        self._settings = None
        self._file = os.path.expanduser("~/.config/ds4-battery-tray.conf")
        self._data = {}
        try:
            # Try to use GSettings (requires a schema installed)
            self._settings = Gio.Settings.new(SETTINGS_SCHEMA)
        except:
            # Fallback: store in a simple file
            self._load_from_file()
    def _load_from_file(self):
        self._data = {"interval": DEFAULT_POLL_INTERVAL, "autostart": False}
        try:
            with open(self._file, "r") as f:
                for line in f:
                    k, v = line.strip().split("=", 1)
                    if k == "interval":
                        self._data["interval"] = int(v)
                    elif k == "autostart":
                        self._data["autostart"] = v.lower() == "true"
        except:
            pass
    def _save_to_file(self):
        os.makedirs(os.path.dirname(self._file), exist_ok=True)
        with open(self._file, "w") as f:
            f.write(f"interval={self._data['interval']}\n")
            f.write(f"autostart={str(self._data['autostart']).lower()}\n")
    def get_int(self, key, default=0):
        if self._settings:
            return self._settings.get_int(key)
        return self._data.get(key, default)
    def get_boolean(self, key, default=False):
        if self._settings:
            return self._settings.get_boolean(key)
        return self._data.get(key, default)
    def set_int(self, key, value):
        if self._settings:
            self._settings.set_int(key, value)
        else:
            self._data[key] = value
            self._save_to_file()
    def set_boolean(self, key, value):
        if self._settings:
            self._settings.set_boolean(key, value)
        else:
            self._data[key] = value
            self._save_to_file()

# ----------------------------------------------------------------------
# GUI Windows
# ----------------------------------------------------------------------
class BatteryWindow(Gtk.Window):
    """Simple window showing battery details."""
    def __init__(self, app):
        Gtk.Window.__init__(self, title="DS4 Battery")
        self.app = app
        self.set_default_size(300, 200)
        self.set_border_width(10)

        vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        self.add(vbox)

        # Percentage label
        self.pct_label = Gtk.Label(label="Battery: --%")
        self.pct_label.set_markup("<b>Battery: --%</b>")
        vbox.pack_start(self.pct_label, False, False, 0)

        # Progress bar
        self.progress = Gtk.ProgressBar()
        vbox.pack_start(self.progress, False, False, 0)

        # State label
        self.state_label = Gtk.Label(label="State: unknown")
        vbox.pack_start(self.state_label, False, False, 0)

        # Close button
        close_btn = Gtk.Button(label="Close")
        close_btn.connect("clicked", self.on_close)
        vbox.pack_start(close_btn, False, False, 0)

        self.show_all()

    def update(self, reading: BatteryReading):
        if reading.present and reading.percentage is not None:
            pct = max(0, min(100, reading.percentage))
            self.pct_label.set_markup(f"<b>Battery: {pct}%</b>")
            self.progress.set_fraction(pct / 100.0)
            state_txt = {
                "charging": "Charging", "full": "Fully charged",
                "discharging": "Discharging", "unknown": "Connected"
            }.get(reading.state, "Connected")
            self.state_label.set_text(f"State: {state_txt}")
        else:
            self.pct_label.set_markup("<b>Battery: Not found</b>")
            self.progress.set_fraction(0)
            self.state_label.set_text("State: no controller")

    def on_close(self, _):
        self.destroy()

class SettingsDialog(Gtk.Dialog):
    def __init__(self, parent, settings):
        Gtk.Dialog.__init__(self, title="Settings", transient_for=parent, flags=0)
        self.settings = settings
        self.set_default_size(300, 150)

        box = self.get_content_area()
        grid = Gtk.Grid()
        grid.set_row_spacing(10)
        grid.set_column_spacing(10)
        box.pack_start(grid, True, True, 0)

        # Poll interval
        lbl = Gtk.Label(label="Poll interval (s):")
        grid.attach(lbl, 0, 0, 1, 1)
        self.interval_spin = Gtk.SpinButton.new_with_range(5, 60, 1)
        self.interval_spin.set_value(settings.get_int("interval", DEFAULT_POLL_INTERVAL))
        grid.attach(self.interval_spin, 1, 0, 1, 1)

        # Autostart
        self.autostart_check = Gtk.CheckButton(label="Autostart on login")
        self.autostart_check.set_active(settings.get_boolean("autostart", False))
        grid.attach(self.autostart_check, 0, 1, 2, 1)

        # Buttons
        self.add_button("Cancel", Gtk.ResponseType.CANCEL)
        self.add_button("Save", Gtk.ResponseType.OK)
        self.show_all()

    def save(self):
        self.settings.set_int("interval", int(self.interval_spin.get_value()))
        self.settings.set_boolean("autostart", self.autostart_check.get_active())
        # If autostart changed, update the .desktop file in ~/.config/autostart
        if self.autostart_check.get_active():
            self._enable_autostart()
        else:
            self._disable_autostart()

    def _enable_autostart(self):
        subprocess.run(
            ["systemctl", "--user", "enable", "ds4-battery-tray.service"],
            check=False,
        )

    def _disable_autostart(self):
        subprocess.run(
            ["systemctl", "--user", "disable", "ds4-battery-tray.service"],
            check=False,
        )

# ----------------------------------------------------------------------
# Main Tray Application
# ----------------------------------------------------------------------
class DS4BatteryTrayApp:
    def __init__(self, poll_interval=DEFAULT_POLL_INTERVAL, verbose=False):
        self.poll_interval = poll_interval
        self.verbose = verbose
        self.settings = Settings()
        self.reading = BatteryReading(present=False)

        # Create indicator
        self.indicator = AppIndicator.Indicator.new(
            APP_ID,
            "input-gaming-symbolic",
            AppIndicator.IndicatorCategory.HARDWARE,
        )
        self.indicator.set_status(AppIndicator.IndicatorStatus.ACTIVE)
        self.indicator.set_title("DualShock 4 Battery")

        # Build menu
        self.status_item = Gtk.MenuItem(label="Searching...")
        self.status_item.set_sensitive(False)

        self.power_item = Gtk.MenuItem(label="Power: --")
        self.power_item.set_sensitive(False)

        self.connect_item = Gtk.MenuItem(label="Connect controller")
        self.connect_item.connect("activate", self.on_connect_clicked)

        self.disconnect_item = Gtk.MenuItem(label="Disconnect controller")
        self.disconnect_item.connect("activate", self.on_disconnect_clicked)
        self.disconnect_item.set_sensitive(False)

        self.show_window_item = Gtk.MenuItem(label="Show Battery Details")
        self.show_window_item.connect("activate", self.on_show_window)

        self.settings_item = Gtk.MenuItem(label="Settings")
        self.settings_item.connect("activate", self.on_settings)

        self.refresh_item = Gtk.MenuItem(label="Refresh")
        self.refresh_item.connect("activate", self.on_refresh_clicked)

        self.quit_item = Gtk.MenuItem(label="Quit")
        self.quit_item.connect("activate", self.on_quit)

        menu = Gtk.Menu()
        menu.append(self.status_item)
        menu.append(self.power_item)
        menu.append(Gtk.SeparatorMenuItem())
        menu.append(self.connect_item)
        menu.append(self.disconnect_item)
        menu.append(Gtk.SeparatorMenuItem())
        menu.append(self.show_window_item)
        menu.append(self.settings_item)
        menu.append(Gtk.SeparatorMenuItem())
        menu.append(self.refresh_item)
        menu.append(Gtk.SeparatorMenuItem())
        menu.append(self.quit_item)
        menu.show_all()
        self.indicator.set_menu(menu)

        # Connect click on the icon itself to show window
        self.indicator.set_secondary_activate_target(self.show_window_item)

        # Window and notification objects
        self.battery_window = None
        self.notification = None

        # Low battery alert state
        self._low_battery_notified = False

        # Bluetooth action state
        self._bt_busy = False
        self.mac = CONTROLLER_MAC

        # Start polling thread
        self._stop_event = threading.Event()
        self._poll_thread = threading.Thread(target=self._poll_loop, daemon=True)

        # Load initial poll interval from settings
        self.poll_interval = self.settings.get_int("interval", DEFAULT_POLL_INTERVAL)

    def start(self):
        self._poll_thread.start()
        Gtk.main()

    # ------------------------------------------------------------------
    # Polling loop
    # ------------------------------------------------------------------
    def _poll_loop(self):
        while not self._stop_event.is_set():
            reading = poll_battery(verbose=self.verbose)
            bt_connected = controller_connected(self.mac)
            GLib.idle_add(self._apply_reading, reading, bt_connected)
            # Sleep with interval from settings (re‑read each cycle)
            interval = self.settings.get_int("interval", DEFAULT_POLL_INTERVAL)
            self._stop_event.wait(interval)

    def _do_poll(self):
        reading = poll_battery(verbose=self.verbose)
        bt_connected = controller_connected(self.mac)
        GLib.idle_add(self._apply_reading, reading, bt_connected)

    # ------------------------------------------------------------------
    # UI updates (main thread)
    # ------------------------------------------------------------------
    def _apply_reading(self, reading: BatteryReading, bt_connected=None):
        self.reading = reading
        if bt_connected is None:
            bt_connected = controller_connected(self.mac)
        self._update_bt_actions(bt_connected)
        # Update tray icon and label
        if reading.present and reading.percentage is not None:
            pct = max(0, min(100, reading.percentage))
            icon = self._icon_for(pct, reading.state)
            power_txt = {
                "charging": "Charging",
                "full": "Fully charged",
                "discharging": "Discharging",
                "unknown": "Unknown",
            }.get(reading.state, "Unknown")
            label_txt = f" {pct}%"
            if reading.state == "charging":
                label_txt = f" {pct}% charging"
            elif reading.state == "full":
                label_txt = f" {pct}% full"
            self.indicator.set_icon_full(icon, f"Controller {power_txt.lower()} {pct}%")
            self.indicator.set_label(label_txt, " 100% charging")
            self.indicator.set_title(f"DualShock 4 Battery: {power_txt} {pct}%")
            self.status_item.set_label(f"Controller: Connected [{pct}%]")
            self.power_item.set_label(f"Power: {power_txt}")

            # Update window if open
            if self.battery_window:
                self.battery_window.update(reading)

            # Low battery notification (only once per low state)
            if pct <= LOW_BATTERY_THRESHOLD and reading.state != "charging":
                if not self._low_battery_notified:
                    self._send_notification(f"Battery low: {pct}%", "Connect your controller to charge.")
                    self._low_battery_notified = True
            else:
                self._low_battery_notified = False
        else:
            self.indicator.set_icon_full("input-gaming-symbolic", "No controller")
            self.indicator.set_label("", " 100%")
            self.indicator.set_title("DualShock 4 Battery: searching")
            if bt_connected:
                self.status_item.set_label("Controller: Connected, waiting for battery...")
            else:
                self.status_item.set_label("Searching for controller...")
            self.power_item.set_label("Power: --")
            if self.battery_window:
                self.battery_window.update(reading)

        return False  # one-shot

    def _icon_for(self, pct, state):
        if pct >= 90:
            level = "battery-full"
        elif pct >= 65:
            level = "battery-good"
        elif pct >= 35:
            level = "battery-low"
        elif pct >= 15:
            level = "battery-caution"
        else:
            level = "battery-empty"
        if state == "full":
            return "battery-full-charged-symbolic"
        if state == "charging":
            return f"{level}-charging-symbolic"
        return f"{level}-symbolic"

    # ------------------------------------------------------------------
    # Notifications (Gio)
    # ------------------------------------------------------------------
    def _send_notification(self, summary, body):
        try:
            app = Gio.Application.get_default()
            if not app:
                app = Gio.Application.new(APP_ID, Gio.ApplicationFlags.FLAGS_NONE)
                app.register()
            notification = Gio.Notification.new(summary)
            notification.set_body(body)
            # Set a default icon
            app.send_notification(None, notification)
        except Exception as e:
            if self.verbose:
                print(f"Notification failed: {e}", file=sys.stderr)

    # ------------------------------------------------------------------
    # Menu callbacks
    # ------------------------------------------------------------------
    def on_show_window(self, _):
        if self.battery_window is None:
            self.battery_window = BatteryWindow(self)
            if self.reading:
                self.battery_window.update(self.reading)
            self.battery_window.connect("destroy", self._window_destroyed)
            self.battery_window.show_all()
        else:
            self.battery_window.present()

    def _window_destroyed(self, _):
        self.battery_window = None

    def on_settings(self, _):
        dialog = SettingsDialog(self.battery_window or None, self.settings)
        response = dialog.run()
        if response == Gtk.ResponseType.OK:
            dialog.save()
            # Update polling interval from settings
            new_interval = self.settings.get_int("interval", DEFAULT_POLL_INTERVAL)
            if new_interval != self.poll_interval:
                self.poll_interval = new_interval
                # Restart polling thread to apply new interval
                self._stop_event.set()
                self._poll_thread.join(timeout=1)
                self._stop_event.clear()
                self._poll_thread = threading.Thread(target=self._poll_loop, daemon=True)
                self._poll_thread.start()
        dialog.destroy()

    def on_refresh_clicked(self, _):
        self.status_item.set_label("Refreshing...")
        threading.Thread(target=self._do_poll, daemon=True).start()

    # ------------------------------------------------------------------
    # Bluetooth connect / disconnect
    # ------------------------------------------------------------------
    def on_connect_clicked(self, _):
        self._bt_action(True)

    def on_disconnect_clicked(self, _):
        self._bt_action(False)

    def _bt_action(self, connect):
        if self._bt_busy:
            return
        self._bt_busy = True
        self.connect_item.set_sensitive(False)
        self.disconnect_item.set_sensitive(False)
        self.connect_item.set_label(
            "Connecting..." if connect else "Connect controller"
        )
        self.disconnect_item.set_label(
            "Disconnecting..." if not connect else "Disconnect controller"
        )
        threading.Thread(target=self._bt_worker, args=(connect,), daemon=True).start()

    def _bt_worker(self, connect):
        action = "connect" if connect else "disconnect"
        try:
            subprocess.run(
                ["bluetoothctl", action, self.mac],
                capture_output=True,
                text=True,
                timeout=30,
            )
        except Exception as exc:
            if self.verbose:
                print(f"bluetoothctl {action} failed: {exc}", file=sys.stderr)
        time.sleep(1.5)
        connected = controller_connected(self.mac)
        GLib.idle_add(self._bt_done, connect, connected)

    def _bt_done(self, connect, connected):
        self._bt_busy = False
        self.connect_item.set_label("Connect controller")
        self.disconnect_item.set_label("Disconnect controller")
        if connect and not connected:
            self._send_notification(
                "Controller connection failed",
                "Could not connect the DualShock 4.",
            )
        elif not connect and connected:
            self._send_notification(
                "Controller disconnect failed",
                "Could not disconnect the DualShock 4.",
            )
        self._update_bt_actions(connected)
        threading.Thread(target=self._do_poll, daemon=True).start()
        return False

    def _update_bt_actions(self, connected):
        self.connect_item.set_sensitive(not connected and not self._bt_busy)
        self.disconnect_item.set_sensitive(connected and not self._bt_busy)

    def on_quit(self, _):
        self._stop_event.set()
        # Stop the user service too, otherwise Restart=always brings the tray
        # straight back after the menu item is clicked.
        subprocess.run(
            ["systemctl", "--user", "stop", "ds4-battery-tray.service"],
            check=False,
        )
        Gtk.main_quit()

# ----------------------------------------------------------------------
# Main
# ----------------------------------------------------------------------
def parse_args():
    p = argparse.ArgumentParser()
    p.add_argument("--interval", type=int, default=DEFAULT_POLL_INTERVAL,
                   help=f"Poll interval (default {DEFAULT_POLL_INTERVAL})")
    p.add_argument("--verbose", action="store_true")
    return p.parse_args()

def main():
    args = parse_args()
    signal.signal(signal.SIGINT, signal.SIG_DFL)
    app = DS4BatteryTrayApp(poll_interval=args.interval, verbose=args.verbose)
    app.start()

if __name__ == "__main__":
    main()
