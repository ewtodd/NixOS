#!/usr/bin/env python3
import argparse
import time
from openrgb import OpenRGBClient
from openrgb.utils import RGBColor

EMA_ALPHA       = 0.3
SAMPLE_INTERVAL = 0.5
RENDER_INTERVAL = 1 / 60
RENDER_LERP     = 0.15
CPU_REF_W       = 125.0

RAPL_PATH     = "/sys/class/powercap/intel-rapl:0/energy_uj"
RAPL_MAX_PATH = "/sys/class/powercap/intel-rapl:0/max_energy_range_uj"


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
    return RGBColor(
        int(a[0] + (b[0] - a[0]) * f),
        int(a[1] + (b[1] - a[1]) * f),
        int(a[2] + (b[2] - a[2]) * f),
    )


def make_cpu_reader():
    with open(RAPL_MAX_PATH) as f:
        rapl_wrap = int(f.read().strip())

    def read_uj():
        with open(RAPL_PATH) as f:
            return int(f.read().strip())

    state = {"prev_uj": read_uj(), "prev_t": time.monotonic()}

    def read_load():
        now_uj = read_uj()
        now_t  = time.monotonic()
        delta  = now_uj - state["prev_uj"]
        if delta < 0:
            delta += rapl_wrap
        watts = (delta / 1e6) / (now_t - state["prev_t"])
        state["prev_uj"], state["prev_t"] = now_uj, now_t
        return min(watts / CPU_REF_W, 1.0) * 100

    return read_load


def make_gpu_reader():
    import pynvml
    pynvml.nvmlInit()
    gpu = pynvml.nvmlDeviceGetHandleByIndex(0)

    def read_load():
        return float(pynvml.nvmlDeviceGetUtilizationRates(gpu).gpu)

    return read_load


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--mode", choices=["cpu", "gpu"], required=True)
    args = parser.parse_args()

    read_load = make_cpu_reader() if args.mode == "cpu" else make_gpu_reader()
    client = OpenRGBClient()

    last_sample = time.monotonic()
    smoothed = displayed = 0.0

    try:
        while True:
            now = time.monotonic()
            if now - last_sample >= SAMPLE_INTERVAL:
                load = read_load()
                smoothed = EMA_ALPHA * load + (1 - EMA_ALPHA) * smoothed
                last_sample = now

            displayed += (smoothed - displayed) * RENDER_LERP
            color = load_to_color(displayed)
            for dev in client.devices:
                dev.set_color(color)
            time.sleep(RENDER_INTERVAL)
    except KeyboardInterrupt:
        client.disconnect()


if __name__ == "__main__":
    main()
