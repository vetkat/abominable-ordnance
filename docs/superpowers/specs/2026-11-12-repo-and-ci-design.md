# Abominable Ordnance: repository and CI

Date: 2026-11-12. Status: design approved in chat. The spec waits for an
EGM review and for the user's review.

## Purpose

This project sets up the repository and every quality check before any
mod feature exists. At the end, an empty mod loads in Factorio 2.1, with
and without Space Age, and every gate in this spec runs on it.

The mod itself (design Version 1) is the next project. It gets its own
spec and plan.

## Facts found during design

- Factorio 2.1.24 is the current stable release. The user plays 2.1.24
  with Space Age on Steam.
- Factorio 2.1 refuses to load a mod with `factorio_version` "2.0". A
  probe mod with "2.1" loads. So this mod targets "2.1".
- The headless server for Linux is a free download of 61 MB, with no
  login. It contains the `space-age` mod, so CI can test both modes.
- The `factorio-test` mod (by GlassBricks) supports Factorio 2.1 from
  version 3.1.2. The latest version is 3.2.0.
- The humanizer checker `ste_check.py` is MIT licensed, from
  <https://github.com/Dodaios/ste80-humanizer>. It reads files or
  standard input.

## Decisions

| Topic | Decision |
| --- | --- |
| Repository | `vetkat/abominable-ordnance` on GitHub, public |
| Branches | `main` is protected. Changes go in through PRs that pass CI. |
| Versions | Semantic versioning. The version in `info.json` is set by hand. CI checks it against the changelog and the tag. |
| Commits | Conventional Commits. CI checks the format of the commits in a PR. |
| Changelog | `CHANGELOG.md` in the Keep a Changelog 1.0.0 format is the only changelog that people edit. A tool generates Factorio's `changelog.txt` when it builds the zip. |
| Markdown lint | `mdl` (Ruby), with the style from the functional-core skill |
| Text check | Fails on any finding. `.ste-allow` lists accepted exceptions, each with a reason. |
| Spelling | cspell with the en-GB dictionary |
| Links | lychee: our own links on every push, external links once a week |
| Coverage | luacov. The floor is 90% of the lines in `core/`. An empty `core/` passes. |
| Game tests | Headless Factorio with `factorio-test`, base game only and with Space Age |
| Updates | Dependabot, weekly, for GitHub Actions |
| Local gates | A git pre-commit hook, and a Claude Code hook before `git commit` |
| Design doc | Converted to `docs/design.md`. The repo is the source of truth. |
| EGM | `/egm:egm-review` on every spec, `/egm:egm-drift-report` before each release |
| Language | British English for all text |

## Repository layout

```text
info.json             factorio_version "2.1", dependencies: base >= 2.1, ? space-age
data.lua, control.lua thin shell. The empty mod loads and does nothing.
core/                 pure Lua with no game API. Empty until mod version 1.
locale/en/locale.cfg  mod name and description
spec/                 busted tests: invariants, locale, docs against code
tests/ingame/         factorio-test tests
tools/                Python standard library, with pytest tests
  changelog.py        CHANGELOG.md to changelog.txt, and the check that they match
  check_version.py    info.json, CHANGELOG.md and the tag agree
  commits.py          Conventional Commit format check
  prose.py            pulls Lua comments and locale text for the text check
  text_check.py       runs the checker, applies .ste-allow, dash and US-spelling rules
  package.py          builds the zip
  publish_mod.sh      uploads to the mod portal
  vendor/ste_check.py copy of the humanizer checker, credited in THIRD_PARTY.md
docs/
  design.md           the design doc
  architecture.md     shell and core, the data stage, determinism
  superpowers/        specs and plans
CHANGELOG.md  ROADMAP.md  README.md  CLAUDE.md  THIRD_PARTY.md  LICENSE
.mdlrc  .mdl-style.rb  .luacheckrc  .busted  .luacov  cspell.json
.ste-allow  lychee.toml  .factorio-version
.githooks/pre-commit
.claude/settings.json  .claude/hooks/pre-commit-reminder.sh
.github/workflows/check.yml  .github/workflows/release.yml
.github/workflows/links.yml  .github/dependabot.yml
.github/pull_request_template.md
Makefile
```

Hattorio supplies `check_version.py`, `package.py`, `publish_mod.sh`, the
release workflow, `.luacheckrc`, `.busted` and the docs-against-code test
pattern. We adapt each one and do not copy it as is. `check_version.py` reads
`CHANGELOG.md`, not `changelog.txt`.

## Make targets

Every gate runs these targets, so a check works the same way on the
developer's machine and in CI.

| Target | What it runs | Who runs it |
| --- | --- | --- |
| `make setup` | Sets `core.hooksPath` to `.githooks` | the developer, once |
| `make fast` | mdl, the text check, cspell, luacheck, busted under Lua 5.2, pytest, version and changelog checks | git hook, Claude hook |
| `make check` | `make fast`, the coverage floor, lychee in offline mode, `make ingame` | before a PR, CI |
| `make ingame` | Downloads the headless server in the version from `.factorio-version` into a cache, then runs `factorio-test` twice: base only, then with Space Age | CI, by hand |
| `make package` | Generates `changelog.txt` and builds `build/abominable-ordnance_<version>.zip` | release |

`make fast` must finish in about 10 seconds on the developer's machine.

## The text check

`tools/text_check.py` checks three kinds of text:

1. every Markdown file
2. every Lua comment, which `prose.py` extracts
3. every locale string in `locale/`, which `prose.py` extracts

For each one it applies these rules:

- the findings of `vendor/ste_check.py`
- no em dash or en dash
- no American spelling from a fixed list (for example "color" and
  "behavior")

Code, paths and identifiers in Markdown code spans and code blocks are not
prose, so the check skips them.

`.ste-allow` holds accepted exceptions. Each line names a rule, a word or a
file, and a reason. A finding that matches an exception passes. Any other
finding fails the check and prints the file, the line and the rule.

## CI

`check.yml` runs on every push and every PR. It has four jobs. The branch
protection on `main` requires all four.

1. **text:** mdl, the text check, cspell, lychee in offline mode.
2. **lua:** luacheck, busted under Lua 5.2, the coverage floor.
3. **tools:** pytest, `check_version.py`, `commits.py` on the PR's
   commits, and the changelog rule below.
4. **ingame:** a matrix with two entries, base only and Space Age. It
   caches the headless server by version.

**The changelog rule.** A PR that changes mod code must also change
`CHANGELOG.md`. Mod code means `info.json`, `data*.lua`, `control.lua`,
`settings*.lua`, `core/`, `prototypes/` and `locale/`. A PR with the label
`no-changelog` skips the rule.

`links.yml` runs lychee on all links once a week. When a link fails, it
opens an issue.

`dependabot.yml` updates the GitHub Actions versions once a week.

## Releases

`release.yml` works as in Hattorio:

1. A tag `v<version>` starts it. It runs every check from `check.yml`
   again.
2. `check_version.py` confirms that `info.json`, `CHANGELOG.md` and the tag
   agree, and that `CHANGELOG.md` has a dated section for the version.
3. `package.py` generates `changelog.txt` and builds the zip.
4. The zip goes to a GitHub release. The release notes are the version's
   section of `CHANGELOG.md`.
5. The upload to the mod portal runs last, in the `mod-portal`
   environment, after the user approves. A portal release cannot be
   withdrawn.

A manual run in "dry-run" mode does steps 1 to 3 and publishes nothing.
This project proves the pipeline with a dry run. Nothing goes to the
portal until mod version 1.

**Version rules.** MAJOR breaks saves or removes prototypes. MINOR adds
features. PATCH fixes bugs. This project leaves the version at 0.1.0,
unreleased. Design Version N becomes release N.0.0.

**Changelog mapping.** `changelog.py` maps the Keep a Changelog headings to
Factorio's categories:

| Keep a Changelog | Factorio |
| --- | --- |
| Added | Features |
| Changed, Deprecated, Removed | Changes |
| Fixed, Security | Bugfixes |

The generated file starts with exactly 99 dashes on each entry, or Factorio
does not load the mod. `changelog.py` has a test for that.

`.factorio-version` holds the pinned headless version, 2.1.24. Dependabot
cannot update it. A move to a new Factorio version is a deliberate change,
and CI proves it.

## Docs

- **`docs/design.md`**: the PDF design doc converted to Markdown, through
  the humanizer, with "2.0" changed to "2.1". The lifecycle chart and the
  research tree become Mermaid diagrams. The open questions stay.
- **`docs/architecture.md`**: the Factorio notes from the functional-core
  work, finished and updated for 2.1.
- **`ROADMAP.md`**: one section per release: 0.1.0 (this project), 1.0.0,
  2.0.0 and 3.0.0. Each item is a checkbox with a link to its section of
  `docs/design.md`. The agent keeps the roadmap up to date. All of its
  content follows from `docs/design.md` and the user's decisions.
- **`CHANGELOG.md`**: Keep a Changelog 1.0.0, with an `Unreleased`
  section at the top.
- **`README.md`**: what the mod does, its status, how to install it, and
  the developer setup.
- **`THIRD_PARTY.md`**: the humanizer checker and any other copied code.
- **`LICENSE`**: MIT, as in Hattorio.

## Local gates

**Git hook.** `.githooks/pre-commit` runs `make fast`. If it fails, the
commit stops.

**Claude Code hook.** `.claude/settings.json` adds a `PreToolUse` hook for
Bash commands that contain `git commit`. The hook does these steps:

1. It runs `make fast` and the changelog rule on the staged files. If one
   fails, the hook blocks the commit and prints why.
2. It prints a reminder: run `/ste80-humanizer` on changed text and
   comments, run `/simplify` on changed code, and update `ROADMAP.md` if
   the change affects it.

A hook cannot run a skill, so the reminder is as far as it goes.

## CLAUDE.md

`CLAUDE.md` holds these rules:

- Load the functional-core skill before you change code.
- Use `superpowers:test-driven-development` for all code, the tools too.
- Before each commit, run `/ste80-humanizer` in British English on changed
  prose and comments. Then run `/simplify` on changed code.
- After a significant change, update `CHANGELOG.md` (Unreleased) and
  `ROADMAP.md`.
- For a spec: superpowers brainstorming writes it, `/egm:egm-review`
  reviews it, and then superpowers writing-plans makes the plan.
- Before a release: `/egm:egm-drift-report docs/`, `make check`, and the
  version bump by the version rules.
- Use Conventional Commits. Change `main` only through a PR.
- The target is Factorio 2.1, with and without Space Age.
- Read `docs/design.md` and `docs/architecture.md` before mod work.

## Pull request template

The template has checkboxes for the humanizer pass, the `/simplify` pass,
the changelog, and the EGM review of any new spec.

## Testing this project

Each tool in `tools/` is built test first with pytest. Each Lua invariant
is a busted test that fails first on a planted bad file.

These checks prove that the project is complete:

1. `make fast` and `make check` pass on a clean clone.
2. Each gate fails on a planted mistake:
   - a dash in a Markdown file
   - an American spelling in a Lua comment
   - a broken `mdl` rule
   - a mod change with no changelog entry
   - a wrong version in `info.json`
   - a commit message that is not a Conventional Commit
   - `math.random` in `core/`
3. The `ingame` job passes in both modes on GitHub.
4. A dry run of `release.yml` builds a zip that the headless server loads.
5. The branch protection blocks a direct push to `main`.

## Out of scope

- Any mod feature. Those belong to the mod version 1 project.
- A fix for Hattorio's `factorio_version`, which still says "2.0".
- Automated version bumps from commit messages.
