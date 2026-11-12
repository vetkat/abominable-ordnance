"""Turn CHANGELOG.md into Factorio's changelog.txt.

CHANGELOG.md uses the Keep a Changelog 1.0.0 format, and it is the only
changelog that people edit. Factorio reads changelog.txt from the mod zip,
so package.py renders it at build time. The file is never committed.

    python3 -m tools.changelog              # print changelog.txt
    python3 -m tools.changelog notes 0.1.0  # print the release notes
"""
from __future__ import annotations

import json
import pathlib
import re
import sys
from typing import NamedTuple

ROOT = pathlib.Path(__file__).resolve().parents[1]

# Factorio does not load a mod whose changelog blocks lack this line.
SEPARATOR = "-" * 99

CATEGORY = {
    "Added": "Features",
    "Changed": "Changes",
    "Deprecated": "Changes",
    "Removed": "Changes",
    "Fixed": "Bugfixes",
    "Security": "Bugfixes",
}
ORDER = ("Features", "Changes", "Bugfixes")

RELEASE = re.compile(
    r"^## \[(?P<version>[^\]]+)\](?: - (?P<date>\d{4}-\d{2}-\d{2}))?\s*$")
GROUP = re.compile(r"^### (?P<name>\S.*?)\s*$")
ITEM = re.compile(r"^- (?P<text>.+)$")
CONTINUATION = re.compile(r"^ {2,}(?P<text>\S.*)$")


class Release(NamedTuple):
    version: str  # "Unreleased" or X.Y.Z
    date: str | None
    groups: tuple[tuple[str, tuple[str, ...]], ...]


class Parsed(NamedTuple):
    releases: tuple[Release, ...]
    problems: tuple[str, ...]


def parse(text: str) -> Parsed:
    # These lists are created here, so filling them in place is safe.
    releases: list[tuple[str, str | None, list]] = []
    problems: list[str] = []
    group: tuple[str, list[str]] | None = None
    for no, line in enumerate(text.splitlines(), 1):
        if line.startswith("## "):
            group = None
            match = RELEASE.match(line)
            if match:
                releases.append((match["version"], match["date"], []))
            else:
                problems.append(f"line {no}: release heading not understood: {line}")
        elif line.startswith("###"):
            match = GROUP.match(line)
            name = match["name"] if match else ""
            if not releases:
                problems.append(f"line {no}: heading {name!r} is outside a release")
                group = None
                continue
            if name not in CATEGORY:
                problems.append(
                    f"line {no}: unknown heading {name!r}, use one of {', '.join(CATEGORY)}")
            group = (name, [])
            releases[-1][2].append(group)
        elif ITEM.match(line):
            if group is None:
                problems.append(f"line {no}: list item outside a ### heading")
            else:
                group[1].append(ITEM.match(line)["text"])
        elif CONTINUATION.match(line) and group is not None and group[1]:
            group[1][-1] += " " + CONTINUATION.match(line)["text"]
    frozen = tuple(
        Release(version, date, tuple((name, tuple(items)) for name, items in groups))
        for version, date, groups in releases)
    return Parsed(frozen, tuple(problems))


def _by_category(release: Release) -> dict[str, tuple[str, ...]]:
    result: dict[str, tuple[str, ...]] = {}
    for heading, items in release.groups:
        category = CATEGORY.get(heading)
        if category:
            result[category] = result.get(category, ()) + items
    return result


def render(releases: tuple[Release, ...], current_version: str) -> str:
    """Factorio's changelog.txt. Unreleased becomes current_version."""
    released = {r.version for r in releases if r.version != "Unreleased"}
    blocks = []
    for release in releases:
        if release.version == "Unreleased":
            if current_version in released:
                continue
            version = current_version
        else:
            version = release.version
        by_category = _by_category(release)
        if not any(by_category.values()):
            continue
        lines = [SEPARATOR, f"Version: {version}"]
        if release.date:
            lines.append(f"Date: {release.date}")
        for category in ORDER:
            if by_category.get(category):
                lines.append(f"  {category}:")
                lines.extend(f"    - {item}" for item in by_category[category])
        blocks.append("\n".join(lines))
    return "\n".join(blocks) + "\n" if blocks else ""


def notes(releases: tuple[Release, ...], version: str) -> str:
    """The Markdown of one version's section, for the GitHub release."""
    for release in releases:
        if release.version == version:
            parts = [f"### {heading}\n\n" + "".join(f"- {item}\n" for item in items)
                     for heading, items in release.groups if items]
            return "\n".join(parts)
    return ""


def main(argv: list[str]) -> int:
    parsed = parse((ROOT / "CHANGELOG.md").read_text(encoding="utf-8"))
    for problem in parsed.problems:
        print(f"changelog: {problem}", file=sys.stderr)
    if parsed.problems:
        return 1
    if len(argv) == 3 and argv[1] == "notes":
        sys.stdout.write(notes(parsed.releases, argv[2]))
        return 0
    info = json.loads((ROOT / "info.json").read_text(encoding="utf-8"))
    sys.stdout.write(render(parsed.releases, info["version"]))
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
