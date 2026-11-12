# Repository and CI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task-by-task. Steps
> use checkbox (`- [ ]`) syntax for tracking.

**Goal:** An empty Factorio 2.1 mod that loads with and without Space Age,
behind every gate from the spec, locally and in CI on GitHub.

**Architecture:** Each check is a small Python or Lua tool with a pure core
and a thin shell (the functional-core skill). Make targets run the checks.
A git hook, a Claude Code hook and GitHub Actions call those targets.

**Tech Stack:** Python 3.12+ (standard library, pytest), Lua 5.2 (busted,
luacheck, luacov), mdl (Ruby), cspell and factorio-test-cli (Node), lychee,
GNU Make, GitHub Actions, Factorio 2.1.24 headless.

**Spec:** `docs/superpowers/specs/2026-11-12-repo-and-ci-design.md`

## Global Constraints

- All text is British English.
- `info.json`: `factorio_version` "2.1", dependencies `base >= 2.1` and
  `? space-age`, version 0.1.0, unreleased.
- Pinned: Factorio headless 2.1.24, `factorio-test` mod 3.2.0,
  `factorio-test-cli` 3.9.0, Lua 5.2. Other tools float.
- `tools/` uses the Python standard library only. pytest is for tests.
  Code runs on Python 3.12 (CI) and 3.14 (the maintainer's machine).
- `core/` is pure Lua 5.2 and never names `game`, `storage`, `script` or
  `defines`. Neither `core/` nor `control.lua` uses `math.random`.
- Every tool follows the functional-core rules: a pure, total core that
  returns problems as values, and a thin shell that does the I/O.
- Markdown passes `mdl` with the existing `.mdlrc` and `.mdl-style.rb`.
- The text check fails on any finding. An accepted exception goes in
  `.ste-allow` with a reason.
- `check.yml` uses no secrets.
- Commit messages and PR titles are Conventional Commits.
- Never commit `docs/archive/`.
- From Task 16 on, every commit goes in this order, each command as its
  own Bash call: run `/ste80-humanizer` on changed prose and comments and
  `/simplify` on changed code, then `git add` the files, then `make stamp`,
  then `git commit`. The Claude Code hook refuses a commit that stages
  files in the same command.
- Deviation from the spec: the vendored `factorio-test` zip lives in
  `tools/vendor/`, not in `tests/ingame/vendor/`. The mod zip ships
  `tests/ingame/`, and a third-party mod must not ship inside this mod.
- Deviation from the spec: mod code (for the changelog rule) is every
  shipped file except `changelog.txt`, `LICENSE` and `tests/`. A licence
  or test change needs no changelog entry.
- "Failure log": an attempt is a change that you expected to make a check
  pass. The planned red run of TDD is not an attempt. A planned
  adaptation that a step names ("adapt the pattern") counts as one. Add
  one line per failed attempt under the task. After 3 failed attempts on
  one task, stop and hand back to the maintainer (vetkat) with the log.
- The executor's ledger is
  `.superpowers/sdd/2026-11-12-repo-and-ci/progress.md`. Notes that a later
  task needs go there.

## Review Focus

- A chained `git add . && git commit` or `git commit -a` stages files
  after the hook checked the stamp. The Claude hook must refuse both
  (Task 16).
- A PR whose title or labels change after the checks ran. The `pr` job
  must run again on `edited`, `labeled` and `unlabeled` (Task 20).
- A dry run while `Unreleased` has entries and `info.json` names a version
  that is already released. `changelog.txt` must not get two blocks for
  one version (Task 4).
- American API names in code, such as `color` in Lua code or in a Markdown
  code span. The text check must not flag them (Tasks 12 and 13).
- A broken `info.json` or a missing `CHANGELOG.md`. The version check must
  print a problem, not a traceback (Task 5).

## File map

| File | Responsibility | Task |
| --- | --- | --- |
| (none) | the local tools | 0 |
| `docs/design.md` | the design document in Markdown | 1, 2 |
| `docs/architecture.md` | the architecture rules, for 2.1 | 3 |
| `pyproject.toml` | pytest settings | 4 |
| `tools/changelog.py` | parse CHANGELOG.md, render changelog.txt and notes | 4 |
| `tools/check_version.py` | manifest and version agreement | 5 |
| `info.json`, `CHANGELOG.md` | the mod manifest and its changelog | 5 |
| `tools/package.py` | the ship list and the zip | 6 |
| `tools/pr_checks.py` | PR title and the changelog rule | 7 |
| `.busted`, `.luacheckrc` | Lua test and lint settings | 8 |
| `spec/support/architecture.lua`, `spec/architecture_spec.lua` | the architecture rules | 8 |
| `data.lua`, `control.lua`, `locale/en/locale.cfg`, `core/.gitkeep` | the empty mod | 9 |
| `spec/support/locale.lua`, `spec/locale_spec.lua` | locale checks | 9 |
| `.luacov`, `tools/coverage_floor.py` | the coverage floor | 10 |
| `spec/docs_spec.lua` | docs against code | 11 |
| `tools/prose.py` | prose extraction | 12 |
| `tools/text_check.py`, `tools/vendor/ste_check.py`, `THIRD_PARTY.md` | the text check | 13, 14 |
| `tools/vendor/factorio-test_3.2.0.zip` | the vendored in-game test mod, committed | 13 |
| `package.json`, `cspell.json`, `.ste-allow` | cspell and exceptions | 14 |
| `Makefile`, `.githooks/pre-commit`, `lychee.toml` | gates | 15 |
| `tools/tests/test_gates.py` | planted mistakes for third-party gates | 15 |
| `tools/review_stamp.py`, `.claude/settings.json` | the Claude Code hook | 16 |
| `CLAUDE.md`, `README.md`, `ROADMAP.md`, `LICENSE`, PR template | docs | 17 |
| `tools/ingame.sh`, `tests/ingame/smoke_test.lua`, `.factorio-version`, `.factorio-test-version` | in-game tests | 18 |
| `tools/factorio_version.py` | the weekly version check | 19 |
| `.github/workflows/check.yml`, `.github/dependabot.yml` | CI | 20 |
| `.github/workflows/release.yml`, `.github/workflows/weekly.yml` | release and weekly jobs | 21 |
| GitHub settings | repository, protection, acceptance | 22 |

Each task ends with a commit. Each task also has an empty "Failure log"
list (see Global Constraints).

---

### Task 0: Check the local tools

The maintainer installed the tools on 2026-11-12. This task checks them
and defines `$BUSTED`, which later steps use.

- [ ] **Step 1: Check each tool**

```bash
for tool in pdftotext python3 pytest lua5.2 luacheck luarocks mdl lychee node npm make gh; do
  command -v "$tool" >/dev/null || echo "MISSING: $tool"
done
eval "$(luarocks --lua-version 5.2 path)"
lua5.2 -e 'require("luacov.runner"); require("lfs")' && echo "luacov and lfs load"
ls tools/vendor/factorio-test_3.2.0.zip
```

Expected: no `MISSING` line, `luacov and lfs load`, and the zip path.
Install a missing tool on Arch with these commands:

```bash
sudo pacman -S poppler lua52 lua52-busted luacheck luarocks lychee ruby nodejs npm python-pytest
gem install mdl
luarocks --lua-version 5.2 install --local luacov
```

Without the zip, stop and ask the maintainer: it needs a mod portal login.

- [ ] **Step 2: Define `$BUSTED`**

On Arch, the `lua52-busted` package puts busted outside `PATH`. Every
later step that runs busted uses this variable:

```bash
BUSTED="lua5.2 $(ls /usr/lib/luarocks/rocks-5.2/busted/*/bin/busted | tail -1) --lua=lua5.2"
$BUSTED --version
```

Expected: a version number such as `2.3.0`.

Failure log:

### Task 1: Convert the design document

The text check does not exist yet, so the faithful conversion can land as
it is. Task 14 cleans up what the text check finds.

**Files:**

- Create: `docs/design.md`
- Source: `docs/archive/old chat logs/Abominable-Ordnance-design-doc.pdf`
  (the same file as `~/Downloads/Abominable-Ordnance-design-doc.pdf`)

- [ ] **Step 1: Extract the text**

Run:

```bash
pdftotext -layout "docs/archive/old chat logs/Abominable-Ordnance-design-doc.pdf" /tmp/design.txt
```

Also read the PDF with the Read tool (pages 1 to 20 at a time) to see the
diagrams, tables and headings.

- [ ] **Step 2: Write `docs/design.md`**

Rules for the conversion:

1. Keep every heading, paragraph, list, table and open question in the
   PDF's order. Do not reword anything.
2. Change "Factorio 2.0" and "2.0" (as a game version) to "2.1".
3. Draw the lifecycle chart (eggs, embryos and larvae) and the research
   tree as Mermaid `flowchart` diagrams in fenced `mermaid` code blocks.
4. Use straight quotes. Keep em dashes for now (Task 2 removes them).
5. Wrap prose at 80 characters. Tables do not wrap.

- [ ] **Step 3: Check the conversion**

Run: `mdl docs/design.md`
Expected: no output.
Then compare the headings of the PDF text with the Markdown:
`grep -c '^#' docs/design.md`. Every PDF section must have a heading.

- [ ] **Step 4: Commit**

```bash
git add docs/design.md
git commit -m "docs: convert the design document to Markdown"
```

Failure log:

### Task 2: Humanizer pass on the design document

**Files:**

- Modify: `docs/design.md`

- [ ] **Step 1: Run `/ste80-humanizer` in Humanize mode on `docs/design.md`**

British English. File mode. Keep every fact, name and number. Mermaid
blocks and tables keep their content. Remove every em dash and en dash
from the prose.

- [ ] **Step 2: Check**

Run:

```bash
mdl docs/design.md && python3 -I ~/.agents/skills/ste80-humanizer/scripts/ste_check.py docs/design.md
```

Expected: mdl prints nothing. Fix the checker's findings where the fix
keeps the meaning. List the rest in the ledger under Task 2, for
`.ste-allow` in Task 14.

- [ ] **Step 3: Commit**

```bash
git add docs/design.md
git commit -m "docs: humanizer pass on the design document"
```

Failure log:

### Task 3: Update the architecture notes for 2.1

**Files:**

- Modify: `docs/architecture.md`

- [ ] **Step 1: Edit**

Change the title to `# Factorio 2.1 mods`. The body has no other mention
of a game version. Add this section after "Determinism":

```markdown
## Tests for these rules

`spec/architecture_spec.lua` enforces two rules on every commit:

- A module in `core/` never names `game`, `storage`, `script` or
  `defines`.
- Neither `core/` nor `control.lua` uses `math.random`.

`spec/docs_spec.lua` checks that this file still names the same game API
as the test.
```

- [ ] **Step 2: Check**

Run: `mdl docs/architecture.md`
Expected: no output.

- [ ] **Step 3: Commit**

```bash
git add docs/architecture.md
git commit -m "docs: update the architecture notes for Factorio 2.1"
```

Failure log:

### Task 4: changelog.py

**Files:**

- Create: `pyproject.toml`, `tools/__init__.py`, `tools/tests/__init__.py`
- Create: `tools/changelog.py`
- Test: `tools/tests/test_changelog.py`

**Interfaces:**

- Produces: `changelog.Release(version: str, date: str | None, groups:
  tuple[tuple[str, tuple[str, ...]], ...])`,
  `changelog.Parsed(releases: tuple[Release, ...], problems: tuple[str,
  ...])`, `changelog.parse(text: str) -> Parsed`,
  `changelog.render(releases, current_version: str) -> str`,
  `changelog.notes(releases, version: str) -> str`,
  `changelog.SEPARATOR` (99 dashes).

- [ ] **Step 1: Create the Python project files**

`pyproject.toml`:

```toml
# The tools in tools/ use the standard library only. pytest runs their
# tests.
[tool.pytest.ini_options]
testpaths = ["tools/tests"]
pythonpath = ["."]
addopts = "-q"
```

`tools/__init__.py` and `tools/tests/__init__.py` are empty files.

- [ ] **Step 2: Write the failing tests**

`tools/tests/test_changelog.py`:

```python
from tools import changelog

SAMPLE = """# Changelog

Intro text.

## [Unreleased]

### Added

- Larvae that explode.
- A long entry that
  goes on to a second line.

### Fixed

- A crash.

## [0.1.0] - 2026-11-12

### Added

- The empty mod.

[Unreleased]: https://example.com
"""


def releases():
    return changelog.parse(SAMPLE).releases


def test_parse_reads_releases_in_order():
    parsed = changelog.parse(SAMPLE)
    assert parsed.problems == ()
    assert [r.version for r in parsed.releases] == ["Unreleased", "0.1.0"]
    assert parsed.releases[1].date == "2026-11-12"
    assert parsed.releases[0].date is None


def test_parse_joins_continuation_lines():
    added = dict(releases()[0].groups)["Added"]
    assert added == ("Larvae that explode.",
                     "A long entry that goes on to a second line.")


def test_parse_reports_an_unknown_heading():
    parsed = changelog.parse("## [Unreleased]\n\n### Improved\n\n- x\n")
    assert any("Improved" in p for p in parsed.problems)


def test_parse_reports_a_bad_release_heading():
    parsed = changelog.parse("## 0.1.0\n")
    assert any("release heading" in p for p in parsed.problems)


def test_parse_never_raises_on_odd_input():
    for text in ["", "###", "### \n- x", "- x", "## [", "  continuation",
                 "## [Unreleased]\n  continuation\n"]:
        changelog.parse(text)


def test_render_maps_headings_to_factorio_categories():
    text = changelog.render(releases(), "0.2.0")
    assert "Version: 0.2.0\n  Features:\n    - Larvae that explode." in text
    assert "  Bugfixes:\n    - A crash." in text


def test_render_starts_every_block_with_99_dashes():
    lines = changelog.render(releases(), "0.2.0").splitlines()
    separators = [line for line in lines if set(line) == {"-"}]
    assert lines[0] == "-" * 99
    assert len(separators) == 2
    assert all(len(line) == 99 for line in separators)


def test_render_dates_released_versions_only():
    text = changelog.render(releases(), "0.2.0")
    assert "Version: 0.1.0\nDate: 2026-11-12\n" in text
    assert "Version: 0.2.0\n  Features" in text


def test_render_skips_an_empty_unreleased_section():
    parsed = changelog.parse(
        "## [Unreleased]\n\n## [0.1.0] - 2026-11-12\n\n### Added\n\n- x\n")
    assert changelog.render(parsed.releases, "0.1.0").count("Version:") == 1


def test_render_skips_unreleased_when_its_version_is_already_released():
    parsed = changelog.parse(
        "## [Unreleased]\n\n### Fixed\n\n- y\n\n"
        "## [0.1.0] - 2026-11-12\n\n### Added\n\n- x\n")
    text = changelog.render(parsed.releases, "0.1.0")
    assert text.count("Version: 0.1.0") == 1


def test_render_of_nothing_is_empty():
    assert changelog.render((), "0.1.0") == ""


def test_notes_give_the_markdown_of_one_version():
    assert changelog.notes(releases(), "0.1.0") == "### Added\n\n- The empty mod.\n"


def test_notes_of_a_missing_version_are_empty():
    assert changelog.notes(releases(), "9.9.9") == ""
```

- [ ] **Step 3: Run the tests to see them fail**

Run: `python3 -m pytest tools/tests/test_changelog.py`
Expected: FAIL, `ImportError: cannot import name 'changelog'`.

- [ ] **Step 4: Write `tools/changelog.py`**

```python
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
```

- [ ] **Step 5: Run the tests to see them pass**

Run: `python3 -m pytest tools/tests/test_changelog.py`
Expected: all pass.

- [ ] **Step 6: Commit**

```bash
git add pyproject.toml tools/__init__.py tools/tests/__init__.py tools/changelog.py tools/tests/test_changelog.py
git commit -m "feat: generate Factorio's changelog.txt from CHANGELOG.md"
```

Failure log:

### Task 5: check_version.py, info.json and CHANGELOG.md

**Files:**

- Create: `tools/check_version.py`, `info.json`, `CHANGELOG.md`
- Test: `tools/tests/test_check_version.py`

**Interfaces:**

- Consumes: `changelog.parse`, `changelog.Release`.
- Produces: `check_version.problems(info_text: str, changelog_text: str,
  tag: str | None) -> list[str]`, `check_version.FACTORIO_VERSION`.

- [ ] **Step 1: Write the failing tests**

`tools/tests/test_check_version.py`:

```python
import json

from tools import check_version as cv

INFO = {
    "name": "abominable-ordnance", "version": "0.1.0",
    "title": "Abominable Ordnance", "author": "vetkat",
    "factorio_version": "2.1", "description": "d",
    "dependencies": ["base >= 2.1", "? space-age"],
}
UNRELEASED = "## [Unreleased]\n\n### Added\n\n- The empty mod.\n"
RELEASED = ("## [Unreleased]\n\n## [0.1.0] - 2026-11-12\n\n"
            "### Added\n\n- The empty mod.\n")


def info(**changes):
    return json.dumps({**INFO, **changes})


def test_unreleased_passes_without_a_tag():
    assert cv.problems(info(), UNRELEASED, None) == []


def test_released_version_passes_with_and_without_its_tag():
    assert cv.problems(info(), RELEASED, None) == []
    assert cv.problems(info(), RELEASED, "v0.1.0") == []


def test_newest_section_must_match_without_a_tag():
    text = "## [0.2.0] - 2026-11-12\n\n### Added\n\n- x\n"
    assert "0.2.0" in cv.problems(info(), text, None)[0]


def test_a_tag_needs_a_dated_section():
    assert cv.problems(info(), UNRELEASED, "v0.1.0")
    undated = "## [0.1.0]\n\n### Added\n\n- x\n"
    assert any("no date" in p for p in cv.problems(info(), undated, "v0.1.0"))


def test_a_tag_must_name_the_info_json_version():
    assert any("v0.2.0" in p for p in cv.problems(info(), RELEASED, "v0.2.0"))


def test_a_tag_fails_while_unreleased_has_entries():
    text = "## [Unreleased]\n\n### Fixed\n\n- y\n\n" + RELEASED.split("\n\n", 1)[1]
    assert any("Unreleased" in p for p in cv.problems(info(), text, "v0.1.0"))


def test_factorio_version_must_be_2_1():
    assert any("2.1" in p for p in cv.problems(info(factorio_version="2.0"), UNRELEASED, None))


def test_dependencies_must_include_base_and_optional_space_age():
    found = cv.problems(info(dependencies=["base >= 2.1"]), UNRELEASED, None)
    assert any("space-age" in p for p in found)


def test_version_must_be_semver():
    assert any("X.Y.Z" in p for p in cv.problems(info(version="0.1"), UNRELEASED, None))


def test_missing_key_is_a_problem():
    data = dict(INFO)
    del data["title"]
    assert any("title" in p for p in cv.problems(json.dumps(data), UNRELEASED, None))


def test_broken_json_is_a_problem_not_an_exception():
    assert "not valid JSON" in cv.problems("{", UNRELEASED, None)[0]
    assert "not a JSON object" in cv.problems("[]", UNRELEASED, None)[0]


def test_empty_changelog_is_a_problem():
    assert cv.problems(info(), "", None) == ["CHANGELOG.md has no release sections"]
```

- [ ] **Step 2: Run the tests to see them fail**

Run: `python3 -m pytest tools/tests/test_check_version.py`
Expected: FAIL, `ImportError`.

- [ ] **Step 3: Write `tools/check_version.py`**

```python
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
```

- [ ] **Step 4: Run the tests to see them pass**

Run: `python3 -m pytest tools/tests/test_check_version.py`
Expected: all pass.

- [ ] **Step 5: Write `info.json` and `CHANGELOG.md`**

`info.json`:

```json
{
  "name": "abominable-ordnance",
  "version": "0.1.0",
  "title": "Abominable Ordnance",
  "author": "vetkat",
  "factorio_version": "2.1",
  "description": "Breed monsters, load them with ordnance and fire them at your enemies.",
  "dependencies": ["base >= 2.1", "? space-age"]
}
```

`CHANGELOG.md`:

```markdown
# Changelog

All notable changes to this mod are in this file. The format follows
[Keep a Changelog 1.0.0](https://keepachangelog.com/en/1.0.0/), and the
mod uses [semantic versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- An empty mod that loads in Factorio 2.1, with and without Space Age.
```

- [ ] **Step 6: Run the real check**

Run: `python3 -m tools.check_version && python3 -m tools.changelog`
Expected: `version check: consistent`, then a block that starts with 99
dashes and `Version: 0.1.0`.

- [ ] **Step 7: Commit**

```bash
git add tools/check_version.py tools/tests/test_check_version.py info.json CHANGELOG.md
git commit -m "feat: check the version in info.json against CHANGELOG.md"
```

Failure log:

### Task 6: package.py

**Files:**

- Create: `tools/package.py`
- Modify: `.gitignore`
- Test: `tools/tests/test_package.py`

**Interfaces:**

- Consumes: `changelog.parse`, `changelog.render`.
- Produces: `package.is_shipped(path: str) -> bool`,
  `package.is_mod_code(path: str) -> bool`,
  `package.missing_required(files: list[str]) -> list[str]`,
  `package.Entry(name, source, text)`, `package.plan(stem, files,
  changelog_txt) -> list[Entry]`, `package.build(root: Path, files:
  list[str], out_dir: Path) -> tuple[Path | None, list[str]]`.

- [ ] **Step 1: Write the failing tests**

`tools/tests/test_package.py`:

```python
import json
import zipfile

from tools import package


def test_shipped_files():
    for path in ["info.json", "LICENSE", "core/a.lua", "locale/en/locale.cfg",
                 "tests/ingame/smoke_test.lua", "data.lua", "control.lua"]:
        assert package.is_shipped(path), path
    for path in ["README.md", "tools/package.py", "spec/a_spec.lua",
                 "core/.gitkeep", "CHANGELOG.md", "tools/vendor/factorio-test_3.2.0.zip"]:
        assert not package.is_shipped(path), path


def test_mod_code_is_shipped_code_without_tests_and_licence():
    assert package.is_mod_code("core/a.lua")
    assert package.is_mod_code("info.json")
    assert not package.is_mod_code("LICENSE")
    assert not package.is_mod_code("tests/ingame/smoke_test.lua")
    assert not package.is_mod_code("README.md")


def test_missing_required():
    assert package.missing_required(["info.json", "LICENSE", "data.lua",
                                     "control.lua", "locale/en/locale.cfg"]) == []
    assert package.missing_required(["info.json"]) == [
        "LICENSE", "data.lua", "control.lua", "locale/"]


def test_plan_adds_the_changelog_and_the_folder_prefix():
    entries = package.plan("m_0.1.0", ["info.json", "README.md"], "text\n")
    assert [e.name for e in entries] == ["m_0.1.0/changelog.txt", "m_0.1.0/info.json"]
    assert entries[0].text == "text\n" and entries[0].source is None


def test_plan_without_changelog_text():
    assert [e.name for e in package.plan("m_0.1.0", ["info.json"], "")] == ["m_0.1.0/info.json"]


def make_tree(root, files):
    for path in files:
        (root / path).parent.mkdir(parents=True, exist_ok=True)
        (root / path).write_text("x\n")
    (root / "info.json").write_text(json.dumps({"name": "m", "version": "0.1.0"}))
    (root / "CHANGELOG.md").write_text("## [Unreleased]\n\n### Added\n\n- x\n")


def test_build_writes_a_zip_with_changelog_txt(tmp_path):
    files = ["info.json", "LICENSE", "data.lua", "control.lua",
             "locale/en/locale.cfg", "README.md", "CHANGELOG.md"]
    make_tree(tmp_path, files)
    out, problems = package.build(tmp_path, files, tmp_path / "build")
    assert problems == []
    names = zipfile.ZipFile(out).namelist()
    assert "m_0.1.0/changelog.txt" in names
    assert "m_0.1.0/README.md" not in names
    text = zipfile.ZipFile(out).read("m_0.1.0/changelog.txt").decode()
    assert text.startswith("-" * 99 + "\nVersion: 0.1.0\n")


def test_build_refuses_a_tree_without_required_files(tmp_path):
    make_tree(tmp_path, ["info.json"])
    out, problems = package.build(tmp_path, ["info.json", "CHANGELOG.md"], tmp_path / "build")
    assert out is None
    assert "missing from the repository: LICENSE" in problems
```

- [ ] **Step 2: Run the tests to see them fail**

Run: `python3 -m pytest tools/tests/test_package.py`
Expected: FAIL, `ImportError`.

- [ ] **Step 3: Write `tools/package.py`**

```python
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
```

- [ ] **Step 4: Run the tests to see them pass**

Run: `python3 -m pytest tools/tests/test_package.py`
Expected: all pass.

- [ ] **Step 5: Extend `.gitignore`**

Replace its content with:

```gitignore
# Old chat logs, for reference only
docs/archive/
# Build output: the zip, coverage data and the in-game test data
build/
changelog.txt
node_modules/
__pycache__/
.pytest_cache/
```

- [ ] **Step 6: Commit**

```bash
git add tools/package.py tools/tests/test_package.py .gitignore
git commit -m "feat: build the mod zip with a generated changelog.txt"
```

Failure log:

### Task 7: pr_checks.py

**Files:**

- Create: `tools/pr_checks.py`
- Test: `tools/tests/test_pr_checks.py`

**Interfaces:**

- Consumes: `package.is_mod_code`.
- Produces: `pr_checks.title_problems(title: str) -> list[str]`,
  `pr_checks.changelog_problems(changed: list[str], labels: list[str]) ->
  list[str]`.

- [ ] **Step 1: Write the failing tests**

`tools/tests/test_pr_checks.py`:

```python
from tools import pr_checks as pr


def test_conventional_titles_pass():
    for title in ["feat: add larvae", "fix(core)!: stop a desync",
                  "ci: bump actions/checkout from 7 to 8", "docs: tidy the README"]:
        assert pr.title_problems(title) == [], title


def test_other_titles_fail():
    for title in ["Add larvae", "feature: add larvae", "feat:add larvae",
                  "feat: ", "FEAT: add larvae", ""]:
        assert pr.title_problems(title), title


def test_long_title_fails():
    assert pr.title_problems("feat: " + "x" * 70)


def test_mod_code_needs_a_changelog_entry():
    assert pr.changelog_problems(["core/a.lua"], [])
    assert pr.changelog_problems(["core/a.lua", "CHANGELOG.md"], []) == []


def test_the_label_skips_the_rule():
    assert pr.changelog_problems(["core/a.lua"], ["no-changelog"]) == []


def test_docs_and_tests_need_no_entry():
    assert pr.changelog_problems(["README.md", "tests/ingame/smoke_test.lua",
                                  "tools/package.py"], []) == []
```

- [ ] **Step 2: Run the tests to see them fail**

Run: `python3 -m pytest tools/tests/test_pr_checks.py`
Expected: FAIL, `ImportError`.

- [ ] **Step 3: Write `tools/pr_checks.py`**

```python
"""Checks that only make sense on a pull request.

1. The PR title is a Conventional Commit. PRs are squash merged, so the
   title becomes the commit message on main.
2. A PR that changes mod code also changes CHANGELOG.md, unless it has the
   label no-changelog.

CI runs this on pull_request events. It reads the event from
GITHUB_EVENT_PATH.
"""
from __future__ import annotations

import json
import os
import pathlib
import re
import subprocess
import sys

from tools import package

TYPES = ("feat", "fix", "docs", "style", "refactor", "perf", "test",
         "build", "ci", "chore", "revert")
TITLE = re.compile(r"^(?P<type>[a-z]+)(?:\([\w./-]+\))?!?: \S")
MAX_TITLE = 72
LABEL = "no-changelog"


def title_problems(title: str) -> list[str]:
    match = TITLE.match(title)
    if not match or match["type"] not in TYPES:
        return [f"PR title {title!r} is not a Conventional Commit, "
                f"for example 'feat: add larvae'. Types: {', '.join(TYPES)}"]
    if len(title) > MAX_TITLE:
        return [f"PR title has {len(title)} characters; the limit is {MAX_TITLE}"]
    return []


def changelog_problems(changed: list[str], labels: list[str]) -> list[str]:
    if LABEL in labels or "CHANGELOG.md" in changed:
        return []
    code = [path for path in changed if package.is_mod_code(path)]
    if not code:
        return []
    return [f"this PR changes mod code ({', '.join(code[:3])}) but not CHANGELOG.md. "
            f"Add an entry under Unreleased, or add the label {LABEL}."]


def main(env: dict[str, str]) -> int:
    event = json.loads(pathlib.Path(env["GITHUB_EVENT_PATH"]).read_text(encoding="utf-8"))
    pull = event["pull_request"]
    labels = [label["name"] for label in pull.get("labels", [])]
    diff = subprocess.run(
        ["git", "diff", "--name-only", f"{pull['base']['sha']}...{pull['head']['sha']}"],
        capture_output=True, text=True, check=True)
    found = title_problems(pull["title"]) + changelog_problems(diff.stdout.splitlines(), labels)
    for problem in found:
        print(f"pr check: {problem}", file=sys.stderr)
    if not found:
        print("pr check: title and changelog are fine")
    return 1 if found else 0


if __name__ == "__main__":
    raise SystemExit(main(dict(os.environ)))
```

- [ ] **Step 4: Run the tests to see them pass**

Run: `python3 -m pytest tools/tests/test_pr_checks.py`
Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add tools/pr_checks.py tools/tests/test_pr_checks.py
git commit -m "feat: check PR titles and the changelog rule"
```

Failure log:

### Task 8: Lua toolchain and the architecture rules

**Files:**

- Create: `.busted`, `.luacheckrc`
- Create: `spec/support/architecture.lua`
- Create: `spec/fixtures/bad_core_api.lua`, `spec/fixtures/bad_random.lua`,
  `spec/fixtures/good_core.lua`
- Test: `spec/architecture_spec.lua`

**Interfaces:**

- Produces (Lua module `spec.support.architecture`): `GAME_API` (list of
  strings), `code_only(src) -> string`, `core_problems(path, src) ->
  list`, `random_problems(path, src) -> list`, `lua_files(dir) -> list`.

`$BUSTED` is the shell variable from Task 0, Step 2. The Makefile
(Task 15) finds busted the same way.

- [ ] **Step 1: Write the settings**

`.busted`:

```lua
return {
  default = {
    ROOT = { "spec" },
    pattern = "_spec%.lua$",
    lpath = "./?.lua;./?/init.lua",
  },
}
```

`.luacheckrc`:

```lua
std = "lua52"
max_line_length = 100
-- .lua, .luarocks and .install hold the Lua that CI installs in the
-- workspace. docs/archive holds old chat logs.
exclude_files = {
  "spec/fixtures/**", "node_modules/**", "build/**", "docs/archive/**",
  ".lua/**", ".luarocks/**", ".install/**",
}

-- Factorio's Lua environment. The game provides these, not Lua.
local factorio = {
  "data", "mods", "settings", "defines", "game", "script", "prototypes",
  "remote", "commands", "rendering", "log", "serpent", "table_size",
  "helpers",
}

-- storage is the mod's saved table, and Factorio adds table.deepcopy.
-- Mods write to both.
local factorio_writable = { "storage", "table" }

local stage = { read_globals = factorio, globals = factorio_writable }
for _, path in ipairs({
  "data.lua", "data-updates.lua", "data-final-fixes.lua", "settings.lua",
  "settings-updates.lua", "settings-final-fixes.lua", "control.lua", "prototypes",
}) do
  files[path] = stage
end

-- core/ gets no Factorio globals. That is the architecture rule.

files["spec"] = { std = "+busted" }
```

- [ ] **Step 2: Write the fixtures**

`spec/fixtures/bad_core_api.lua`:

```lua
local M = {}
function M.tick() return game.tick end
return M
```

`spec/fixtures/bad_random.lua`:

```lua
return math.random(6)
```

`spec/fixtures/good_core.lua`:

```lua
-- The word game in a comment is fine.
local s = "storage in a string is fine"
local t = [[ script in a long string is fine ]]
local M = { gamey = s, t = t }
return M
```

- [ ] **Step 3: Write the failing spec**

`spec/architecture_spec.lua`:

```lua
-- Enforces the rules in docs/architecture.md.

local A = require("spec.support.architecture")

local function read(path)
  local f = assert(io.open(path, "r"), "cannot open " .. path)
  local s = f:read("*a")
  f:close()
  return s
end

local function check(fn, path)
  return fn(path, read(path))
end

describe("the architecture checks", function()
  it("catch a game API name in a core module", function()
    local problems = check(A.core_problems, "spec/fixtures/bad_core_api.lua")
    assert.are.equal(1, #problems)
    assert.truthy(problems[1]:find("game", 1, true))
  end)

  it("catch math.random", function()
    assert.are.equal(1, #check(A.random_problems, "spec/fixtures/bad_random.lua"))
  end)

  it("ignore comments, strings and longer names", function()
    assert.are.same({}, check(A.core_problems, "spec/fixtures/good_core.lua"))
  end)

  it("find Lua files in a folder", function()
    local files = A.lua_files("spec/fixtures")
    assert.are.same({ "spec/fixtures/bad_core_api.lua",
      "spec/fixtures/bad_random.lua", "spec/fixtures/good_core.lua" }, files)
  end)

  it("return an empty list for a missing folder", function()
    assert.are.same({}, A.lua_files("no/such/folder"))
  end)
end)

describe("the repository", function()
  it("keeps the core free of the game API", function()
    for _, path in ipairs(A.lua_files("core")) do
      assert.are.same({}, check(A.core_problems, path))
    end
  end)

  it("never uses math.random in core/ or control.lua", function()
    local paths = A.lua_files("core")
    if io.open("control.lua") then paths[#paths + 1] = "control.lua" end
    for _, path in ipairs(paths) do
      assert.are.same({}, check(A.random_problems, path))
    end
  end)
end)
```

- [ ] **Step 4: Run the spec to see it fail**

Run: `$BUSTED spec/architecture_spec.lua`
Expected: FAIL, `module 'spec.support.architecture' not found`.

- [ ] **Step 5: Write `spec/support/architecture.lua`**

```lua
-- The rules from docs/architecture.md, as pure functions. Each check takes
-- a path and the file's source and returns a list of problems.

local lfs = require("lfs")

local M = {}

-- A core module never names these. docs_spec.lua checks that
-- docs/architecture.md names the same list.
M.GAME_API = { "game", "storage", "script", "defines" }

-- Returns the source without comments and string literals, so that a
-- name in a comment or a string does not count.
function M.code_only(src)
  local out, i, n = {}, 1, #src
  while i <= n do
    local c = src:sub(i, i)
    local long = src:match("^%[(=*)%[", i)
    if src:sub(i, i + 1) == "--" then
      local eq = src:match("^%[(=*)%[", i + 2)
      if eq then
        local close = src:find("]" .. eq .. "]", i, true)
        i = close and close + #eq + 2 or n + 1
      else
        i = src:find("\n", i, true) or n + 1
      end
    elseif c == '"' or c == "'" then
      local j = i + 1
      while j <= n and src:sub(j, j) ~= c do
        if src:sub(j, j) == "\\" then j = j + 1 end
        j = j + 1
      end
      out[#out + 1] = " "
      i = j + 1
    elseif long then
      local close = src:find("]" .. long .. "]", i, true)
      out[#out + 1] = " "
      i = close and close + #long + 2 or n + 1
    else
      out[#out + 1] = c
      i = i + 1
    end
  end
  return table.concat(out)
end

local function names(code, name)
  return code:find("%f[%w_]" .. name .. "%f[^%w_]") ~= nil
end

function M.core_problems(path, src)
  local code, problems = M.code_only(src), {}
  for _, name in ipairs(M.GAME_API) do
    if names(code, name) then
      problems[#problems + 1] = path .. " names " .. name ..
        ", but a core module never touches the game"
    end
  end
  return problems
end

function M.random_problems(path, src)
  if M.code_only(src):find("%f[%w_]math%s*%.%s*random%f[^%w_]") then
    return { path .. " uses math.random, which desyncs multiplayer games" }
  end
  return {}
end

-- Lists the .lua files under dir, sorted. A missing dir gives {}.
function M.lua_files(dir)
  local files = {}
  if lfs.attributes(dir, "mode") ~= "directory" then return files end
  for name in lfs.dir(dir) do
    local path = dir .. "/" .. name
    if name:sub(1, 1) ~= "." then
      if lfs.attributes(path, "mode") == "directory" then
        for _, f in ipairs(M.lua_files(path)) do files[#files + 1] = f end
      elseif name:match("%.lua$") then
        files[#files + 1] = path
      end
    end
  end
  table.sort(files)
  return files
end

return M
```

- [ ] **Step 6: Run the spec and luacheck**

Run: `$BUSTED && luacheck .`
Expected: busted reports 7 successes. luacheck reports 0 warnings.

- [ ] **Step 7: Commit**

```bash
git add .busted .luacheckrc spec/
git commit -m "test: enforce the architecture rules with busted"
```

Failure log:

### Task 9: The empty mod and the locale checks

**Files:**

- Create: `data.lua`, `control.lua`, `locale/en/locale.cfg`, `core/.gitkeep`
- Create: `spec/support/locale.lua`
- Test: `spec/locale_spec.lua`

The Unreleased entry from Task 5 already covers the empty mod.

**Interfaces:**

- Produces (Lua module `spec.support.locale`): `problems(path, text) ->
  list`, `value(text, section, key) -> string | nil`.

- [ ] **Step 1: Write the failing spec**

`spec/locale_spec.lua`:

```lua
-- Checks on the locale files. In the game, all of these failures are
-- silent: a broken value shows as cut-off text, and a broken key shows as
-- the raw key.

local L = require("spec.support.locale")

local function read(path)
  local f = assert(io.open(path, "r"), "cannot open " .. path)
  local s = f:read("*a")
  f:close()
  return s
end

describe("the locale checks", function()
  it("accept sections, keys and comments", function()
    assert.are.same({}, L.problems("x.cfg", "; comment\n[a]\nk=v\n\n# also\n"))
  end)

  it("catch a semicolon in a value", function()
    assert.are.equal(1, #L.problems("x.cfg", "[a]\nk=one; two\n"))
  end)

  it("catch a key outside a section", function()
    assert.are.equal(1, #L.problems("x.cfg", "k=v\n"))
  end)

  it("catch a line that is not key=value", function()
    assert.are.equal(1, #L.problems("x.cfg", "[a]\njust text\n"))
  end)

  it("read a value", function()
    assert.are.equal("v", L.value("[a]\nk=v\n", "a", "k"))
    assert.is_nil(L.value("[a]\nk=v\n", "b", "k"))
  end)
end)

describe("locale/en/locale.cfg", function()
  local text = read("locale/en/locale.cfg")

  it("has no problems", function()
    assert.are.same({}, L.problems("locale/en/locale.cfg", text))
  end)

  it("names the mod with the title from info.json", function()
    local title = read("info.json"):match('"title"%s*:%s*"(.-)"')
    assert.are.equal(title, L.value(text, "mod-name", "abominable-ordnance"))
  end)

  it("describes the mod", function()
    assert.truthy(L.value(text, "mod-description", "abominable-ordnance"))
  end)
end)
```

- [ ] **Step 2: Run it to see it fail**

Run: `$BUSTED spec/locale_spec.lua`
Expected: FAIL, `module 'spec.support.locale' not found`.

- [ ] **Step 3: Write `spec/support/locale.lua`**

```lua
-- Pure checks for Factorio's .cfg locale format.

local M = {}

local function lines(text)
  local out = {}
  for line in (text .. "\n"):gmatch("([^\n]*)\n") do
    out[#out + 1] = (line:gsub("\r$", ""))
  end
  return out
end

function M.problems(path, text)
  local problems, section = {}, nil
  for n, line in ipairs(lines(text)) do
    local where = path .. ":" .. n .. ": "
    if line:match("^%s*$") or line:match("^%s*[;#]") then
      -- a blank line or a comment
    elseif line:match("^%[.+%]%s*$") then
      section = line:match("^%[(.+)%]")
    else
      local key, value = line:match("^([^=]+)=(.*)$")
      if not key then
        problems[#problems + 1] = where .. "not a key=value line"
      elseif not section then
        problems[#problems + 1] = where .. "key outside a [section]"
      elseif value:find(";", 1, true) then
        -- The .cfg format may read ';' as the start of a comment.
        problems[#problems + 1] = where .. "semicolon in a value"
      end
    end
  end
  return problems
end

function M.value(text, wanted_section, wanted_key)
  local section
  for _, line in ipairs(lines(text)) do
    local name = line:match("^%[(.+)%]%s*$")
    if name then
      section = name
    elseif section == wanted_section then
      local key, value = line:match("^([^=]+)=(.*)$")
      if key == wanted_key then return value end
    end
  end
  return nil
end

return M
```

- [ ] **Step 4: Write the mod files**

`locale/en/locale.cfg`:

```ini
[mod-name]
abominable-ordnance=Abominable Ordnance

[mod-description]
abominable-ordnance=Breed monsters, load them with ordnance and fire them at your enemies.
```

`data.lua`:

```lua
-- The data stage. The mod adds no prototypes yet.
```

`control.lua`:

```lua
-- The control stage. This file is the shell: it talks to the game and
-- calls the pure modules in core/. The mod has no features yet.
```

`core/.gitkeep` is an empty file. Git does not track an empty folder.

- [ ] **Step 5: Run the specs and luacheck**

Run: `$BUSTED && luacheck .`
Expected: all specs pass, 0 warnings.

- [ ] **Step 6: Commit**

```bash
git add data.lua control.lua locale/ core/.gitkeep spec/support/locale.lua spec/locale_spec.lua
git commit -m "feat: add the empty mod and the locale checks"
```

Failure log:

### Task 10: The coverage floor

**Files:**

- Create: `.luacov`, `tools/coverage_floor.py`
- Test: `tools/tests/test_coverage_floor.py`

**Interfaces:**

- Produces: `coverage_floor.problems(report: str, floor: float) ->
  list[str]`, `coverage_floor.FLOOR` (90.0).

- [ ] **Step 1: Write the failing tests**

`tools/tests/test_coverage_floor.py`:

```python
from tools import coverage_floor as cf

HEAD = ("=" * 30 + "\nSummary\n" + "=" * 30 + "\n\n"
        "File        Hits Missed Coverage\n" + "-" * 30 + "\n")
TAIL = "-" * 30 + "\nTotal 9 11 45.00%\n"


def report(*rows):
    return HEAD + "".join(row + "\n" for row in rows) + TAIL


def test_core_at_the_floor_passes():
    assert cf.problems(report("core/a.lua 9 1 90.00%", "spec/x.lua 0 10 0.00%"), 90.0) == []


def test_core_below_the_floor_fails():
    found = cf.problems(report("core/a.lua 8 2 80.00%"), 90.0)
    assert found and "80.0%" in found[0]


def test_lines_add_up_across_core_files():
    found = cf.problems(report("core/a.lua 10 0 100.00%", "./core/b.lua 5 5 50.00%"), 90.0)
    assert found and "75.0%" in found[0]


def test_an_empty_core_passes():
    assert cf.problems(report("spec/x.lua 0 10 0.00%"), 90.0) == []


def test_a_report_without_a_summary_is_a_problem():
    assert cf.problems("garbage", 90.0) == [
        "the luacov report has no Summary section; did busted run with --coverage?"]
```

- [ ] **Step 2: Run them to see them fail**

Run: `python3 -m pytest tools/tests/test_coverage_floor.py`
Expected: FAIL, `ImportError`.

- [ ] **Step 3: Write `tools/coverage_floor.py`**

```python
"""Fail when the busted tests cover less than 90% of the lines in core/.

luacov writes a report with a Summary table. This reads the rows for
core/ and adds up their lines. An empty core/ passes.

    python3 -m tools.coverage_floor build/luacov.report.out
"""
from __future__ import annotations

import pathlib
import re
import sys

FLOOR = 90.0
ROW = re.compile(r"^(?P<file>\S+)\s+(?P<hits>\d+)\s+(?P<missed>\d+)\s+[\d.]+%\s*$")


def problems(report: str, floor: float) -> list[str]:
    if "\nSummary\n" not in report:
        return ["the luacov report has no Summary section; did busted run with --coverage?"]
    summary = report.split("\nSummary\n", 1)[1]
    hits = missed = 0
    for line in summary.splitlines():
        match = ROW.match(line)
        if match and match["file"].removeprefix("./").startswith("core/"):
            hits += int(match["hits"])
            missed += int(match["missed"])
    if hits + missed == 0:
        return []
    percent = 100.0 * hits / (hits + missed)
    if percent >= floor:
        return []
    return [f"core/ coverage is {percent:.1f}%, under the floor of {floor:.0f}%"]


def main(argv: list[str]) -> int:
    path = pathlib.Path(argv[1])
    if not path.is_file():
        print(f"coverage: {path} does not exist; did busted run with --coverage?",
              file=sys.stderr)
        return 1
    found = problems(path.read_text(encoding="utf-8"), FLOOR)
    for problem in found:
        print(f"coverage: {problem}", file=sys.stderr)
    return 1 if found else 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
```

- [ ] **Step 4: Run the tests to see them pass**

Run: `python3 -m pytest tools/tests/test_coverage_floor.py`
Expected: all pass.

- [ ] **Step 5: Write `.luacov`**

```lua
-- luacov settings. Coverage counts core/ only, including files that no
-- test loads.
return {
  statsfile = "build/luacov.stats.out",
  reportfile = "build/luacov.report.out",
  include = { "^%.?/?core/" },
  includeuntestedfiles = true,
}
```

- [ ] **Step 6: Run the real chain and check the report format**

```bash
eval "$(luarocks --lua-version 5.2 path)"
mkdir -p build
$BUSTED --coverage && ~/.luarocks/bin/luacov && python3 -m tools.coverage_floor build/luacov.report.out
```

Expected: exit 0. Open `build/luacov.report.out` and check that the
Summary rows look like `ROW`. If the format differs, adapt `ROW` and the
test helper to the real format (that counts as the first attempt).

Then plant a mistake: write `core/planted.lua` with
`local M = {} function M.f() return 1 end return M` and no test. Run the
chain again. Expected: `coverage: core/ coverage is 0.0%`. If it passes,
luacov skipped the untested file: log the attempt, then try
`include = { "core/" }` and run again. If it still passes, hand back.
Delete `core/planted.lua` and `build/`.

- [ ] **Step 7: Commit**

```bash
git add .luacov tools/coverage_floor.py tools/tests/test_coverage_floor.py
git commit -m "feat: enforce a 90% coverage floor on core/"
```

Failure log:

### Task 11: Docs against code

**Files:**

- Test: `spec/docs_spec.lua`
- Modify: `docs/architecture.md` only if Step 2 says so

**Interfaces:**

- Consumes: `spec.support.architecture.GAME_API`.

- [ ] **Step 1: Write the spec**

`spec/docs_spec.lua`:

```lua
-- Checks that the docs still describe the code. A rule list in the docs
-- that differs from the test is wrong, and nobody notices until a reader
-- trusts it.

local A = require("spec.support.architecture")

local function read(path)
  local f = assert(io.open(path, "r"), "cannot open " .. path)
  local s = f:read("*a")
  f:close()
  return s
end

-- The names in backticks in the first paragraph that states the core
-- rule ("never names"). A paragraph ends at a blank line.
local function rule_names(text)
  for paragraph in (text .. "\n\n"):gmatch("(.-)\n%s*\n") do
    if paragraph:find("never names", 1, true) then
      local names = {}
      for name in paragraph:gmatch("`([%w_]+)`") do names[#names + 1] = name end
      return names
    end
  end
  return {}
end

describe("docs/architecture.md", function()
  local text = read("docs/architecture.md")

  it("names the same game API as the architecture test", function()
    local names = rule_names(text)
    table.sort(names)
    local expected = {}
    for _, name in ipairs(A.GAME_API) do expected[#expected + 1] = name end
    table.sort(expected)
    assert.are.same(expected, names)
  end)

  it("still forbids math.random", function()
    assert.truthy(text:find("math.random", 1, true))
  end)
end)

describe("the rule finder", function()
  it("reads the names from the rule paragraph, across a line break", function()
    local text = "x\n\nA module never names `a`\nor `b`.\n\nLater `c`.\n"
    assert.are.same({ "a", "b" }, rule_names(text))
  end)

  it("gives an empty list without a rule line", function()
    assert.are.same({}, rule_names("nothing here"))
  end)
end)
```

- [ ] **Step 2: Run it**

Run: `$BUSTED spec/docs_spec.lua`
Expected: PASS. The first paragraph with "never names" is in "The
core" section of `docs/architecture.md`. It names the four names and no
other name in backticks. If the spec reads another paragraph, move the
rule paragraph so that it comes first.

- [ ] **Step 3: Check that it catches drift**

Temporarily remove `` `defines` `` from that paragraph in
`docs/architecture.md`. Run the spec. Expected: FAIL. Restore the
paragraph.

- [ ] **Step 4: Commit**

```bash
git add spec/docs_spec.lua docs/architecture.md
git commit -m "test: check the architecture notes against the architecture test"
```

Failure log:

### Task 12: prose.py

**Files:**

- Create: `tools/prose.py`
- Test: `tools/tests/test_prose.py`

**Interfaces:**

- Produces: `prose.markdown_prose(text) -> str`, `prose.lua_prose(text)
  -> str`, `prose.locale_prose(text) -> str`. Each returns text with the
  same number of lines as its input, so line numbers carry over.

- [ ] **Step 1: Write the failing tests**

`tools/tests/test_prose.py`:

```python
from tools import prose


def lines(text):
    return text.split("\n")


def test_markdown_keeps_the_line_count():
    text = "a\n```\ncode\n```\nb\n"
    assert len(lines(prose.markdown_prose(text))) == len(lines(text))


def test_markdown_drops_code_blocks_and_spans():
    out = prose.markdown_prose("The `color` key.\n```lua\nlocal color = 1\n```\n")
    assert "color" not in out
    assert "The" in out and "key." in out


def test_markdown_drops_tilde_fences():
    assert "color" not in prose.markdown_prose("~~~\ncolor\n~~~\n")


def test_markdown_drops_link_targets_and_urls():
    out = prose.markdown_prose(
        "See [the docs](https://example.com/colour) and <https://x.org>.\n")
    assert "example" not in out and "x.org" not in out
    assert "the docs" in out


def test_lua_keeps_comments_only():
    out = prose.lua_prose('local color = 1 -- the colour of the larva\n'
                          'print("-- not a comment")\n')
    assert lines(out) == ["the colour of the larva", "", ""]


def test_lua_block_comments_span_lines():
    out = prose.lua_prose("--[[ first line\nsecond line ]] local x = 1\n")
    assert lines(out)[:2] == ["first line", "second line"]


def test_lua_long_strings_are_not_prose():
    out = prose.lua_prose("local s = [[ -- not a comment\nstill a string ]]\n")
    assert out.strip() == ""


def test_lua_doc_comment_dashes_are_dropped():
    assert prose.lua_prose("--- A doc comment.\n") == "A doc comment.\n"


def test_locale_keeps_values_only():
    text = "[mod-name]\nabominable-ordnance=Abominable Ordnance\n; a comment\n"
    assert lines(prose.locale_prose(text)) == ["", "Abominable Ordnance", "", ""]


def test_locale_drops_placeholders_and_rich_text():
    out = prose.locale_prose("[x]\nk=Fires __1__ [item=iron-plate] larvae\n")
    assert "__1__" not in out and "iron-plate" not in out and "larvae" in out
```

- [ ] **Step 2: Run them to see them fail**

Run: `python3 -m pytest tools/tests/test_prose.py`
Expected: FAIL, `ImportError`.

- [ ] **Step 3: Write `tools/prose.py`**

```python
"""Pull the prose out of Markdown, Lua and locale files.

Each function returns text with the same number of lines as its input.
A line without prose becomes an empty line, so a finding in the output
has the line number of the source.
"""
from __future__ import annotations

import re

FENCE = re.compile(r"^\s*(`{3,}|~{3,})")
CODE_SPAN = re.compile(r"`[^`]*`")
LINK_TARGET = re.compile(r"\]\([^)]*\)")
URL = re.compile(r"<https?://[^>]*>|https?://\S+")
LONG_BRACKET = re.compile(r"\[(=*)\[")
PLACEHOLDER = re.compile(r"__\w+__|\[[^\]]*\]")


def markdown_prose(text: str) -> str:
    out = []
    fence = None
    for line in text.split("\n"):
        match = FENCE.match(line)
        if fence:
            if match and match.group(1).startswith(fence):
                fence = None
            out.append("")
        elif match:
            fence = match.group(1)[0] * 3
            out.append("")
        else:
            line = CODE_SPAN.sub(lambda m: " " * len(m.group()), line)
            line = LINK_TARGET.sub("]", line)
            out.append(URL.sub(" ", line))
    return "\n".join(out)


def _lua_line(line: str, block: tuple[str, bool] | None) -> tuple[str, tuple[str, bool] | None]:
    """One line of Lua: its comment text, and the open block after it.

    block is (closing bracket, is a comment) for a block comment or a long
    string that is still open.
    """
    parts = []
    i = 0
    while i < len(line):
        if block:
            close, is_comment = block
            j = line.find(close, i)
            if is_comment:
                parts.append(line[i:] if j < 0 else line[i:j])
            if j < 0:
                break
            i = j + len(close)
            block = None
            continue
        if line.startswith("--", i):
            match = LONG_BRACKET.match(line, i + 2)
            if match:
                block = ("]" + match.group(1) + "]", True)
                i = match.end()
                continue
            parts.append(line[i + 2:].lstrip("-"))
            break
        if line[i] in "\"'":
            quote = line[i]
            j = i + 1
            while j < len(line) and line[j] != quote:
                j += 2 if line[j] == "\\" else 1
            i = j + 1
            continue
        match = LONG_BRACKET.match(line, i)
        if match:
            block = ("]" + match.group(1) + "]", False)
            i = match.end()
            continue
        i += 1
    return " ".join(p.strip() for p in parts if p.strip()), block


def lua_prose(text: str) -> str:
    out = []
    block = None
    for line in text.split("\n"):
        prose_line, block = _lua_line(line, block)
        out.append(prose_line)
    return "\n".join(out)


def locale_prose(text: str) -> str:
    out = []
    for line in text.split("\n"):
        stripped = line.strip()
        if not stripped or stripped[0] in "[;#" or "=" not in line:
            out.append("")
        else:
            out.append(PLACEHOLDER.sub(" ", line.split("=", 1)[1]).strip())
    return "\n".join(out)
```

- [ ] **Step 4: Run the tests to see them pass**

Run: `python3 -m pytest tools/tests/test_prose.py`
Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add tools/prose.py tools/tests/test_prose.py
git commit -m "feat: extract prose from Markdown, Lua and locale files"
```

Failure log:

### Task 13: The text check core

**Files:**

- Create: `tools/vendor/__init__.py` (empty), `tools/vendor/ste_check.py`
- Create: `tools/text_check.py`, `THIRD_PARTY.md`
- Commit: `tools/vendor/factorio-test_3.2.0.zip` (on disk since 2026-11-12,
  not yet committed; Task 18 needs it in CI)
- Test: `tools/tests/test_text_check.py`

**Interfaces:**

- Consumes: `prose.markdown_prose`, `prose.lua_prose`,
  `prose.locale_prose`, `ste_check.check(text: str, strict: bool) ->
  list[Finding]` (vendored; findings have `line`, `rule`, `message`,
  `excerpt`).
- Produces: `text_check.Finding(path, line, rule, message, excerpt)`,
  `text_check.Allow(rule, path, word, reason)`, `text_check.kind(path)`,
  `text_check.prose_of(path, text)`, `text_check.check_files(texts:
  dict[str, str]) -> list[Finding]`, `text_check.parse_allow(text) ->
  tuple[list[Allow], list[str]]`, `text_check.allowed(finding, allows) ->
  bool`, `text_check.spelling_findings(output: str) -> list[Finding]`.

- [ ] **Step 1: Vendor the checker**

```bash
cp ~/.agents/skills/ste80-humanizer/scripts/ste_check.py tools/vendor/ste_check.py
git hash-object tools/vendor/ste_check.py
```

Expected hash: `1ddf0440ab561f71db06692f04b1429bfa0ae165`. That is the
blob of `scripts/ste_check.py` at upstream commit
`6a69c447a3eb24c7d403aea5fc04f965ad6dafcc`. Do not edit the copy. On a
mismatch, take the upstream file instead:

```bash
curl -fsSL -o tools/vendor/ste_check.py \
  https://raw.githubusercontent.com/Dodaios/ste80-humanizer/6a69c447a3eb24c7d403aea5fc04f965ad6dafcc/scripts/ste_check.py
```

`THIRD_PARTY.md`:

```markdown
# Third-party code

## ste80-humanizer checker

- File: `tools/vendor/ste_check.py`, unchanged
- Source: <https://github.com/Dodaios/ste80-humanizer>, file
  `scripts/ste_check.py` at commit
  `6a69c447a3eb24c7d403aea5fc04f965ad6dafcc`
- Licence: MIT, copyright (c) 2026 Dodaios
- Use: the text check (`tools/text_check.py`). It does not ship in the
  mod.

## factorio-test

- File: `tools/vendor/factorio-test_3.2.0.zip`, unchanged
- Source: <https://mods.factorio.com/mod/factorio-test> by GlassBricks
  (<https://github.com/GlassBricks/FactorioTest>)
- Licence: MIT
- Use: the in-game tests (`make ingame`). It does not ship in the mod.
```

- [ ] **Step 2: Write the failing tests**

`tools/tests/test_text_check.py`:

```python
from tools import text_check as tc


def rules(found):
    return [f.rule for f in found]


def test_style_findings_come_from_the_vendored_checker():
    found = tc.check_files({"docs/x.md": "We utilize this tool.\n"})
    assert "word" in rules(found)
    assert all(f.path == "docs/x.md" and f.line == 1 for f in found)


def test_code_in_markdown_is_not_checked():
    text = "```\nwe utilize – code\n```\n\nUse `utilize` here.\n"
    assert tc.check_files({"docs/x.md": text}) == []


def test_en_dash_in_prose_fails():
    found = tc.check_files({"docs/x.md": "Read pages 1–3 first.\n"})
    assert "en-dash" in rules(found)


def test_lua_comments_are_checked_and_code_is_not():
    assert tc.check_files({"core/x.lua": "local utilize = 1\n"}) == []
    found = tc.check_files({"core/x.lua": "local x = 1\n-- we utilize this\n"})
    assert [f.line for f in found if f.rule == "word"] == [2]


def test_other_files_are_skipped():
    assert tc.kind("tools/x.py") is None
    assert tc.kind("tools/vendor/notes.md") is None
    assert tc.kind("locale/en/locale.cfg") == "locale"
    assert tc.check_files({"tools/x.py": "# we utilize this\n"}) == []


def test_parse_allow_reads_entries_and_comments():
    allows, problems = tc.parse_allow(
        "# a comment\n\nspelling | docs/reviews/*.md | color | quotes the old spec\n")
    assert problems == []
    assert allows == [tc.Allow("spelling", "docs/reviews/*.md", "color", "quotes the old spec")]


def test_parse_allow_rejects_bad_entries():
    for line in ["spelling | a.md | color", "* | a.md | | reason",
                 "spelling | | | reason", "spelling | a.md | |"]:
        allows, problems = tc.parse_allow(line + "\n")
        assert allows == [] and len(problems) == 1, line


def test_allowed_matches_rule_path_and_word():
    allows, _ = tc.parse_allow("spelling | docs/reviews/*.md | color | quotes\n")
    finding = tc.Finding("docs/reviews/a.md", 3, "spelling", "", "color")
    assert tc.allowed(finding, allows)
    assert not tc.allowed(finding._replace(excerpt="behavior"), allows)
    assert not tc.allowed(finding._replace(path="README.md"), allows)
    assert not tc.allowed(finding._replace(rule="word"), allows)


def test_an_entry_without_a_word_covers_the_rule_in_that_file():
    allows, _ = tc.parse_allow("passive | docs/design.md | | the design's voice\n")
    assert tc.allowed(tc.Finding("docs/design.md", 9, "passive", "", "is made"), allows)


def test_spelling_findings_parse_cspell_output():
    out = ("docs/x.md.txt:4:5 - Unknown word (color)\n"
           "./core/y.lua.txt:2:1 - Unknown word (behavior)\n"
           "CSpell: Files checked: 2\n")
    assert tc.spelling_findings(out) == [
        tc.Finding("docs/x.md", 4, "spelling", "not in the en-GB dictionary", "color"),
        tc.Finding("core/y.lua", 2, "spelling", "not in the en-GB dictionary", "behavior"),
    ]
```

- [ ] **Step 3: Run them to see them fail**

Run: `python3 -m pytest tools/tests/test_text_check.py`
Expected: FAIL, `ImportError`.

- [ ] **Step 4: Write the core of `tools/text_check.py`**

```python
"""Check the prose in Markdown files, Lua comments and locale files.

The rules: the findings of the vendored humanizer checker, no en dash
(the checker only flags em dashes), and cspell with the en-GB dictionary.
.ste-allow lists accepted exceptions. Each entry names a rule, a file
pattern, an optional word and a reason:

    spelling | docs/superpowers/reviews/*.md | color | quotes the old spec

    python3 -m tools.text_check            # every tracked file
    python3 -m tools.text_check FILE ...   # only these files
"""
from __future__ import annotations

import fnmatch
import pathlib
import re
import subprocess
import sys
import tempfile
from typing import NamedTuple

from tools import prose
from tools.vendor import ste_check

ROOT = pathlib.Path(__file__).resolve().parents[1]
EN_DASH = "–"
# Copied code keeps its upstream text.
SKIP = ("tools/vendor/",)
EXTRACT = {
    "markdown": prose.markdown_prose,
    "lua": prose.lua_prose,
    "locale": prose.locale_prose,
}
CSPELL = re.compile(r"^(?P<file>.+?):(?P<line>\d+):\d+ - Unknown word \((?P<word>[^)]+)\)")


class Finding(NamedTuple):
    path: str
    line: int
    rule: str
    message: str
    excerpt: str


class Allow(NamedTuple):
    rule: str
    path: str  # an fnmatch pattern
    word: str  # empty: any finding of this rule in these files
    reason: str


def kind(path: str) -> str | None:
    if path.startswith(SKIP):
        return None
    if path.endswith(".md"):
        return "markdown"
    if path.endswith(".lua"):
        return "lua"
    if path.startswith("locale/") and path.endswith(".cfg"):
        return "locale"
    return None


def prose_of(path: str, text: str) -> str:
    found = kind(path)
    return EXTRACT[found](text) if found else ""


def _style(path: str, text: str) -> list[Finding]:
    # The checker skips Markdown code itself, so it gets the raw Markdown.
    source = text if kind(path) == "markdown" else prose_of(path, text)
    return [Finding(path, f.line, f.rule, f.message, f.excerpt)
            for f in ste_check.check(source, False)]


def _dashes(path: str, prose_text: str) -> list[Finding]:
    return [Finding(path, no, "en-dash", "en dash: use 'to', a hyphen or a comma",
                    line.strip()[:100])
            for no, line in enumerate(prose_text.split("\n"), 1) if EN_DASH in line]


def check_files(texts: dict[str, str]) -> list[Finding]:
    found: list[Finding] = []
    for path in sorted(texts):
        if kind(path) is None:
            continue
        found += _style(path, texts[path]) + _dashes(path, prose_of(path, texts[path]))
    return found


def parse_allow(text: str) -> tuple[list[Allow], list[str]]:
    allows, problems = [], []
    for no, line in enumerate(text.splitlines(), 1):
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        fields = [field.strip() for field in line.split("|")]
        if len(fields) != 4:
            problems.append(f".ste-allow line {no}: use 'rule | path | word | reason'")
            continue
        rule, path, word, reason = fields
        if not rule or rule == "*" or not path or not reason:
            problems.append(f".ste-allow line {no}: an entry needs a rule (not *), "
                            "a path and a reason")
            continue
        allows.append(Allow(rule, path, word, reason))
    return allows, problems


def allowed(finding: Finding, allows: list[Allow]) -> bool:
    return any(a.rule == finding.rule
               and fnmatch.fnmatchcase(finding.path, a.path)
               and (not a.word or a.word.lower() in finding.excerpt.lower())
               for a in allows)


def spelling_findings(output: str) -> list[Finding]:
    """Read cspell's output. The prose copies are named <path>.txt."""
    found = []
    for line in output.splitlines():
        match = CSPELL.match(line.strip())
        if match:
            path = match["file"].removeprefix("./").removesuffix(".txt")
            found.append(Finding(path, int(match["line"]), "spelling",
                                 "not in the en-GB dictionary", match["word"]))
    return found
```

- [ ] **Step 5: Run the tests to see them pass**

Run: `python3 -m pytest tools/tests/test_text_check.py`
Expected: all pass. If `test_style_findings_come_from_the_vendored_checker`
fails, run `printf 'We utilize this tool.\n' | python3 -I
tools/vendor/ste_check.py -` and use the rule name that it prints.

- [ ] **Step 6: Commit**

```bash
git add tools/vendor/__init__.py tools/vendor/ste_check.py tools/vendor/factorio-test_3.2.0.zip tools/text_check.py tools/tests/test_text_check.py THIRD_PARTY.md
git commit -m "feat: add the text check rules and the .ste-allow format"
```

Failure log:

### Task 14: The text check shell and cspell

**Files:**

- Create: `package.json`, `package-lock.json`, `cspell.json`, `.ste-allow`
- Modify: `tools/text_check.py` (add the shell)
- Modify: any Markdown, Lua or locale file with findings
- Test: `tools/tests/test_gates.py` (created here, extended in Task 15)

**Interfaces:**

- Produces: `text_check.spelling(root: Path, prose_by_path: dict[str,
  str]) -> list[Finding]`, `text_check.main(argv) -> int`.

- [ ] **Step 1: Write `package.json` and install**

```json
{
  "name": "abominable-ordnance-dev",
  "private": true,
  "description": "Development tools for the Abominable Ordnance mod. The mod has no npm dependencies.",
  "devDependencies": {
    "@cspell/dict-en-gb-mit": "3.1.32",
    "cspell": "10.4.1",
    "factorio-test-cli": "3.9.0"
  }
}
```

Run: `npm install`
Expected: `node_modules/` and `package-lock.json`.

- [ ] **Step 2: Write `cspell.json`**

```json
{
  "version": "0.2",
  "language": "en-GB",
  "import": ["@cspell/dict-en-gb-mit/cspell-ext.json"],
  "words": []
}
```

- [ ] **Step 3: Write the failing gate test**

`tools/tests/test_gates.py`:

```python
"""Each third-party gate fails on a planted mistake.

These tests run the real tools with this repository's settings. A test
skips when its tool is not installed, so CI's tools job skips most of
them. CI runs the gates themselves in the text and lua jobs.
"""
import pathlib
import shutil
import subprocess

import pytest

ROOT = pathlib.Path(__file__).resolve().parents[2]


def need(tool):
    return pytest.mark.skipif(shutil.which(tool) is None, reason=f"{tool} is not installed")


needs_cspell = pytest.mark.skipif(
    not (ROOT / "node_modules/.bin/cspell").exists(), reason="run npm ci first")


@needs_cspell
def test_cspell_flags_an_american_spelling():
    from tools import text_check
    found = text_check.spelling(ROOT, {"bad.md": "The color is red.\n"})
    assert [(f.path, f.line, f.excerpt) for f in found] == [("bad.md", 1, "color")]


@needs_cspell
def test_cspell_accepts_the_british_spelling():
    from tools import text_check
    assert text_check.spelling(ROOT, {"good.md": "The colour is red.\n"}) == []
```

- [ ] **Step 4: Run it to see it fail**

Run: `python3 -m pytest tools/tests/test_gates.py`
Expected: FAIL, `AttributeError: module 'tools.text_check' has no
attribute 'spelling'`.

- [ ] **Step 5: Add the shell to `tools/text_check.py`**

Append:

```python
def spelling(root: pathlib.Path, prose_by_path: dict[str, str]) -> list[Finding]:
    """Run cspell once over copies of the prose, named <path>.txt."""
    names = []
    with tempfile.TemporaryDirectory() as tmp:
        for path, text in prose_by_path.items():
            target = pathlib.Path(tmp, path + ".txt")
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(text, encoding="utf-8")
            names.append(path + ".txt")
        if not names:
            return []
        result = subprocess.run(
            [str(root / "node_modules/.bin/cspell"), "--no-progress", "--no-summary",
             "--no-color", "--dot", "--config", str(root / "cspell.json"), *names],
            cwd=tmp, capture_output=True, text=True)
    if result.returncode not in (0, 1):
        raise SystemExit(f"text check: cspell failed:\n{result.stdout}{result.stderr}")
    return spelling_findings(result.stdout)


def tracked(root: pathlib.Path) -> list[str]:
    result = subprocess.run(["git", "ls-files", "-z"], cwd=root,
                            capture_output=True, text=True, check=True)
    return [p for p in result.stdout.split("\0") if p and (root / p).is_file()]


def relative(path: str) -> str:
    return pathlib.Path(path).resolve().relative_to(ROOT).as_posix()


def main(argv: list[str]) -> int:
    paths = [relative(p) for p in argv[1:]] or tracked(ROOT)
    texts = {p: (ROOT / p).read_text(encoding="utf-8") for p in paths if kind(p)}
    allow_file = ROOT / ".ste-allow"
    allow_text = allow_file.read_text(encoding="utf-8") if allow_file.exists() else ""
    allows, problems = parse_allow(allow_text)
    findings = check_files(texts) + spelling(
        ROOT, {p: prose_of(p, t) for p, t in texts.items()})
    left = sorted(f for f in findings if not allowed(f, allows))
    for problem in problems:
        print(f"text check: {problem}", file=sys.stderr)
    for f in left:
        print(f"{f.path}:{f.line}: {f.rule}: {f.message} ({f.excerpt})")
    if left:
        print(f"text check: {len(left)} finding(s). Fix the text, or add an entry "
              "with a reason to .ste-allow.", file=sys.stderr)
    return 1 if left or problems else 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
```

- [ ] **Step 6: Run the gate tests**

Run: `python3 -m pytest tools/tests/test_gates.py`
Expected: PASS. If `color` is not flagged, cspell still loads the US
dictionary: run `npx cspell trace color --config cspell.json` and change
`cspell.json` until only the en-GB dictionary knows English words (for
example add `"dictionaries": ["en-gb-mit"]` or set
`"languageSettings"`). If the output format differs from `CSPELL`, adapt
the pattern and its test. Each change is one attempt for the failure log.

- [ ] **Step 7: Run the text check on the repository**

Run: `python3 -m tools.text_check`
Then work through the findings:

1. Real project words that cspell does not know (Factorio, luacheck,
   busted, biter, pentapod and so on) go in `cspell.json` `words`.
2. A finding in this project's own prose (the spec, the plan,
   `docs/design.md`, `docs/architecture.md`, `CHANGELOG.md`, Lua
   comments) gets fixed in place, with `/ste80-humanizer`, when the fix
   keeps the meaning.
3. A finding that a fix cannot remove gets a `.ste-allow` entry with the
   reason. Examples: an "-ing" word that is a name ("Breeding" branch,
   "heating towers"; see the ledger notes from Task 2), and text that
   quotes others (the review reports quote reviewers and the old spec).

Start `.ste-allow` with this header:

```text
# Accepted text-check findings. One entry per line:
#   rule | file pattern | word (optional) | reason
# The rule is required and cannot be *. tools/text_check.py has the rules.
```

Run `python3 -m tools.text_check` again until it exits 0.

- [ ] **Step 8: Run all tests**

Run: `python3 -m pytest && mdl $(git ls-files '*.md')`
Expected: all pass, no mdl output.

- [ ] **Step 9: Commit**

```bash
git add package.json package-lock.json cspell.json .ste-allow tools/text_check.py tools/tests/test_gates.py
git add -u
git commit -m "feat: run the text check with cspell over the repository"
```

Failure log:

### Task 15: Makefile, git hook and lychee

**Files:**

- Create: `Makefile`, `.githooks/pre-commit`, `lychee.toml`
- Modify: `tools/tests/test_gates.py`

- [ ] **Step 1: Add the planted-mistake tests for mdl, luacheck and lychee**

Append to `tools/tests/test_gates.py`:

```python
def run(args, cwd=ROOT):
    return subprocess.run(args, cwd=cwd, capture_output=True, text=True)


@need("mdl")
def test_mdl_fails_on_a_heading_without_a_space(tmp_path):
    bad = tmp_path / "bad.md"
    bad.write_text("#Heading\n")
    result = run(["mdl", str(bad)])
    assert result.returncode != 0 and "MD018" in result.stdout


@need("luacheck")
def test_luacheck_fails_on_a_new_global(tmp_path):
    bad = tmp_path / "bad.lua"
    bad.write_text("larvae = 1\n")
    result = run(["luacheck", "--config", str(ROOT / ".luacheckrc"), str(bad)])
    assert result.returncode != 0


@need("lychee")
def test_lychee_fails_on_a_missing_local_file(tmp_path):
    bad = tmp_path / "bad.md"
    bad.write_text("[gone](missing.md)\n")
    result = run(["lychee", "--offline", "--no-progress", str(bad)])
    assert result.returncode != 0


@need("lychee")
def test_lychee_passes_a_good_local_link(tmp_path):
    (tmp_path / "there.md").write_text("# There\n")
    good = tmp_path / "good.md"
    good.write_text("[there](there.md)\n")
    assert run(["lychee", "--offline", "--no-progress", str(good)]).returncode == 0
```

Run: `python3 -m pytest tools/tests/test_gates.py`
Expected: all pass (these test the tools' settings, so they pass at once).
Check the planted test is real: change `bad.write_text("#Heading\n")` to
`"# Heading\n"` and see the mdl test fail. Change it back.

- [ ] **Step 2: Write `lychee.toml`**

```toml
# lychee settings. `make text` checks the links inside the repository
# (--offline). weekly.yml checks every link, external ones included.
exclude_path = ["node_modules", "build", "docs/archive"]
```

- [ ] **Step 3: Write the `Makefile`**

```make
# Each CI job calls one of these targets, so a check works the same way
# on the maintainer's machine and in CI. The spec is
# docs/superpowers/specs/2026-11-12-repo-and-ci-design.md.

# On Arch, lua52-busted installs busted outside PATH. Use a busted on PATH
# if there is one (CI). If not, use the Arch rock path.
LUA         := lua5.2
ARCH_BUSTED := $(lastword $(wildcard /usr/lib/luarocks/rocks-5.2/busted/*/bin/busted))
BUSTED      := $(shell command -v busted 2>/dev/null)
ifeq ($(BUSTED),)
  RUN_BUSTED := $(LUA) $(ARCH_BUSTED) --lua=$(LUA)
else
  RUN_BUSTED := $(BUSTED)
endif

# Lua modules that luarocks installed for this user, such as luacov. The
# _5_2 names reach Lua 5.2 only. Arch's luacheck runs on Lua 5.4 and must
# not load 5.2 modules.
ifneq ($(shell command -v luarocks 2>/dev/null),)
  export LUA_PATH_5_2  := $(shell luarocks --lua-version 5.2 path --lr-path);;
  export LUA_CPATH_5_2 := $(shell luarocks --lua-version 5.2 path --lr-cpath);;
  export PATH          := $(HOME)/.luarocks/bin:$(PATH)
endif

# The git hook may pass the staged files in FILES (see Task 15, Step 5).
# Without FILES, the text checks cover every tracked file, as in CI.
MARKDOWN   = $(if $(FILES),$(filter %.md,$(FILES)),$(shell git ls-files '*.md'))
TEXT_FILES = $(if $(FILES),$(filter %.md %.lua locale/%.cfg,$(FILES)),)

.PHONY: setup fast check text lua tools ingame stamp package

## once, after a clone: turn on the git hook
setup:
	git config core.hooksPath .githooks

## every commit (the git hook)
fast: text lua tools

## before a PR
check: fast ingame

text:
	$(if $(MARKDOWN),mdl $(MARKDOWN))
	python3 -m tools.text_check $(TEXT_FILES)
	$(if $(MARKDOWN),lychee --offline --no-progress $(MARKDOWN))

lua:
	mkdir -p build
	luacheck .
	$(RUN_BUSTED) --coverage
	luacov
	python3 -m tools.coverage_floor build/luacov.report.out

tools:
	python3 -m pytest
	python3 -m tools.check_version

## MODE=base or MODE=space-age runs one mode; empty runs both
ingame:
	tools/ingame.sh $(MODE)

## after /ste80-humanizer and /simplify: lets the Claude Code hook pass
stamp:
	python3 -m tools.review_stamp stamp

package:
	python3 -m tools.package
```

`tools/review_stamp.py` arrives in Task 16 and `tools/ingame.sh` in
Task 18. `make stamp` and `make ingame` fail until then.

- [ ] **Step 4: Write `.githooks/pre-commit`**

```sh
#!/bin/sh
# Every commit runs the fast gates. CI runs them again on every PR.
exec make fast
```

Run: `chmod +x .githooks/pre-commit`

- [ ] **Step 5: Run the gates and measure them**

Run: `time make fast`
Expected: exit 0. Write the time in the ledger under Task 15.

If it is over 10 seconds, the spec says that the git hook checks the
staged files only. Then replace the last line of `.githooks/pre-commit`
with:

```sh
exec make fast FILES="$(git diff --cached --name-only --diff-filter=ACMR | tr '\n' ' ')"
```

With staged files that hold no text, `make text` checks every file, which
is slower but still correct. luacheck, busted and pytest always run in
full. CI calls `make text` without `FILES` and checks every file.

- [ ] **Step 6: Turn on the hook and commit through it**

```bash
make setup
git add Makefile .githooks/pre-commit lychee.toml tools/tests/test_gates.py
git commit -m "build: add the Make targets and the git pre-commit hook"
```

Expected: the hook runs `make fast`, and the commit succeeds.

Failure log:

### Task 16: The Claude Code hook

**Files:**

- Create: `tools/review_stamp.py`, `.claude/settings.json`
- Test: `tools/tests/test_review_stamp.py`

**Interfaces:**

- Produces: `review_stamp.is_commit(command: str) -> bool`,
  `review_stamp.commit_stages_files(command: str) -> bool`,
  `review_stamp.decide(command: str, hooks_path: str | None, tree: str |
  None, stamp: str | None) -> tuple[int, str]`.

- [ ] **Step 1: Write the failing tests**

`tools/tests/test_review_stamp.py`:

```python
from tools import review_stamp as rs

GOOD = (".githooks", "tree1", "tree1")
HEREDOC = "git commit -q -F - <<'EOF'\nfeat: don't stop\n\nmore text\nEOF"


def test_commits_are_recognised():
    for command in ["git commit -m x", "cd repo && git commit -m x",
                    "git -C /repo commit -m x", "git --no-pager commit",
                    "make fast; git commit --amend --no-edit",
                    "make fast\ngit commit -m x", HEREDOC]:
        assert rs.is_commit(command), command


def test_other_commands_are_not_commits():
    for command in ["git status", "git log --grep commit", 'echo "git commit"',
                    "make fast", "git commit-tree abc"]:
        assert not rs.is_commit(command), command


def test_non_commit_passes_whatever_the_state():
    assert rs.decide("git status", None, None, None) == (0, "")


def test_commit_with_a_current_stamp_passes():
    for command in ["git commit -m x", "git commit -qm x", "git commit -mfoo",
                    'git commit -m "docs: explain git add"', HEREDOC,
                    "git commit --amend --no-edit", "git commit --message=x"]:
        assert rs.decide(command, *GOOD) == (0, ""), command


def test_commit_without_the_git_hook_is_blocked():
    code, message = rs.decide("git commit -m x", None, "tree1", "tree1")
    assert code == 2 and "make setup" in message


def test_commit_without_a_stamp_is_blocked():
    code, message = rs.decide("git commit -m x", ".githooks", "tree1", None)
    assert code == 2
    for step in ["/ste80-humanizer", "/simplify", "ROADMAP.md", "make stamp"]:
        assert step in message


def test_commit_with_an_old_stamp_is_blocked():
    assert rs.decide("git commit -m x", ".githooks", "tree2", "tree1")[0] == 2


def test_staging_in_the_same_command_is_blocked():
    for command in ["git add . && git commit -m x", "git add -A\ngit commit -m x",
                    "git commit -am x", "git commit -a -m x", "git commit --all -m x",
                    "git commit -m x path/to/file", "git commit -i -m x f",
                    "git commit -o f -m x", "git commit --only f", "git commit -p"]:
        code, message = rs.decide(command, *GOOD)
        assert code == 2 and "separate command" in message, command


def test_unreadable_quotes_are_blocked():
    assert rs.decide('git commit -m "x', *GOOD)[0] == 2
```

- [ ] **Step 2: Run them to see them fail**

Run: `python3 -m pytest tools/tests/test_review_stamp.py`
Expected: FAIL, `ImportError`.

- [ ] **Step 3: Write `tools/review_stamp.py`**

```python
"""Block an agent commit until the review skills have run.

A hook cannot run a skill, but it can refuse the commit until the agent
has run them. `make stamp` saves the hash of the staged tree. The Claude
Code hook compares that hash with the staged tree before `git commit`.

    python3 -m tools.review_stamp stamp   # make stamp
    python3 -m tools.review_stamp         # the hook: reads its JSON on stdin
"""
from __future__ import annotations

import json
import pathlib
import re
import shlex
import subprocess
import sys
from typing import TextIO

# A git subcommand at the start of a command line, or after ; & | ( or a
# shell keyword, with git's own options before it.
_GIT = (r"(?:^|[;&|(]|\bthen\b|\bdo\b)[ \t]*git\s+"
        r"(?:(?:-C|-c)\s+\S+\s+|--?[\w-]+(?:=\S+)?\s+)*")
COMMIT = re.compile(_GIT + r"commit(?![\w-])", re.MULTILINE)
STAGE_COMMAND = re.compile(_GIT + r"(?:add|rm|mv|stage)(?![\w-])", re.MULTILINE)

# Options of git commit that stage files at commit time.
STAGING_OPTIONS = {"-a", "--all", "-i", "--include", "-o", "--only", "-p",
                   "--patch", "--interactive"}
STAGING_LETTERS = set("aiop")
# Options whose value is the next argument.
VALUE_OPTIONS = {"-m", "-F", "-C", "-c", "-t", "--message", "--file", "--author",
                 "--date", "--template", "--cleanup", "--fixup", "--squash",
                 "--reuse-message", "--reedit-message", "--trailer"}
VALUE_LETTERS = set("mFCct")
SHELL_PUNCTUATION = set(";&|<>()")

REVIEW_STEPS = """The staged files have no review stamp. Before you commit:
1. Run /ste80-humanizer (British English) on staged prose and comments.
2. Run /simplify on staged code.
3. Update ROADMAP.md if the change affects it.
4. Stage the results, then run `make stamp`.
Then commit again, in a command of its own."""


def is_commit(command: str) -> bool:
    return COMMIT.search(command) is not None


def _short_option_stages(token: str, tokens) -> bool:
    """Reads a cluster such as -qm. Consumes a separate value if needed."""
    letters = token[1:]
    for index, letter in enumerate(letters):
        if letter in STAGING_LETTERS:
            return True
        if letter in VALUE_LETTERS:
            if index == len(letters) - 1:
                next(tokens, None)
            return False
    return False


def commit_stages_files(command: str) -> bool:
    """True when git commit itself stages files: -a, -i, -o, -p or a path."""
    match = COMMIT.search(command)
    if match is None:
        return False
    lexer = shlex.shlex(command[match.end():], posix=True, punctuation_chars=True)
    lexer.whitespace_split = True
    tokens = iter(lexer)
    try:
        for token in tokens:
            if set(token) <= SHELL_PUNCTUATION:
                return False  # the commit command ends here
            if token in STAGING_OPTIONS:
                return True
            if token in VALUE_OPTIONS:
                next(tokens, None)
            elif token.startswith("--"):
                continue
            elif token.startswith("-") and len(token) > 1:
                if _short_option_stages(token, tokens):
                    return True
            else:
                return True  # a path
    except ValueError:
        return True  # unbalanced quotes: the hook cannot tell, so it refuses
    return False


def decide(command: str, hooks_path: str | None, tree: str | None,
           stamp: str | None) -> tuple[int, str]:
    """Exit code 2 blocks the command. The message goes to the agent."""
    if not is_commit(command):
        return 0, ""
    if hooks_path != ".githooks":
        return 2, "The git hook is not active. Run `make setup`, then commit again."
    if STAGE_COMMAND.search(command) or commit_stages_files(command):
        return 2, ("Stage files in a separate command (git add), then run `make stamp`, "
                   "then commit. The hook checks what is staged before the command runs, "
                   "so it refuses -a, -i, -o, -p and paths after git commit.")
    if tree is None or stamp != tree:
        return 2, REVIEW_STEPS
    return 0, ""


def git(*args: str) -> str | None:
    result = subprocess.run(["git", *args], capture_output=True, text=True)
    return result.stdout.strip() if result.returncode == 0 else None


def stamp_file() -> pathlib.Path | None:
    path = git("rev-parse", "--git-path", "review-stamp")
    return pathlib.Path(path) if path else None


def main(argv: list[str], stdin: TextIO) -> int:
    if argv[1:] == ["stamp"]:
        tree, path = git("write-tree"), stamp_file()
        if tree is None or path is None:
            print("review stamp: not in a git repository", file=sys.stderr)
            return 1
        path.write_text(tree + "\n", encoding="utf-8")
        print(f"review stamp: {tree}")
        return 0
    try:
        command = json.load(stdin)["tool_input"]["command"]
    except (ValueError, KeyError, TypeError):
        return 0
    if not isinstance(command, str) or not is_commit(command):
        return 0
    path = stamp_file()
    stamp = path.read_text(encoding="utf-8").strip() if path and path.exists() else None
    code, message = decide(command, git("config", "--get", "core.hooksPath"),
                           git("write-tree"), stamp)
    if message:
        print(message, file=sys.stderr)
    return code


if __name__ == "__main__":
    raise SystemExit(main(sys.argv, sys.stdin))
```

- [ ] **Step 4: Run the tests to see them pass**

Run: `python3 -m pytest tools/tests/test_review_stamp.py`
Expected: all pass.

- [ ] **Step 5: Write `.claude/settings.json`**

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "cd \"$CLAUDE_PROJECT_DIR\" && python3 -m tools.review_stamp"
          }
        ]
      }
    ]
  }
}
```

- [ ] **Step 6: Try the hook by hand**

```bash
echo '{"tool_input":{"command":"git commit -m x"}}' | python3 -m tools.review_stamp; echo "exit $?"
make stamp
echo '{"tool_input":{"command":"git commit -m x"}}' | python3 -m tools.review_stamp; echo "exit $?"
```

Expected: first `exit 2` with the review steps, then `exit 0`.

- [ ] **Step 7: Commit through the hook**

Run `/ste80-humanizer` on the new comments and `/simplify` on
`tools/review_stamp.py`. Then run each line below as its own Bash call:

```bash
git add tools/review_stamp.py tools/tests/test_review_stamp.py .claude/settings.json
make stamp
git commit -m "feat: block agent commits until the review skills have run"
```

Claude Code loads `.claude/settings.json` at the start of a session. The
hook is active in the next session. Until then, follow the same steps by
hand for every commit.

Failure log:

### Task 17: CLAUDE.md, README, ROADMAP, LICENSE and the PR template

**Files:**

- Modify: `CLAUDE.md`
- Create: `README.md`, `ROADMAP.md`, `LICENSE`,
  `.github/pull_request_template.md`

- [ ] **Step 1: Write `CLAUDE.md`**

Replace the whole file with this text. It keeps the functional-core line.

```markdown
# Abominable Ordnance

Load the functional-core skill before you change code.

## Rules

- The target is Factorio 2.1, with and without Space Age.
- Read `docs/design.md` and `docs/architecture.md` before you work on the
  mod.
- Use `superpowers:test-driven-development` for all code, `tools/`
  included.
- Before each commit, run `/ste80-humanizer` in British English on
  changed prose and comments, and `/simplify` on changed code. Stage the
  result, then run `make stamp`, then commit in a separate command. The
  Claude Code hook blocks the commit until you do.
- A change to mod code gets an entry under Unreleased in `CHANGELOG.md`.
  Update `ROADMAP.md` when a change affects it.
- A new spec: superpowers brainstorming writes it, `/egm:egm-review`
  reviews it, and superpowers writing-plans turns it into a plan.
- Change `main` only through a PR. A PR title is a Conventional Commit,
  for example `feat: add larvae`. PRs are squash merged.
- Before a release: run `/egm:egm-drift-report docs/` and `make check`,
  then set the version by the version rules in
  `docs/superpowers/specs/2026-11-12-repo-and-ci-design.md`.
- Never commit `docs/archive/`. It holds old chat logs.
```

- [ ] **Step 2: Write `LICENSE`**

```text
MIT License

Copyright (c) 2026 vetkat

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

`LICENSE` is not checked by the text check (it is not Markdown).

- [ ] **Step 3: Write `README.md`**

Sections, in this order:

1. `# Abominable Ordnance`, then two or three sentences on what the mod
   does, taken from the concept section of `docs/design.md`.
2. `## Status`, with this text: "Version 0.1.0 is an empty mod: the
   repository, its checks and its release workflow. The first features
   arrive in 1.0.0 (design version 1). See the [roadmap](ROADMAP.md)."
3. `## Install`, with this text: "The mod is not on the mod portal yet.
   Download the zip from the GitHub releases page and put it in your
   Factorio `mods` folder. The mod needs Factorio 2.1. Space Age is
   optional."
4. `## Development`: the tools and how to install them on Arch:
   `sudo pacman -S lua52 lua52-busted luacheck luarocks lychee`,
   `sudo pacman -S ruby nodejs npm python-pytest`,
   `gem install mdl`, `luarocks --lua-version 5.2 install --local luacov`,
   `npm ci`, `make setup`. Then a table of the Make targets (copy the
   table from the spec's "Make targets" section). Then a line on the
   `factorio-test` zip in `tools/vendor/` and where it comes from.
5. `## Documents`: links to `docs/design.md`, `docs/architecture.md`,
   `CHANGELOG.md`, `ROADMAP.md` and the spec.

- [ ] **Step 4: Write `ROADMAP.md`**

Structure:

```markdown
# Roadmap

Each release ships one design version from
[the design document](docs/design.md). The agent keeps this file up to
date.

## 0.1.0: repository and CI

- [x] The design document in Markdown
- [ ] An empty mod that loads in Factorio 2.1, with and without Space Age
- [ ] Every gate runs locally and in CI
- [ ] A release dry run builds a zip that loads

## 1.0.0: design version 1

## 2.0.0: design version 2

## 3.0.0: design version 3
```

Fill the 1.0.0, 2.0.0 and 3.0.0 sections from the version 1, 2 and 3
feature lists in `docs/design.md`. Each item is an unchecked box with a
link to its section, for example
`- [ ] Breeding pod ([design](docs/design.md#breeding-pod))`. Check every
anchor with `lychee --offline --include-fragments ROADMAP.md`.

- [ ] **Step 5: Write `.github/pull_request_template.md`**

```markdown
## What changes

## Checks

- [ ] `/ste80-humanizer` ran on changed prose and comments
- [ ] `/simplify` ran on changed code
- [ ] `CHANGELOG.md` has an entry under Unreleased, or the PR has the
      label `no-changelog`
- [ ] A new spec has an EGM review
```

- [ ] **Step 6: Check and commit**

The text check reads tracked and staged files, so stage first:

```bash
git add CLAUDE.md README.md ROADMAP.md LICENSE .github/pull_request_template.md
```

Run: `make fast`. Fix any finding in the new files, run
`/ste80-humanizer` on them, stage them again and run `make fast` until it
exits 0. Then run each line as its own Bash call:

```bash
make stamp
git commit -m "docs: add the README, roadmap, licence and agent rules"
```

Failure log:

### Task 18: In-game tests

**Files:**

- Create: `tools/ingame.sh`, `tests/ingame/smoke_test.lua`,
  `.factorio-version`, `.factorio-test-version`
- Modify: `control.lua`, `.luacheckrc`, `CHANGELOG.md`
- Uses: `tools/vendor/factorio-test_3.2.0.zip` (committed in Task 13)

- [ ] **Step 1: Write the version files**

`.factorio-version` holds `2.1.24` and a newline.
`.factorio-test-version` holds `3.2.0` and a newline.

- [ ] **Step 2: Write the smoke test**

`tests/ingame/smoke_test.lua`:

```lua
-- In-game smoke tests. factorio-test runs them in the headless server,
-- once with the base game only and once with Space Age.

test("the mod is active", function()
  assert(script.active_mods["abominable-ordnance"], "abominable-ordnance is not active")
end)

test("the game is version 2.1", function()
  local version = script.active_mods["base"]
  assert(version:match("^2%.1%."), "base is " .. version)
end)
```

- [ ] **Step 3: Hook the tests into `control.lua`**

Append to `control.lua`:

```lua

-- factorio-test runs the in-game tests. The hook does nothing unless the
-- factorio-test mod is active.
if script.active_mods["factorio-test"] then
  require("__factorio-test__/init")({ "tests/ingame/smoke_test" })
end
```

Add to `.luacheckrc`, after the `control.lua` entry:

```lua
-- factorio-test provides these in the in-game tests.
files["tests/ingame"] = {
  read_globals = {
    "script", "game", "defines", "test", "describe", "it", "before_each",
    "after_each", "before_all", "after_all", "async", "done",
    "after_ticks", "on_tick", "ticks_between_tests",
  },
}
```

- [ ] **Step 4: Write `tools/ingame.sh`**

```bash
#!/usr/bin/env bash
# Runs the in-game tests in the Factorio headless server.
#   tools/ingame.sh             base game only, then with Space Age
#   tools/ingame.sh base        base game only
#   tools/ingame.sh space-age   with Space Age
# The server and the factorio-test mod come in the pinned versions. No
# login is needed: the server is a free download, and the factorio-test
# zip is in tools/vendor/.
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
version=$(tr -d '[:space:]' < "$root/.factorio-version")
ft_version=$(tr -d '[:space:]' < "$root/.factorio-test-version")
cache=${FACTORIO_CACHE:-${XDG_CACHE_HOME:-$HOME/.cache}/abominable-ordnance}
server="$cache/factorio-$version"
binary="$server/bin/x64/factorio"
# The data folder must not sit inside the mod folder: the CLI links the
# mod folder into the data folder's mods/, which would make a loop.
data=$(mktemp -d)
trap 'rm -rf "$data"' EXIT

if [ ! -x "$binary" ]; then
  echo "ingame: downloading the Factorio $version headless server"
  mkdir -p "$cache"
  tmp=$(mktemp -d "$cache/download.XXXXXX")
  curl -fsSL "https://www.factorio.com/get-download/$version/headless/linux64" \
    | tar -xJ -C "$tmp"
  mv "$tmp/factorio" "$server"
  rmdir "$tmp"
fi

mkdir -p "$data/mods"
cp "$root/tools/vendor/factorio-test_$ft_version.zip" "$data/mods/"

run() {
  npx --no-install factorio-test run --mod-path "$root" \
    --factorio-path "$binary" --data-directory "$data" --forbid-only "$@"
}

case "${1:-all}" in
  base) run ;;
  space-age) run --mods space-age ;;
  all) echo "ingame: base game only"; run
       echo "ingame: with Space Age"; run --mods space-age ;;
  *) echo "usage: tools/ingame.sh [base|space-age]" >&2; exit 2 ;;
esac
```

Run: `chmod +x tools/ingame.sh`

- [ ] **Step 5: Run it**

Run: `make ingame`
Expected: the server downloads once (61 MB), then two runs report 2
passing tests each. If the CLI rejects an option, read
`npx factorio-test run --help` and adapt `run()`. If `--mods space-age`
does not pull in `quality` and `elevated-rails`, pass them too. Note each
change in the failure log.

- [ ] **Step 6: Plant a failing test**

Add `test("planted", function() assert(false) end)` to the smoke test.
Run `make ingame MODE=base`. Expected: FAIL. Remove the planted test.

- [ ] **Step 7: Check that the zip ships the tests but not the vendored mod**

`make package` reads `git ls-files`, so stage first:
`git add tests/ingame/ control.lua`. Then run:

```bash
make package && python3 -I -c "import zipfile;print('\n'.join(zipfile.ZipFile('build/abominable-ordnance_0.1.0.zip').namelist()))"
```

Expected: `tests/ingame/smoke_test.lua` is in the list. No path under
`tools/`.

- [ ] **Step 8: Commit**

Add an Unreleased entry to `CHANGELOG.md` under `### Added`:
`- In-game smoke tests that run in the headless server.`

Run the review skills, then each line as its own Bash call:

```bash
git add tools/ingame.sh tests/ingame/ .factorio-version .factorio-test-version control.lua .luacheckrc CHANGELOG.md
make stamp
git commit -m "test: run in-game smoke tests in the headless server"
```

Failure log:

### Task 19: factorio_version.py

**Files:**

- Create: `tools/factorio_version.py`
- Test: `tools/tests/test_factorio_version.py`

**Interfaces:**

- Produces: `factorio_version.problems(latest: object, pinned: str) ->
  list[str]`, `factorio_version.URL`.

- [ ] **Step 1: Write the failing tests**

`tools/tests/test_factorio_version.py`:

```python
from tools import factorio_version as fv


def latest(headless):
    return {"stable": {"headless": headless, "alpha": "x"}, "experimental": {}}


def test_same_version_passes():
    assert fv.problems(latest("2.1.24"), "2.1.24") == []


def test_older_stable_passes():
    assert fv.problems(latest("2.1.9"), "2.1.24") == []


def test_newer_stable_fails():
    found = fv.problems(latest("2.1.25"), "2.1.24")
    assert found and "2.1.25" in found[0] and "2.1.24" in found[0]


def test_numeric_order_not_text_order():
    assert fv.problems(latest("2.1.100"), "2.1.24")


def test_a_changed_format_is_a_problem():
    for data in [{}, [], {"stable": {}}, latest(7), latest("2.1")]:
        assert "format" in fv.problems(data, "2.1.24")[0], data


def test_a_bad_pin_is_a_problem():
    assert "X.Y.Z" in fv.problems(latest("2.1.24"), "2.1")[0]
```

- [ ] **Step 2: Run them to see them fail**

Run: `python3 -m pytest tools/tests/test_factorio_version.py`
Expected: FAIL, `ImportError`.

- [ ] **Step 3: Write `tools/factorio_version.py`**

```python
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
```

- [ ] **Step 4: Run the tests, then the real check**

Run:

```bash
python3 -m pytest tools/tests/test_factorio_version.py && python3 -m tools.factorio_version
```

Expected: tests pass. The real check prints that 2.1.24 is the newest, or
names a newer version. A newer version is information for the
maintainer, not a failure of this task.

- [ ] **Step 5: Commit**

Run the review skills, then each line as its own Bash call:

```bash
git add tools/factorio_version.py tools/tests/test_factorio_version.py
make stamp
git commit -m "feat: check weekly for a newer Factorio version"
```

Failure log:

### Task 20: check.yml and Dependabot

**Files:**

- Create: `.github/workflows/check.yml`, `.github/dependabot.yml`
- Test: `tools/tests/test_workflows.py`

- [ ] **Step 1: Write the failing tests**

`tools/tests/test_workflows.py`:

```python
"""Static checks on the workflows, for rules that only fail on GitHub."""
import pathlib

ROOT = pathlib.Path(__file__).resolve().parents[2]


def read(name):
    return (ROOT / ".github/workflows" / name).read_text(encoding="utf-8")


def test_check_uses_no_secrets():
    assert "secrets." not in read("check.yml")


def test_pr_checks_run_again_when_title_or_labels_change():
    assert ("types: [opened, synchronize, reopened, edited, labeled, unlabeled]"
            in read("check.yml"))


def test_all_checks_needs_every_job():
    text = read("check.yml")
    assert "needs: [text, lua, tools, ingame, pr]" in text


def test_each_gate_job_calls_its_make_target():
    text = read("check.yml")
    for target in ["make text", "make lua", "make tools", "make ingame"]:
        assert target in text


def test_check_can_be_called_by_the_release():
    assert "workflow_call:" in read("check.yml")
```

- [ ] **Step 2: Run them to see them fail**

Run: `python3 -m pytest tools/tests/test_workflows.py`
Expected: FAIL, `FileNotFoundError`.

- [ ] **Step 3: Write `.github/workflows/check.yml`**

```yaml
name: check

on:
  push:
    branches: ["**"]
  pull_request:
    types: [opened, synchronize, reopened, edited, labeled, unlabeled]
  workflow_call:

permissions:
  contents: read

jobs:
  text:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: "3.4"
      - run: gem install mdl
      - uses: actions/setup-node@v7
        with:
          node-version: 22
          cache: npm
      - run: npm ci
      - name: Install lychee
        run: |
          mkdir -p "$HOME/.local/bin"
          curl -fsSL https://github.com/lycheeverse/lychee/releases/download/lychee-v0.24.2/lychee-x86_64-unknown-linux-gnu.tar.gz \
            | tar -xz -C "$HOME/.local/bin"
          echo "$HOME/.local/bin" >> "$GITHUB_PATH"
      - run: make text

  lua:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
      # Factorio embeds Lua 5.2. A newer Lua could hide a bug.
      - uses: leafo/gh-actions-lua@v13
        with:
          luaVersion: "5.2"
      - uses: leafo/gh-actions-luarocks@v6
      - run: luarocks install busted && luarocks install luacheck && luarocks install luacov
      - run: make lua

  tools:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
      - uses: actions/setup-python@v7
        with:
          python-version: "3.12"
      - run: pip install pytest
      - run: make tools

  ingame:
    runs-on: ubuntu-latest
    env:
      FACTORIO_CACHE: ${{ github.workspace }}/../factorio-cache
    strategy:
      fail-fast: false
      matrix:
        mode: [base, space-age]
    steps:
      - uses: actions/checkout@v7
      - uses: actions/setup-node@v7
        with:
          node-version: 22
          cache: npm
      - run: npm ci
      - id: factorio
        run: echo "version=$(cat .factorio-version)" >> "$GITHUB_OUTPUT"
      - uses: actions/cache@v6
        with:
          path: ${{ env.FACTORIO_CACHE }}
          key: factorio-headless-${{ steps.factorio.outputs.version }}
      - run: make ingame MODE=${{ matrix.mode }}

  pr:
    if: github.event_name == 'pull_request'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
        with:
          fetch-depth: 0
      - run: python3 -m tools.pr_checks

  # Branch protection requires this job only, so the matrix entries do
  # not each need a rule.
  all-checks:
    if: always()
    needs: [text, lua, tools, ingame, pr]
    runs-on: ubuntu-latest
    steps:
      - if: contains(needs.*.result, 'failure') || contains(needs.*.result, 'cancelled')
        run: exit 1
      - run: echo "all checks passed"
```

`make lua` in CI: the leafo Lua binary is `lua`, not `lua5.2`, but CI has
`busted` on `PATH`, so the Makefile uses it.

The action versions were checked on 2026-11-12 with
`gh api repos/<owner>/<action>/releases/latest`: checkout v7.0.1,
setup-python v7.1.0, setup-node v7.1.0, cache v6.1.0, upload-artifact
v7.0.2, download-artifact v8.0.2, gh-actions-lua v13.1.0,
gh-actions-luarocks v6.1.1. Dependabot moves them later.

- [ ] **Step 4: Write `.github/dependabot.yml`**

```yaml
version: 2
updates:
  - package-ecosystem: github-actions
    directory: /
    schedule:
      interval: weekly
    # The ci prefix makes Dependabot's PR titles Conventional Commits.
    commit-message:
      prefix: ci
```

- [ ] **Step 5: Check the lychee archive layout**

Run:

```bash
curl -fsSL https://github.com/lycheeverse/lychee/releases/download/lychee-v0.24.2/lychee-x86_64-unknown-linux-gnu.tar.gz | tar -tz
```

Expected: `lychee` at the top level. If it is in a folder, add
`--strip-components=1` to the `tar -xz` in check.yml.

- [ ] **Step 6: Run the tests**

Run: `python3 -m pytest tools/tests/test_workflows.py`
Expected: all pass.

- [ ] **Step 7: Commit**

Run the review skills, then each line as its own Bash call:

```bash
git add .github/workflows/check.yml .github/dependabot.yml tools/tests/test_workflows.py
make stamp
git commit -m "ci: run every gate on push and on pull requests"
```

Failure log:

### Task 21: release.yml and weekly.yml

**Files:**

- Create: `.github/workflows/release.yml`, `.github/workflows/weekly.yml`
- Modify: `tools/tests/test_workflows.py`

- [ ] **Step 1: Add the failing tests**

Append to `tools/tests/test_workflows.py`:

```python
def test_release_calls_check_and_does_not_publish_to_the_portal():
    text = read("release.yml")
    assert "uses: ./.github/workflows/check.yml" in text
    assert "mods.factorio.com" not in text and "secrets." not in text


def test_release_checks_that_the_tag_is_on_main():
    assert "merge-base --is-ancestor" in read("release.yml")


def test_weekly_has_links_and_factorio_version_jobs():
    text = read("weekly.yml")
    assert "links:" in text and "factorio-version:" in text
    assert "schedule:" in text
```

Run: `python3 -m pytest tools/tests/test_workflows.py`
Expected: FAIL, `FileNotFoundError`.

- [ ] **Step 2: Write `.github/workflows/release.yml`**

```yaml
name: release

# A tag v<version> on main builds the zip and makes a GitHub release.
# A manual run in dry-run mode builds the zip and publishes nothing.
# Publishing to the mod portal arrives with design version 1.
on:
  push:
    tags: ["v*"]
  workflow_dispatch:
    inputs:
      mode:
        description: "dry-run builds the zip and publishes nothing"
        type: choice
        options: [dry-run]
        default: dry-run

permissions:
  contents: read

jobs:
  on-main:
    if: github.event_name == 'push'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
        with:
          fetch-depth: 0
      - name: Fail unless the tagged commit is on main
        run: git merge-base --is-ancestor "$GITHUB_SHA" origin/main

  checks:
    uses: ./.github/workflows/check.yml

  build:
    needs: [on-main, checks]
    if: >-
      always() && needs.checks.result == 'success' &&
      (needs.on-main.result == 'success' || needs.on-main.result == 'skipped')
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
      - name: Check the version
        run: |
          if [ "$GITHUB_EVENT_NAME" = push ]; then
            python3 -m tools.check_version "$GITHUB_REF_NAME"
          else
            python3 -m tools.check_version
          fi
      - run: make package
      - run: python3 -m tools.changelog notes "${GITHUB_REF_NAME#v}" > build/notes.md
        if: github.event_name == 'push'
      - uses: actions/upload-artifact@v7
        with:
          name: mod-zip
          path: |
            build/*.zip
            build/notes.md
          if-no-files-found: error

  release:
    needs: build
    if: github.event_name == 'push'
    runs-on: ubuntu-latest
    permissions:
      contents: write
    steps:
      - uses: actions/download-artifact@v8
        with:
          name: mod-zip
          path: build
      - name: Make the GitHub release
        env:
          GH_TOKEN: ${{ github.token }}
        run: >-
          gh release create "$GITHUB_REF_NAME" build/*.zip
          --repo "$GITHUB_REPOSITORY" --title "$GITHUB_REF_NAME"
          --notes-file build/notes.md
```

`if-no-files-found: error` with the two-line `path` passes when the zip
exists, even if `notes.md` is missing on a dry run.

- [ ] **Step 3: Write `.github/workflows/weekly.yml`**

```yaml
name: weekly

# Each job fails and does nothing else. GitHub tells the maintainer when a
# scheduled run fails.
on:
  schedule:
    - cron: "17 6 * * 1"
  workflow_dispatch:

permissions:
  contents: read

jobs:
  links:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
      - name: Install lychee
        run: |
          mkdir -p "$HOME/.local/bin"
          curl -fsSL https://github.com/lycheeverse/lychee/releases/download/lychee-v0.24.2/lychee-x86_64-unknown-linux-gnu.tar.gz \
            | tar -xz -C "$HOME/.local/bin"
          echo "$HOME/.local/bin" >> "$GITHUB_PATH"
      - name: Check every link, external ones included
        env:
          GITHUB_TOKEN: ${{ github.token }}
        run: lychee --no-progress $(git ls-files '*.md')

  factorio-version:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
      - run: python3 -m tools.factorio_version
```

If Task 20, Step 5 added `--strip-components=1` to check.yml, add it here
too.

- [ ] **Step 4: Run the tests and the gates**

Run: `python3 -m pytest tools/tests/test_workflows.py && make fast`
Expected: all pass.

- [ ] **Step 5: Commit**

Run the review skills, then each line as its own Bash call:

```bash
git add .github/workflows/release.yml .github/workflows/weekly.yml tools/tests/test_workflows.py
make stamp
git commit -m "ci: add the release workflow and the weekly checks"
```

Failure log:

### Task 22: GitHub repository and acceptance

The maintainer approved this task on 2026-11-12: create the public
repository, push, configure it and run the acceptance checks.

**Files:** `ROADMAP.md` changes through the acceptance PR in Step 6.

- [ ] **Step 1: Final local check**

Run: `make check`
Expected: exit 0. Then `python3 -m pytest tools/tests/test_gates.py -v`
and check that no test was skipped. A skip means a tool is missing: go
back to Task 0.

- [ ] **Step 2: Create the repository and push**

```bash
gh repo create vetkat/abominable-ordnance --public --source . --remote origin \
  --description "Factorio mod: breed monsters, load them with ordnance, fire them at your enemies."
git push -u origin main
```

- [ ] **Step 3: Settings: squash merge only, and the label**

```bash
gh api -X PATCH repos/vetkat/abominable-ordnance \
  -F allow_squash_merge=true -F allow_merge_commit=false -F allow_rebase_merge=false \
  -F delete_branch_on_merge=true \
  -f squash_merge_commit_title=PR_TITLE -f squash_merge_commit_message=PR_BODY
gh label create no-changelog --repo vetkat/abominable-ordnance \
  --description "This PR needs no CHANGELOG.md entry" --color cccccc
```

- [ ] **Step 4: Wait for the first CI run on main**

```bash
repo=vetkat/abominable-ordnance
sha=$(git rev-parse HEAD)
until id=$(gh run list --repo $repo --workflow check.yml --branch main --event push \
    --commit "$sha" --json databaseId --jq '.[0].databaseId') && [ -n "$id" ]; do
  sleep 10
done
gh run watch "$id" --repo $repo --exit-status
```

Expected: every job passes. Protection is still off, so fix a failing job
with a commit pushed straight to main, then watch the new run. Step 5
turns protection on, and from then on every change goes through a PR.

- [ ] **Step 5: Branch protection, also for admins**

```bash
cat > /tmp/protection.json <<'EOF'
{
  "required_status_checks": {"strict": true, "contexts": ["all-checks"]},
  "enforce_admins": true,
  "required_pull_request_reviews": {"required_approving_review_count": 0},
  "restrictions": null
}
EOF
gh api -X PUT repos/vetkat/abominable-ordnance/branches/main/protection --input /tmp/protection.json
```

- [ ] **Step 6: Acceptance on GitHub**

1. A direct push to main fails:
   `git commit --allow-empty -m "test: direct push" && git push origin main`.
   Expected: rejected. Then `git reset --hard origin/main`.
2. A PR with a planted mistake fails: branch `test/planted`, create
   `core/planted.lua` with the content `return {}` and no changelog
   entry, and open a PR titled `Planted mistake`. Expected: the `pr` job
   fails with two problems (title and changelog), `lua` fails on the
   coverage floor, and `all-checks` fails. Close the PR and delete the
   branch.
3. A clean PR passes: branch `docs/acceptance`, tick the 0.1.0 items in
   `ROADMAP.md`, open a PR titled `docs: tick the 0.1.0 roadmap items`.
   Expected: every job passes, including both `ingame` entries. Squash
   merge it.
4. A dry run of the release:

   ```bash
   gh workflow run release.yml --repo $repo -f mode=dry-run
   sleep 10
   id=$(gh run list --repo $repo --workflow release.yml --event workflow_dispatch \
     --limit 1 --json databaseId --jq '.[0].databaseId')
   gh run watch "$id" --repo $repo --exit-status
   gh run download "$id" --repo $repo --name mod-zip --dir build/dry-run
   ```

   Expected: the run passes, and `build/dry-run` holds the zip (the dry
   run writes no `notes.md`).
5. The zip loads in the headless server (manual check, once):

   ```bash
   mkdir -p build/load/mods && cp build/dry-run/*.zip build/load/mods/
   ~/.cache/abominable-ordnance/factorio-2.1.24/bin/x64/factorio \
     --mod-directory build/load/mods --create build/load/test-save.zip
   ```

   Expected: exit 0, and the log lists `abominable-ordnance` among the
   loaded mods.

- [ ] **Step 7: Record the result**

In the agent's memory, record that the CI project is done and that the
next project is design version 1.

Failure log:

---

## Planted mistakes per gate

| Gate | Planted mistake | Where |
| --- | --- | --- |
| mdl | a heading without a space | Task 15, `test_gates.py` |
| text check: humanizer rules | "We utilize this tool." | Task 13, `test_text_check.py` |
| text check: en dash | an en dash between two page numbers | Task 13, `test_text_check.py` |
| text check: cspell | "The color is red." | Task 14, `test_gates.py` |
| `.ste-allow` | entries without a reason or with rule `*` | Task 13, `test_text_check.py` |
| lychee | a link to a missing file | Task 15, `test_gates.py` |
| luacheck | a new global | Task 15, `test_gates.py` |
| busted: architecture | `game.tick` and `math.random` fixtures | Task 8 |
| busted: locale | a semicolon in a value | Task 9 |
| busted: docs against code | a name removed from the rule line | Task 11 |
| coverage floor | an untested core file | Task 10 (unit test and Step 6) |
| version check | wrong version, missing date, factorio_version "2.0" | Task 5 |
| changelog.txt | 99 dashes on every block | Task 4 |
| PR title | "Add larvae" | Task 7 and Task 22 |
| changelog rule | core change without an entry | Task 7 and Task 22 |
| Claude Code hook | commit without a stamp | Task 16 |
| in-game tests | `assert(false)` | Task 18 |
| weekly version check | a newer stable version | Task 19 |
| branch protection | a direct push to main | Task 22 |
