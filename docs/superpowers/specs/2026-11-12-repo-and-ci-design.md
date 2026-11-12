# Abominable Ordnance: repository and CI

Date: 2026-11-12. Status: the maintainer approved the design in chat. An
EGM review (Stages 5 to 8) followed. This version applies its findings and
the maintainer's answers. The spec waits for the maintainer's review.

## Purpose

This project sets up the repository and every quality check before any mod
feature exists. The agent writes most of the mod code in small TDD commits.
Each check must be in place before the first feature commit, so that it
catches a mistake in the commit that makes it. A check that arrives later
must first fix every mistake that came before it.

Goals:

1. An empty mod loads in Factorio 2.1, with and without Space Age.
2. Every gate in this spec runs on that empty mod, locally and in CI.
3. A release dry run builds a zip that the headless server loads.

The out-of-scope list is at the end of this spec.

Terms:

- **The maintainer** is vetkat, who owns the repository and approves every
  merge and release.
- **The agent** is Claude Code in this repository.
- **A gate** is a check that stops a commit, a merge or a release when it
  fails.
- **Design version N** is a section of the mod's design document. It ships
  as release N.0.0. The mod itself (design version 1) is the next project.
  It gets its own spec and plan.
- **Hattorio** is the maintainer's earlier Factorio mod, in
  `~/Documents/hattorio`. This project reuses parts of its tooling.

## Facts found during design

The agent checked these facts on 2026-11-12.

- Factorio 2.1.24 is the stable release. The maintainer plays 2.1.24 with
  Space Age on Steam.
- Factorio 2.1 refuses to load a mod with `factorio_version` "2.0". A probe
  mod with "2.1" loads. So this mod targets "2.1".
- The headless server for Linux is a free download of 61 MB, with no
  login, from <https://www.factorio.com/download>. It contains the
  `space-age` mod, so CI can test both modes.
- The `factorio-test` mod by GlassBricks
  (<https://mods.factorio.com/mod/factorio-test>) supports Factorio 2.1
  from version 3.1.2. The latest version is 3.2.0.
- The humanizer checker `ste_check.py` is MIT licensed, from
  <https://github.com/Dodaios/ste80-humanizer>. It reads files or standard
  input. It flags em dashes but not en dashes.

## Decisions

| Topic | Decision | Why |
| --- | --- | --- |
| Repository | `vetkat/abominable-ordnance` on GitHub, public | The maintainer's choice. |
| Branches | `main` is protected, also for admins. Changes go in through PRs that pass CI. PRs are squash merged. | Squash merge gives one commit per PR, with the PR title as its message. |
| Versions | Semantic versioning. The version in `info.json` is set by hand. | Automated bumps need commit data that nothing produces yet. |
| Commit format | Conventional Commits, checked on the PR title only. | After a squash merge, the title is the only message on `main`. A check on every commit would also need rules for Dependabot and merge commits. |
| Changelog | `CHANGELOG.md` in the [Keep a Changelog 1.0.0](https://keepachangelog.com/en/1.0.0/) format is the only changelog that people edit. `changelog.txt` is generated at build time and never committed. | The maintainer chose Keep a Changelog over Hattorio's hand-edited `changelog.txt`. A file that is never committed cannot drift. |
| Markdown lint | `mdl` (Ruby), with the existing `.mdlrc` and `.mdl-style.rb` | The maintainer chose `mdl` over the `markdownlint-cli` that was already installed. |
| Text check | Fails on any finding. `.ste-allow` lists accepted exceptions, each with a reason. | A warning that never fails gets ignored. |
| Spelling | cspell with the en-GB dictionary | All text is British English. |
| Links | lychee: links inside the repository on every push, external links once a week | External sites fail at random, so they must not block a PR. |
| Coverage | luacov. The floor is 90% of the lines in `core/`. An empty `core/` passes. | The core holds the logic, and the shell is tested in game. |
| Game tests | Headless Factorio with `factorio-test`, base game only and with Space Age | A plain load test shows that the mod loads, but not that it works. |
| Factorio version | Pinned in `.factorio-version`. A weekly job fails when a newer stable version exists. | Steam updates the maintainer's game, so CI must notice when it falls behind. |
| Updates | Dependabot, weekly, for GitHub Actions, with the commit prefix `ci` | The prefix makes its PR titles pass the title check. |
| Local gates | A git pre-commit hook for the fixed checks. A Claude Code hook that blocks a commit until the review skills have run. | The git hook catches mistakes from everyone. Only the Claude hook can make the agent run a skill. |
| Design doc | Converted to `docs/design.md`, which is then the source of truth for the design. The PDF is no longer used. | A Markdown file works with diffs, linters and reviews. |
| Reviews | [EGM](https://github.com/google/elephant-goldfish-model) (`/egm:egm-review`) on every spec, `/egm:egm-drift-report docs/` before each release | Reviewers with no context find the gaps that the author cannot see. |
| Language | British English for all text | The maintainer's choice. |

## Repository layout

Files marked "exists" are in the repository already. This project edits
them but does not create them again.

```text
info.json                factorio_version "2.1", dependencies: base >= 2.1, ? space-age
data.lua, control.lua    thin shell: the empty mod loads and does nothing
core/                    pure Lua with no game API, empty until design version 1
locale/en/locale.cfg     mod name and description
spec/                    busted tests: architecture rules, locale, docs against code
tests/ingame/            factorio-test tests
tools/                   Python standard library only
  changelog.py           CHANGELOG.md to changelog.txt
  check_version.py       info.json, CHANGELOG.md and the tag agree
  pr_checks.py           PR title format and the changelog rule
  prose.py               pulls Lua comments and locale text for the text check
  text_check.py          runs the checker and cspell, applies .ste-allow
  review_stamp.py        writes and checks the review stamp
  package.py             builds the zip
  vendor/ste_check.py    copy of the humanizer checker
  tests/                 pytest tests for every tool
docs/design.md           the design document
docs/architecture.md     exists: shell and core, the data stage, determinism
docs/superpowers/        exists: specs and plans
CHANGELOG.md             Keep a Changelog, with Unreleased at the top
ROADMAP.md               releases and their items
README.md                what the mod does, status, install, developer setup
CLAUDE.md                exists: rules for the agent
THIRD_PARTY.md           copied code and its upstream commit
LICENSE                  MIT, as in Hattorio
.mdlrc, .mdl-style.rb    exist: mdl configuration
.luacheckrc, .busted, .luacov, cspell.json, lychee.toml
.ste-allow               accepted text-check exceptions
.factorio-version        pinned headless server version
.factorio-test-version   pinned factorio-test version
.gitignore               build/, changelog.txt, caches
.githooks/pre-commit     runs make fast
.claude/settings.json    the Claude Code hook
.github/workflows/       check.yml, release.yml, weekly.yml
.github/dependabot.yml, .github/pull_request_template.md
Makefile
```

From Hattorio, this project adapts `check_version.py`, `package.py`,
`release.yml`, `.luacheckrc`, `.busted` and the docs-against-code test
(a busted test that checks the names in the docs against the names in the
code). The changes are:

- `check_version.py` reads `CHANGELOG.md`, not `changelog.txt`, and adds the
  dated-section rule (see Releases).
- `package.py` ships this mod's files. Hattorio's list of shipped files
  does not fit. The plan gives the exact list. It includes `core/`.
- `release.yml` calls `check.yml` and does not publish to the mod portal
  (see Releases).

## Make targets

Each CI job calls one Make target, so a check works the same way on the
developer's machine and in CI.

| Target | What it runs | When it runs |
| --- | --- | --- |
| `make setup` | Sets `core.hooksPath` to `.githooks` | once, after a clone |
| `make text` | mdl, the text check, lychee in offline mode | in `make fast`, CI job `text` |
| `make lua` | luacheck, busted under Lua 5.2, the coverage floor | in `make fast`, CI job `lua` |
| `make tools` | pytest, `check_version.py` without a tag | in `make fast`, CI job `tools` |
| `make fast` | `make text`, `make lua`, `make tools` | every commit (git hook) |
| `make ingame` | Downloads the headless server and `factorio-test` in their pinned versions into a cache, then runs the tests twice: base only, then with Space Age | CI job `ingame`, by hand |
| `make check` | `make fast`, `make ingame` | before a PR |
| `make stamp` | Writes the review stamp for the staged files | after the review skills |
| `make package` | Generates `changelog.txt` and builds `build/abominable-ordnance_<version>.zip` | release |

The PR checks (`pr_checks.py`) need a PR title and a list of changed files,
so they run only in CI, outside Make.

The target for `make fast` is 10 seconds on the maintainer's machine. The
plan measures it. If it goes over, the git hook runs the file checks on the
staged files only, and CI keeps checking every file.

## The text check

`tools/text_check.py` checks three kinds of text:

1. every Markdown file, specs and plans included
2. every Lua comment, which `prose.py` extracts
3. every locale string in `locale/`, which `prose.py` extracts

For each one it applies these rules:

- the findings of `vendor/ste_check.py`
- no en dash, because the checker only flags em dashes
- cspell with the en-GB dictionary, so `color` and `behavior` fail

cspell reads the extracted prose, not the Lua code. Lua code uses
Factorio's API names, such as `color`, which are American.

Code, paths and identifiers in Markdown code spans and code blocks are not
prose, so the check skips them.

`.ste-allow` holds accepted exceptions. Each entry names a rule, a file and
a reason, and can also name a word. So no entry can disable every rule for
a file. The plan gives the exact syntax.

A result that matches an entry passes. Any other result fails the check,
and the check prints the file, the line and the rule.

## CI

`check.yml` runs on every PR and on every push to `main`. A push run on a
PR branch would report a second `all-checks` without the PR checks. Other
workflows can also call it (`workflow_call`). It has these jobs:

1. **`text`**: `make text`.
2. **`lua`**: `make lua`.
3. **`tools`**: `make tools`.
4. **`ingame`**: `make ingame`, as a matrix with two entries, base only and
   Space Age. It caches the server and `factorio-test` by version.
5. **`pr`**: on PRs only. `pr_checks.py` checks the PR title against
   Conventional Commits and applies the changelog rule.
6. **`all-checks`**: needs every job above. Branch protection on `main`
   requires this job only, so the matrix entries do not each need a rule.

`check.yml` uses no secrets, so PRs from forks and from Dependabot run
every job.

### The changelog rule

A PR that changes mod code must also change `CHANGELOG.md`. Mod code is
every file that the zip ships, except `changelog.txt`. A PR with the label
`no-changelog` skips the rule. The rule runs per PR in CI only. A local
version would fire on every small TDD commit.

### Weekly checks

`weekly.yml` runs once a week. It has two jobs. Each one fails and does
nothing else, because GitHub already tells the maintainer when a scheduled
run fails:

- **`links`**: lychee on every link, external ones included.
- **`factorio-version`**: fails when Factorio's latest stable headless
  version is newer than `.factorio-version`. The job reads Factorio's
  public release data. If that data cannot be read, the job fails with a
  clear message.

`dependabot.yml` updates the GitHub Actions versions once a week.

## Releases

`release.yml` has two modes.

A tag `v<version>` on `main` starts a release:

1. It fails if the tagged commit is not on `main`.
2. It calls `check.yml`, so a release runs the same checks as a PR.
3. `check_version.py` runs with the tag.
4. `package.py` generates `changelog.txt` and builds the zip.
5. The zip goes to a GitHub release. The release notes are the version's
   section of `CHANGELOG.md`.

A manual run in `dry-run` mode does steps 2 to 4, with
`check_version.py` run without a tag. It keeps the zip as a workflow
artefact and publishes nothing.

This project does not publish to the mod portal. Nobody can withdraw a
portal release, and nothing goes to the portal before design version 1.
That project adds the upload, the `FACTORIO_API_KEY` secret and a required
reviewer on a `mod-portal` environment.

This `release.yml` differs from Hattorio's in four ways:

1. It calls `check.yml`. Hattorio's workflow repeats some of those steps.
2. It takes the release notes from `CHANGELOG.md`, not from GitHub's
   generated notes.
3. It checks that the tag is on `main`.
4. It has no upload and no `check-credentials` mode.

### Version rules

MAJOR breaks saves or removes prototypes. MINOR adds features. PATCH fixes
bugs. This project leaves the version at 0.1.0, unreleased. Design
version N ships as release N.0.0.

`check_version.py` has two modes:

- **Without a tag** (every commit, and the dry run): the newest section of
  `CHANGELOG.md` is either `Unreleased` or the version in `info.json`.
- **With a tag**: the tag, `info.json` and the newest section of
  `CHANGELOG.md` name the same version, and that section has a date.

### Changelog generation

`changelog.py` maps the Keep a Changelog headings to Factorio's
categories. Added becomes Features. Changed, Deprecated and Removed become
Changes. Fixed and Security become Bugfixes. The `Unreleased` section
becomes the version in `info.json`.

Each version block in `changelog.txt` starts with a line of exactly 99
dashes, or Factorio does not load the mod. `changelog.py` has a test for
that.

### The pinned Factorio version

`.factorio-version` holds the pinned headless version, 2.1.24.
`.factorio-test-version` holds the pinned `factorio-test` version.
Dependabot cannot update these files. A move to a new Factorio version is
a PR that changes `.factorio-version`. The `ingame` job shows if the
mod still passes on that version.

`factorio-test` must come from a source that needs no login, so that
`check.yml` stays free of secrets. The plan checks if GlassBricks publishes
the mod zip on GitHub. If not, the agent commits the zip to
`tests/ingame/vendor/`. The plan also picks the test runner. If the runner
is the `factorio-test` command-line tool from npm, Node is already there
for cspell.

## Docs

- `docs/design.md`: converted from
  `~/Downloads/Abominable-Ordnance-design-doc.pdf` in two commits. The
  first commit is a faithful conversion to Markdown, with "2.0" changed to
  "2.1". The lifecycle chart and the research tree become Mermaid
  diagrams. The open questions stay. The second commit is the
  `/ste80-humanizer` pass, so that the maintainer can review its changes
  on their own.
- `docs/architecture.md`: exists. Its title and text change from 2.0 to
  2.1. It is complete when each of its rules has a busted test or a
  luacheck rule (see Testing this project).
- `ROADMAP.md`: one section per release: 0.1.0 (this project), 1.0.0,
  2.0.0 and 3.0.0. Each item is a checkbox with a link to its section of
  `docs/design.md`. The agent keeps the roadmap up to date, from
  `docs/design.md` and the maintainer's decisions.
- `CHANGELOG.md`: Keep a Changelog 1.0.0, with an `Unreleased`
  section at the top.
- `README.md`: what the mod does, its status, how to install it, and
  the developer setup.
- `THIRD_PARTY.md`: the humanizer checker and its upstream commit, and
  any other copied code.

## Local gates

### Git hook

`.githooks/pre-commit` runs `make fast`. If it fails, the commit stops.
`git commit --no-verify` skips it, and CI is the backstop.

### Claude Code hook

`tools/review_stamp.py` blocks an agent commit until the agent runs the
review skills. A hook cannot run a skill. But it can refuse the commit until
the agent runs the skills. `make stamp` writes the hash of the staged tree
(`git write-tree`) to `.git/review-stamp`. Two hooks use it:

1. The git pre-commit hook checks the stamp when the commit comes from
   Claude Code (the `CLAUDECODE` variable is set). During a commit, git
   points `git write-tree` at the exact index that it is about to commit.
   So the check also holds for `git commit -a` and for paths after
   `git commit`. Without a current stamp, the message tells the agent to
   do these steps:
   1. Run `/ste80-humanizer` on staged prose and comments.
   2. Run `/simplify` on staged code.
   3. Update `ROADMAP.md` if the change affects it.
   4. Run `make stamp`.
2. `.claude/settings.json` adds a `PreToolUse` hook for Bash commands that
   contain `git commit`. It makes sure that the git hook runs. It blocks
   the commit (exit code 2) when `core.hooksPath` is not `.githooks`, and
   when the command has `--no-verify`.

A change to the staged files after `make stamp` gives a new hash, so the
git hook asks again. The Claude hook does not run `make fast`, because the
git hook runs it on the same commit.

The stamp shows that the skills ran, not that they did their job well. A
human who commits outside Claude Code does not meet the stamp check.

## CLAUDE.md and the PR template

`CLAUDE.md` keeps its functional-core line and gets the working rules of
this spec:

- TDD for all code
- the review skills before each commit
- updates to `CHANGELOG.md` and `ROADMAP.md` for each change to mod code
- EGM for specs
- the release steps
- changes to `main` only through PRs, with Conventional Commit titles
- the 2.1 target

The functional-core skill holds the coding rules that the agent loads
before it changes code: pure core, side effects at the edge. It lives
outside this repository. The plan gives the exact text of `CLAUDE.md`.

The PR template has checkboxes for the humanizer pass, the `/simplify`
pass, the changelog and the EGM review of any new spec.

## Risks

- **External downloads.** The headless server and `factorio-test` come
  from outside sites. CI pins and caches them, so it needs the sites only
  when the cache is empty.
- **Bypassed hooks.** `--no-verify`, or a commit command the Claude hook
  does not match, skips a local gate. CI runs the fixed checks again on
  every PR.
- **Text-check false positives.** `ste_check.py` is a heuristic. A false
  finding goes in `.ste-allow` with a reason.
- **Copied code.** `vendor/ste_check.py` runs in CI. `THIRD_PARTY.md`
  records its upstream commit, and an update is a reviewed PR.
- **Tool versions that float.** CI pins Lua, Factorio and `factorio-test`.
  mdl, cspell, lychee, luacheck, busted and pytest float. CI is the source
  of truth when a local result differs.

## Testing this project

Each tool in `tools/` is built test-first with pytest.

The busted tests in `spec/` enforce the rules in `docs/architecture.md`.
Each one fails first on a planted bad file:

- a core module never names `game`, `storage`, `script` or `defines`
- neither `core/` nor `control.lua` uses `math.random`

These are the acceptance criteria for this project:

1. `make check` passes on a clean clone.
2. Each gate has a test that fails on a planted mistake. The plan lists
   one mistake per gate.
3. The `ingame` job passes in both modes on GitHub.
4. The zip from a dry run of `release.yml` loads in the headless server.
   This is a manual check, done once.
5. Branch protection blocks a direct push to `main`, also from an admin.
6. The Claude Code hook blocks a commit without a current review stamp.

## Out of scope

- Any mod feature. Those belong to the design version 1 project.
- Uploads to the mod portal. They arrive with design version 1.
- A fix for Hattorio's `factorio_version`, which still says "2.0".
- Automated version bumps from commit messages.
- Pinned versions for tools other than Lua, Factorio and `factorio-test`.
