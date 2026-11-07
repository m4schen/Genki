#!/usr/bin/env python3
"""Print the UDID of an iPhone 17 simulator that can run Genki on CI.

CI runner images list simulator devices, but a given Xcode may not see any
of them. So this script picks the lowest available iOS runtime that is at
least the app's minimum (26.5), then reuses an iPhone 17 on it or creates
one. If no runtime qualifies, it lists the runtimes it found and fails.
"""

import json
import subprocess
import sys

MINIMUM_IOS = (26, 5)
DEVICE_TYPE = "com.apple.CoreSimulator.SimDeviceType.iPhone-17"


def simctl(*args: str) -> str:
    return subprocess.run(
        ["xcrun", "simctl", *args], check=True, capture_output=True, text=True
    ).stdout


def version(runtime: dict) -> tuple[int, ...]:
    return tuple(int(part) for part in runtime["version"].split(".")[:2])


def main() -> int:
    runtimes = [
        r for r in json.loads(simctl("list", "runtimes", "-j"))["runtimes"]
        if r.get("platform") == "iOS" and r.get("isAvailable")
    ]
    print("iOS runtimes:", ", ".join(r["version"] for r in runtimes) or "none", file=sys.stderr)

    eligible = sorted((r for r in runtimes if version(r) >= MINIMUM_IOS), key=version)
    if not eligible:
        print(f"No available iOS runtime >= {MINIMUM_IOS[0]}.{MINIMUM_IOS[1]}", file=sys.stderr)
        return 1
    runtime = eligible[0]

    devices = json.loads(simctl("list", "devices", "available", "-j"))["devices"]
    for device in devices.get(runtime["identifier"], []):
        if device.get("deviceTypeIdentifier") == DEVICE_TYPE:
            print(f"Using {device['name']} on iOS {runtime['version']}", file=sys.stderr)
            print(device["udid"])
            return 0

    udid = simctl("create", "Genki CI iPhone 17", DEVICE_TYPE, runtime["identifier"]).strip()
    print(f"Created Genki CI iPhone 17 on iOS {runtime['version']}", file=sys.stderr)
    print(udid)
    return 0


if __name__ == "__main__":
    sys.exit(main())
