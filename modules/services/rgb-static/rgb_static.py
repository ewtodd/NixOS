#!/usr/bin/env python3
import argparse
import json
import sys
import time

from openrgb import OpenRGBClient
from openrgb.utils import RGBColor

# openrgb.service is Type=simple, so systemd calls it started well before the
# SDK server is listening. Ordering after it is not enough on a cold boot.
CONNECT_ATTEMPTS = 30
CONNECT_INTERVAL = 1.0

# Worse, the server starts listening while it is still enumerating: connecting
# early returns a partial device list. On this box the two DIMMs are there
# immediately and the GPU and motherboard arrive seconds later, so wait for the
# count to stop growing rather than painting whatever happens to be ready.
DETECT_POLL    = 0.5
DETECT_SETTLE  = 8.0
DETECT_TIMEOUT = 120.0

# Appearing in the device list is not the same as being ready. A mode command
# sent in the first moments after a controller is enumerated can be dropped by
# the hardware, and OpenRGB has no way to notice: it updates its own model
# regardless, so from then on the server reports Direct while the board is
# really still running its BIOS effect. Write immediately, so the lights come up
# without a delay, then keep re-applying (mode included, see below) on a
# schedule long enough to outlast the board waking up. Seconds after detection
# settled.
APPLY_PASSES = (0.0, 2.0, 5.0, 15.0, 30.0)


def parse_color(text):
    value = text.lstrip("#")
    if len(value) != 6:
        raise ValueError(f"colour must be 6 hex digits, got {text!r}")
    return RGBColor(int(value[0:2], 16), int(value[2:4], 16), int(value[4:6], 16))


def connect():
    for attempt in range(1, CONNECT_ATTEMPTS + 1):
        try:
            return OpenRGBClient(name="rgb-static")
        except (ConnectionError, OSError) as exc:
            if attempt == CONNECT_ATTEMPTS:
                raise
            print(f"waiting for the OpenRGB server ({exc})", flush=True)
            time.sleep(CONNECT_INTERVAL)


def wait_for_detection(client, expected):
    """Block until the server's device list looks complete.

    With `expected` set this is exact: the host config knows how many
    controllers the machine has. Without it, fall back to waiting for the count
    to stop growing, which is only a guess about detection timing.
    """
    deadline = time.monotonic() + DETECT_TIMEOUT
    count, changed_at = -1, time.monotonic()
    while time.monotonic() < deadline:
        client.update()
        found = len(client.devices)
        if found != count:
            print(f"detected {found} device(s)", flush=True)
            count, changed_at = found, time.monotonic()
        if expected:
            if found >= expected:
                return True
        elif found and time.monotonic() - changed_at >= DETECT_SETTLE:
            return True
        time.sleep(DETECT_POLL)

    if expected:
        print(
            f"only {count} of {expected} device(s) after {DETECT_TIMEOUT:.0f}s; "
            "colouring what was found",
            flush=True,
        )
    else:
        print(f"device list still settling after {DETECT_TIMEOUT:.0f}s, continuing", flush=True)
    return False


def pick_color(device_name, overrides, fallback):
    # Match on a substring so the key stays readable in the Nix config rather
    # than repeating OpenRGB's full device string.
    for pattern, color in overrides.items():
        if pattern.lower() in device_name.lower():
            return color
    return fallback


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--default-color", required=True)
    parser.add_argument("--device-colors", default="{}")
    parser.add_argument("--expect-devices", type=int, default=0)
    args = parser.parse_args()

    fallback = parse_color(args.default_color)
    overrides = {k: parse_color(v) for k, v in json.loads(args.device_colors).items()}

    client = connect()
    complete = wait_for_detection(client, args.expect_devices)
    if not client.devices:
        print("no devices reported by the OpenRGB server", flush=True)
        return 1

    failed = not complete
    started = time.monotonic()
    for number, offset in enumerate(APPLY_PASSES, start=1):
        pending = started + offset - time.monotonic()
        if pending > 0:
            time.sleep(pending)
        if number > 1:
            # Re-read, so a controller that a driver reset behind our back
            # shows its real mode rather than the one we think we set.
            client.update()

        tag = f"pass {number} (+{offset:g}s)"
        for dev in client.devices:
            color = pick_color(dev.name, overrides, fallback)
            try:
                # A device only honours colour writes while it is in a software
                # mode; left in a hardware effect it keeps running its own
                # animation and silently ignores us.
                modes = {mode.name.lower(): mode.name for mode in dev.modes}
                name = modes.get("direct") or modes.get("static")
                if name is not None:
                    # Re-send the mode every pass rather than trusting the
                    # cached one. A mode command dropped by a controller that
                    # was not ready yet still updates OpenRGB's model, so the
                    # cache happily reports Direct while the board is really
                    # still running its BIOS effect and ignoring colour data.
                    # Skipping on a cache hit is exactly what let the boot
                    # failure survive every retry.
                    if dev.modes[dev.active_mode].name != name:
                        print(f"{tag}: {dev.name}: mode -> {name}", flush=True)
                    dev.set_mode(name)
                dev.set_color(color)
                if number == 1:
                    print(
                        f"{tag}: {dev.name}: #{color.red:02X}{color.green:02X}{color.blue:02X}",
                        flush=True,
                    )
            except Exception as exc:
                failed = True
                print(f"{tag}: {dev.name}: FAILED: {exc}", flush=True)
        if number > 1:
            print(f"{tag}: re-applied to {len(client.devices)} device(s)", flush=True)

    client.disconnect()
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
