"""Move the pin in .factorio-version to Factorio's newest stable release.

factorio-version.yml runs this every day. When Factorio has a newer stable
headless release, the tool writes it into .factorio-version and adds
`version=X.Y.Z` to $GITHUB_OUTPUT. The workflow then opens a PR, and CI
runs every test on the new version.

    python3 -m tools.factorio_version
"""
from __future__ import annotations

import json
import os
import pathlib
import re
import sys
import urllib.request
from typing import Callable, Mapping

ROOT = pathlib.Path(__file__).resolve().parents[1]
URL = "https://factorio.com/api/latest-releases"
# ASCII digits only, matched against the whole string: the workflow puts
# the version in $GITHUB_OUTPUT, a branch name and a PR title.
SEMVER = re.compile(r"[0-9]+\.[0-9]+\.[0-9]+")


def _numbers(version: str) -> tuple[int, ...]:
    return tuple(int(part) for part in version.split("."))


def check(latest: object, pinned: str) -> tuple[str | None, list[str]]:
    """Return the newer stable version, or None, and the format problems."""
    stable = latest.get("stable") if isinstance(latest, dict) else None
    headless = stable.get("headless") if isinstance(stable, dict) else None
    if not isinstance(headless, str) or not SEMVER.fullmatch(headless):
        return None, [f"{URL} has no stable headless version; its format may have changed"]
    if not SEMVER.fullmatch(pinned):
        return None, [f".factorio-version holds {pinned!r}, not X.Y.Z"]
    if _numbers(headless) > _numbers(pinned):
        return headless, []
    return None, []


def _fetch() -> object:
    request = urllib.request.Request(URL, headers={"User-Agent": "abominable-ordnance-ci"})
    with urllib.request.urlopen(request, timeout=30) as response:
        return json.load(response)


def main(root: pathlib.Path = ROOT, fetch: Callable[[], object] = _fetch,
         env: Mapping[str, str] = os.environ) -> int:
    pin_file = root / ".factorio-version"
    pinned = pin_file.read_text(encoding="utf-8").strip()
    try:
        latest = fetch()
    except (OSError, ValueError) as error:
        print(f"factorio version: cannot read {URL}: {error}", file=sys.stderr)
        return 1
    newer, found = check(latest, pinned)
    for problem in found:
        print(f"factorio version: {problem}", file=sys.stderr)
    if found:
        return 1
    if not newer:
        print(f"factorio version: {pinned} is the newest stable release")
        return 0
    pin_file.write_text(newer + "\n", encoding="utf-8")
    if env.get("GITHUB_OUTPUT"):
        with open(env["GITHUB_OUTPUT"], "a", encoding="utf-8") as out:
            out.write(f"version={newer}\n")
    print(f"factorio version: wrote {newer} over {pinned}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
