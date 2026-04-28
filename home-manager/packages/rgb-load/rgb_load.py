#!/usr/bin/env python3
import argparse
import time
import colorsys
from openrgb import OpenRGBClient
from openrgb.utils import RGBColor

EMA_ALPHA       = 0.3
SAMPLE_INTERVAL = 0.5
RENDER_INTERVAL = 1 / 60
RENDER_LERP     = 0.15
CPU_REF_W       = 125.0

RAPL_PATH     = "/sys/class/powercap/intel-rapl:0/energy_uj"
RAPL_MAX_PATH = "/sys/class/powercap/intel-rapl:0/max_energy_range_uj"


def load_to_color(load):
    hue = (1.0 - min(load, 100) / 100.0) * (120.0 / 360.0)
    r, g, b = colorsys.hsv_to_rgb(hue, 1.0, 1.0)
    return RGBColor(int(r * 255), int(g * 255), int(b * 255))


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
