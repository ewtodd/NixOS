#!/usr/bin/env python3
import argparse
import glob
import json
import subprocess
import time

EMA_ALPHA       = 0.3
SAMPLE_INTERVAL = 0.5
RENDER_INTERVAL = 1 / 60
RENDER_LERP     = 0.15

# framework_tool talks to the EC over the cros_ec path, which is far too slow
# to drive at the 60 fps render rate. Cap hardware writes and skip duplicates.
FRAMEWORK_EMIT_INTERVAL = 0.1   # 10 Hz
FRAMEWORK_LEDS          = 8

AMDGPU_BUSY_GLOB = "/sys/class/drm/card*/device/gpu_busy_percent"

# openrgb.service is Type=simple and the SDK server starts listening part-way
# through enumeration: on e-desktop the GPU is listed at once and the board two
# seconds later. A client that takes the first list it gets never drives the
# late arrivals, so wait for the count the host config expects (rgb-static has
# the same wait).
CONNECT_ATTEMPTS = 30
CONNECT_INTERVAL = 1.0
DETECT_POLL      = 0.5
DETECT_SETTLE    = 8.0
DETECT_TIMEOUT   = 120.0

# A controller can drop a mode command sent just after it is enumerated while
# OpenRGB's model still records the new mode, so zone sizes and Direct are
# re-sent at these offsets (seconds after detection), as rgb-static does.
SETUP_PASSES = (0.0, 2.0, 5.0, 15.0, 30.0)


PINK_STOPS = (
    (255, 255, 255),
    (255, 182, 193),
    (190, 15, 110),
)


def load_to_color(load):
    t = min(max(load, 0), 100) / 100.0
    seg = t * (len(PINK_STOPS) - 1)
    i = min(int(seg), len(PINK_STOPS) - 2)
    f = seg - i
    a, b = PINK_STOPS[i], PINK_STOPS[i + 1]
    return (
        int(a[0] + (b[0] - a[0]) * f),
        int(a[1] + (b[1] - a[1]) * f),
        int(a[2] + (b[2] - a[2]) * f),
    )


def make_cpu_reader():
    def read_busy_total():
        with open("/proc/stat") as f:
            vals = list(map(int, f.readline().split()[1:]))
        idle = vals[3] + vals[4]  # idle + iowait
        return sum(vals), idle

    state = {"prev": read_busy_total()}

    def read_load():
        total, idle = read_busy_total()
        d_total = total - state["prev"][0]
        d_idle  = idle - state["prev"][1]
        state["prev"] = (total, idle)
        if d_total <= 0:
            return 0.0
        return (1 - d_idle / d_total) * 100

    return read_load


def make_gpu_reader(vendor):
    if vendor == "none":
        return lambda: 0.0

    if vendor == "nvidia":
        import pynvml
        pynvml.nvmlInit()
        gpu = pynvml.nvmlDeviceGetHandleByIndex(0)
        return lambda: float(pynvml.nvmlDeviceGetUtilizationRates(gpu).gpu)

    # amd: amdgpu exposes instantaneous busy percentage via sysfs.
    paths = glob.glob(AMDGPU_BUSY_GLOB)
    if not paths:
        raise RuntimeError(f"no amdgpu busy sysfs node found ({AMDGPU_BUSY_GLOB})")
    path = sorted(paths)[0]

    def read_load():
        with open(path) as f:
            return float(f.read().strip())

    return read_load


def connect_openrgb():
    from openrgb import OpenRGBClient

    for attempt in range(1, CONNECT_ATTEMPTS + 1):
        try:
            # Protocol 3, not the library's default 4: OpenRGB 1.0 in --server
            # mode never answers the protocol-4 plugin-list request, so
            # openrgb-python sits out a 10 s socket timeout and reconnects
            # before the constructor returns. Nothing here uses plugins.
            return OpenRGBClient(name="rgb-load", protocol_version=3)
        except (ConnectionError, OSError) as exc:
            if attempt == CONNECT_ATTEMPTS:
                raise
            print(f"rgb-load: waiting for the OpenRGB server ({exc})", flush=True)
            time.sleep(CONNECT_INTERVAL)


def wait_for_detection(client, expected):
    """Poll the server until it lists `expected` devices (0: until the count
    stops growing). Gives up after DETECT_TIMEOUT and carries on with whatever
    was found, so a missing controller costs its own lights, not the rest."""
    deadline = time.monotonic() + DETECT_TIMEOUT
    count, changed_at = -1, time.monotonic()
    while time.monotonic() < deadline:
        client.update()
        found = len(client.devices)
        if found != count:
            print(f"rgb-load: detected {found} device(s)", flush=True)
            count, changed_at = found, time.monotonic()
        if expected and found >= expected:
            return
        if not expected and found and time.monotonic() - changed_at >= DETECT_SETTLE:
            return
        time.sleep(DETECT_POLL)
    print(f"rgb-load: {count} device(s) after {DETECT_TIMEOUT:.0f}s, expected {expected}", flush=True)


def make_openrgb_emitter(expect_devices, zone_sizes, exclude):
    from openrgb.utils import RGBColor

    client = connect_openrgb()
    wait_for_detection(client, expect_devices)

    def excluded(dev):
        return any(pattern.lower() in dev.name.lower() for pattern in exclude)

    def targets():
        return [dev for dev in client.devices if not excluded(dev)]

    def setup():
        # ARGB header zones are resizable and come up with whatever size the
        # server has saved for the controller's location, 0 if none; colour
        # writes reach only the LEDs the zone claims.
        for dev in targets():
            for zone in dev.zones:
                size = zone_sizes.get(zone.name)
                if size is None or len(zone.leds) == size:
                    continue
                print(f"rgb-load: {dev.name}: {zone.name}: {len(zone.leds)} -> {size} LEDs", flush=True)
                try:
                    zone.resize(size)
                except Exception as exc:
                    print(f"rgb-load: {dev.name}: {zone.name}: cannot resize: {exc}", flush=True)
        client.update()

        # A device only honours per-LED colour writes while it is in a software
        # mode. Anything left in a hardware effect (the MSI board boots into
        # "Rainbow wave", the Gigabyte GPU into "Static") ignores the updates and
        # keeps running its own animation, so put every device into Direct first.
        # Sent unconditionally, never skipped because the cached mode already looks
        # right: a mode command the hardware drops still updates OpenRGB's model, so
        # the server can report Direct for a board that is really still running its
        # BIOS effect and ignoring every colour we write.
        for dev in targets():
            modes = {mode.name.lower(): mode.name for mode in dev.modes}
            name = modes.get("direct") or modes.get("static")
            if name is None:
                continue
            try:
                dev.set_mode(name)
            except Exception as exc:  # a device we cannot switch is not fatal
                print(f"rgb-load: {dev.name}: cannot set mode {name}: {exc}", flush=True)

    for dev in client.devices:
        state = "excluded" if excluded(dev) else f"{len(dev.leds)} LEDs"
        print(f"rgb-load: {dev.name}: {state}", flush=True)

    passes = list(SETUP_PASSES)
    detected_at = time.monotonic()

    def emit(color):
        if passes and time.monotonic() - detected_at >= passes[0]:
            passes.pop(0)
            setup()
        rgb = RGBColor(*color)
        for dev in targets():
            # fast: skip the full device read-back after every write, which for
            # the board is a few hundred LEDs parsed 60 times a second.
            dev.set_color(rgb, fast=True)

    def close():
        client.disconnect()

    return emit, close


def make_framework_emitter():
    state = {"last_t": 0.0, "last_color": None}

    def emit(color):
        now = time.monotonic()
        if color == state["last_color"]:
            return
        if now - state["last_t"] < FRAMEWORK_EMIT_INTERVAL:
            return
        hex_color = "0x{:02x}{:02x}{:02x}".format(*color)
        subprocess.run(
            ["framework_tool", "--rgbkbd", "0", *([hex_color] * FRAMEWORK_LEDS)],
            check=False,
        )
        state["last_t"] = now
        state["last_color"] = color

    return emit, (lambda: None)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--backend", choices=["openrgb", "framework"], required=True)
    parser.add_argument("--gpu", choices=["nvidia", "amd", "none"], default="none")
    parser.add_argument("--expect-devices", type=int, default=0)
    parser.add_argument("--zone-sizes", default="{}")
    parser.add_argument("--exclude-devices", default="[]")
    args = parser.parse_args()

    read_cpu = make_cpu_reader()
    read_gpu = make_gpu_reader(args.gpu)
    emit, close = (
        make_openrgb_emitter(
            args.expect_devices,
            json.loads(args.zone_sizes),
            json.loads(args.exclude_devices),
        )
        if args.backend == "openrgb"
        else make_framework_emitter()
    )

    last_sample = time.monotonic()
    smoothed = displayed = 0.0

    try:
        while True:
            now = time.monotonic()
            if now - last_sample >= SAMPLE_INTERVAL:
                load = max(read_cpu(), read_gpu())
                smoothed = EMA_ALPHA * load + (1 - EMA_ALPHA) * smoothed
                last_sample = now

            displayed += (smoothed - displayed) * RENDER_LERP
            emit(load_to_color(displayed))
            time.sleep(RENDER_INTERVAL)
    except KeyboardInterrupt:
        close()


if __name__ == "__main__":
    main()
