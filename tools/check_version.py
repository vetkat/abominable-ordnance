"""Check that the version agrees everywhere it appears.

info.json is the source of truth. CHANGELOG.md must agree with it, and a
release tag must name it.

    python3 -m tools.check_version          # every commit, and the dry run
    python3 -m tools.check_version v0.1.0   # a release
"""
from __future__ import annotations

import json
import pathlib
import re
import sys

from tools import changelog

ROOT = pathlib.Path(__file__).resolve().parents[1]
SEMVER = re.compile(r"^\d+\.\d+\.\d+$")
REQUIRED_KEYS = ("name", "version", "title", "author", "factorio_version",
                 "description", "dependencies")
# Factorio 2.1 refuses to load a mod that says "2.0".
FACTORIO_VERSION = "2.1"
REQUIRED_DEPENDENCIES = ("base >= 2.1", "? space-age")


def manifest_problems(info: object) -> list[str]:
    if not isinstance(info, dict):
        return ["info.json is not a JSON object"]
    missing = [key for key in REQUIRED_KEYS if key not in info]
    if missing:
        return [f"info.json has no {key!r}" for key in missing]
    problems = []
    if not SEMVER.match(str(info["version"])):
        problems.append(f"info.json version {info['version']!r} is not X.Y.Z")
    if info["factorio_version"] != FACTORIO_VERSION:
        problems.append(f"info.json factorio_version is {info['factorio_version']!r}, "
                        f"not {FACTORIO_VERSION!r}")
    dependencies = info["dependencies"] if isinstance(info["dependencies"], list) else []
    for dependency in REQUIRED_DEPENDENCIES:
        if dependency not in dependencies:
            problems.append(f"info.json dependencies lack {dependency!r}")
    return problems


def _has_entries(release: changelog.Release) -> bool:
    return any(items for _, items in release.groups)


def changelog_problems(version: str, releases: tuple[changelog.Release, ...],
                       tag: str | None) -> list[str]:
    if not releases:
        return ["CHANGELOG.md has no release sections"]
    if tag is None:
        newest = releases[0].version
        if newest in ("Unreleased", version):
            return []
        return [f"the newest section of CHANGELOG.md is {newest}, but info.json says {version}"]
    problems = []
    if tag != f"v{version}":
        problems.append(f"tag {tag} does not match info.json (v{version})")
    if any(r.version == "Unreleased" and _has_entries(r) for r in releases):
        problems.append("CHANGELOG.md still has entries under Unreleased; "
                        "move them into the release section")
    versioned = [r for r in releases if r.version != "Unreleased"]
    if not versioned or versioned[0].version != version:
        problems.append(f"CHANGELOG.md has no section for {version} at the top")
    elif versioned[0].date is None:
        problems.append(f"the {version} section of CHANGELOG.md has no date")
    return problems


def problems(info_text: str, changelog_text: str, tag: str | None) -> list[str]:
    try:
        info = json.loads(info_text)
    except json.JSONDecodeError as error:
        return [f"info.json is not valid JSON: {error}"]
    found = manifest_problems(info)
    if found:
        return found
    parsed = changelog.parse(changelog_text)
    return list(parsed.problems) + changelog_problems(info["version"], parsed.releases, tag)


def main(argv: list[str]) -> int:
    tag = argv[1] if len(argv) > 1 else None
    try:
        info_text = (ROOT / "info.json").read_text(encoding="utf-8")
        changelog_text = (ROOT / "CHANGELOG.md").read_text(encoding="utf-8")
    except OSError as error:
        print(f"version check: {error}", file=sys.stderr)
        return 1
    found = problems(info_text, changelog_text, tag)
    for problem in found:
        print(f"version check: {problem}", file=sys.stderr)
    if found:
        return 1
    print("version check: consistent" + (f", tag {tag}" if tag else ""))
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
