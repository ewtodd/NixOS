#!/usr/bin/env python3
"""
wireview-safety - WireView safety watchdog.

Polls the wireview-monitor exporter's /metrics and, when a dangerous
condition is sustained across several consecutive checks, powers the machine
off (or reboots). Redundancy on top of the hardware protection: the WireView
fault/alarm output is also wired to the mains switch.

Dangerous conditions (configurable via environment, see the NixOS module):
  - any WireView fault bit set (OTP / OCP / wire OCP / OPP / current
    imbalance) - the firmware's own fault detection
  - any reported temperature at or above WV_TEMP_THRESHOLD_C

Never triggers on missing/stale data: if the exporter reports the device is
down (wireview_up 0) or the metrics are unreachable, the counters reset.
"""

import logging
import os
import subprocess
import sys
import time
import urllib.request

log = logging.getLogger("wireview-safety")

METRICS_URL = os.environ.get("WV_METRICS_URL", "http://127.0.0.1:9877/metrics")
POLL_SECONDS = float(os.environ.get("WV_POLL_SECONDS", "5"))
CONSECUTIVE = int(os.environ.get("WV_CONSECUTIVE", "3"))
TEMP_THRESHOLD_C = float(os.environ.get("WV_TEMP_THRESHOLD_C", "85.0"))
TRIGGER_FAULTS = os.environ.get("WV_TRIGGER_FAULTS", "1") == "1"
ACTION = os.environ.get("WV_ACTION", "poweroff")
DRY_RUN = os.environ.get("WV_DRY_RUN", "0") == "1"

FAULTS = ("otp_tchip", "otp_ts", "ocp", "wire_ocp", "opp", "current_imbalance")
TEMP_SENSORS = ("onboard_in", "onboard_out", "external_1", "external_2")


def fetch_metrics(url):
    with urllib.request.urlopen(url, timeout=5) as resp:
        return resp.read().decode("utf-8")


def parse_metrics(text):
    """Extract wireview_up, the active fault bits and the temperatures from
    the Prometheus text exposition. Returns (up, faults, temps)."""
    up = None
    faults = []
    temps = {}
    for line in text.splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        name, _, value = line.partition(" ")
        if name == "wireview_up":
            up = float(value)
        elif name.startswith("wireview_fault_status{"):
            fault = name[name.index('"') + 1:name.rindex('"')]
            if float(value) > 0:
                faults.append(fault)
        elif name.startswith("wireview_temperature_c{"):
            sensor = name[name.index('"') + 1:name.rindex('"')]
            temps[sensor] = float(value)
    return up, faults, temps


def main():
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s %(levelname)s %(message)s",
        stream=sys.stderr,
    )
    log.info(
        "wireview-safety started: action=%s%s, poll %.0fs, %d consecutive checks, "
        "temp >= %.1f C, faults=%s",
        ACTION, " (DRY RUN)" if DRY_RUN else "",
        POLL_SECONDS, CONSECUTIVE, TEMP_THRESHOLD_C, TRIGGER_FAULTS)

    hits = 0
    while True:
        try:
            text = fetch_metrics(METRICS_URL)
            up, faults, temps = parse_metrics(text)
        except Exception as exc:
            log.warning("metrics fetch failed (%s); resetting counters", exc)
            up = 0
            faults = []
            temps = {}

        reasons = []
        if up != 1:
            # Device down or exporter unreachable: never act on missing data.
            hits = 0
        else:
            if TRIGGER_FAULTS and faults:
                reasons.append("faults: " + ", ".join(faults))
            for sensor, value in sorted(temps.items()):
                if value >= TEMP_THRESHOLD_C:
                    reasons.append("%s %.1f C >= %.1f C" % (sensor, value, TEMP_THRESHOLD_C))
            if reasons:
                hits += 1
                log.warning("dangerous condition %d/%d: %s",
                            hits, CONSECUTIVE, "; ".join(reasons))
            else:
                hits = 0

        if hits >= CONSECUTIVE:
            log.error("wireview safety trigger: %s -> %s",
                      "; ".join(reasons), ACTION)
            if DRY_RUN:
                log.error("dry run: would have run `systemctl %s`", ACTION)
            else:
                try:
                    subprocess.run(["systemctl", ACTION, "--no-block"], check=False)
                except OSError as exc:
                    log.error("failed to run systemctl %s: %s", ACTION, exc)
                # Keep the service alive (and quiet) while the machine goes
                # down so Restart=always does not respawn it mid-shutdown.
                time.sleep(60)

        time.sleep(POLL_SECONDS)


if __name__ == "__main__":
    sys.exit(main())
