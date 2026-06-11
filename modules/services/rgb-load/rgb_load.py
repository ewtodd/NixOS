#!/usr/bin/env python3
import argparse
import glob
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


def make_openrgb_emitter():
    from openrgb import OpenRGBClient
    from openrgb.utils import RGBColor

    client = OpenRGBClient()

    def emit(color):
        rgb = RGBColor(*color)
        for dev in client.devices:
            dev.set_color(rgb)

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
    args = parser.parse_args()

    read_cpu = make_cpu_reader()
    read_gpu = make_gpu_reader(args.gpu)
    emit, close = (
        make_openrgb_emitter() if args.backend == "openrgb" else make_framework_emitter()
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
