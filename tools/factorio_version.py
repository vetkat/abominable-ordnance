"""Fail when Factorio has a newer stable headless version than the pin.

weekly.yml runs this once a week. The maintainer's game updates through
Steam, so CI must notice when it tests an older version.

    python3 -m tools.factorio_version
"""
from __future__ import annotations

import json
import pathlib
import re
import sys
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parents[1]
URL = "https://factorio.com/api/latest-releases"
SEMVER = re.compile(r"^\d+\.\d+\.\d+$")


def _numbers(version: str) -> tuple[int, ...]:
    return tuple(int(part) for part in version.split("."))


def problems(latest: object, pinned: str) -> list[str]:
    stable = latest.get("stable") if isinstance(latest, dict) else None
    headless = stable.get("headless") if isinstance(stable, dict) else None
    if not isinstance(headless, str) or not SEMVER.match(headless):
        return [f"{URL} has no stable headless version; its format may have changed"]
    if not SEMVER.match(pinned):
        return [f".factorio-version holds {pinned!r}, not X.Y.Z"]
    if _numbers(headless) > _numbers(pinned):
        return [f"Factorio {headless} is the stable release, but .factorio-version "
                f"pins {pinned}. Open a PR that moves the pin."]
    return []


def main() -> int:
    pinned = (ROOT / ".factorio-version").read_text(encoding="utf-8").strip()
    request = urllib.request.Request(URL, headers={"User-Agent": "abominable-ordnance-ci"})
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            latest = json.load(response)
    except (OSError, ValueError) as error:
        print(f"factorio version: cannot read {URL}: {error}", file=sys.stderr)
        return 1
    found = problems(latest, pinned)
    for problem in found:
        print(f"factorio version: {problem}", file=sys.stderr)
    if not found:
        print(f"factorio version: {pinned} is the newest stable release")
    return 1 if found else 0


if __name__ == "__main__":
    raise SystemExit(main())
