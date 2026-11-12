"""Build the mod zip.

The zip holds one folder, <name>_<version>, with info.json at its root.
Only the files that the game needs ship. changelog.txt is rendered from
CHANGELOG.md into the zip and never written to the repository.

    python3 -m tools.package    # writes build/<name>_<version>.zip
"""
from __future__ import annotations

import json
import pathlib
import subprocess
import sys
import zipfile
from typing import NamedTuple

from tools import changelog

ROOT = pathlib.Path(__file__).resolve().parents[1]

# A folder entry ends with "/". The build fails without a REQUIRED entry.
REQUIRED = ("info.json", "LICENSE", "data.lua", "control.lua", "locale/")
OPTIONAL = ("thumbnail.png", "data-updates.lua", "data-final-fixes.lua",
            "settings.lua", "settings-updates.lua", "settings-final-fixes.lua",
            "core/", "prototypes/", "graphics/", "tests/ingame/")
SHIP = REQUIRED + OPTIONAL


class Entry(NamedTuple):
    name: str           # the path inside the zip
    source: str | None  # a repository file, or None for generated text
    text: str | None


def _matches(path: str, entry: str) -> bool:
    return path == entry or (entry.endswith("/") and path.startswith(entry))


def is_shipped(path: str) -> bool:
    name = path.rsplit("/", 1)[-1]
    return not name.startswith(".") and any(_matches(path, entry) for entry in SHIP)


def is_mod_code(path: str) -> bool:
    """A change to this file needs an entry in CHANGELOG.md."""
    return is_shipped(path) and path != "LICENSE" and not path.startswith("tests/")


def missing_required(files: list[str]) -> list[str]:
    return [entry for entry in REQUIRED if not any(_matches(f, entry) for f in files)]


def plan(stem: str, files: list[str], changelog_txt: str) -> list[Entry]:
    entries = [Entry(f"{stem}/{f}", f, None) for f in files if is_shipped(f)]
    if changelog_txt:
        entries.append(Entry(f"{stem}/changelog.txt", None, changelog_txt))
    return sorted(entries)


def build(root: pathlib.Path, files: list[str],
          out_dir: pathlib.Path) -> tuple[pathlib.Path | None, list[str]]:
    info = json.loads((root / "info.json").read_text(encoding="utf-8"))
    parsed = changelog.parse((root / "CHANGELOG.md").read_text(encoding="utf-8"))
    problems = list(parsed.problems) + [
        f"missing from the repository: {entry}" for entry in missing_required(files)]
    if problems:
        return None, problems
    stem = f"{info['name']}_{info['version']}"
    out_dir.mkdir(parents=True, exist_ok=True)
    out = out_dir / f"{stem}.zip"
    with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as archive:
        for entry in plan(stem, files, changelog.render(parsed.releases, info["version"])):
            if entry.source is None:
                archive.writestr(entry.name, entry.text)
            else:
                archive.write(root / entry.source, entry.name)
    return out, []


def tracked_files(root: pathlib.Path) -> list[str]:
    result = subprocess.run(["git", "ls-files"], cwd=root,
                            capture_output=True, text=True, check=True)
    return result.stdout.splitlines()


def main() -> int:
    out, problems = build(ROOT, tracked_files(ROOT), ROOT / "build")
    for problem in problems:
        print(f"package: {problem}", file=sys.stderr)
    if out is None:
        return 1
    print(f"package: built {out.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
