# Stage 5: Initial Zoom Out Review

Target: `docs/superpowers/specs/2026-11-12-repo-and-ci-design.md` as of
commit dd3ab51, lines 1 to 267 (the whole file). Later edits moved the
lines.

Goldfish context: `docs/architecture.md`, and Hattorio's
`.github/workflows/release.yml`, `tools/check_version.py` and
`tools/package.py`.

Reviewers: `egm-zoom-out` (simplicity and scope) and `egm-inventive-catalyst`
(false compromises).

Neither reviewer found a Blocker. Both say the design passes with changes.

## Elephant notes

These notes come from the main session, which has the full design history.
They are not reviewer findings.

- **Found by both reviewers.** Z1 and Z6 match C4: one gate list should
  drive local runs, `check.yml` and `release.yml`. Z2 matches C2: the git hook
  and the Claude hook both run `make fast`. Z13 matches C6: the 10-second
  budget for `make fast`.
- **Against decisions the user made.** Z4 (drop Keep a Changelog) goes
  against the user's explicit choice of Keep a Changelog with a generated
  `changelog.txt`. Z9 (shrink `ROADMAP.md`) goes against the user's decision
  that the agent keeps `ROADMAP.md` up to date. These findings stay in the
  report, but the decisions stand unless the user changes them.
- **Not checked yet.** The catalyst says the spec does not say where
  `factorio-test` 3.2.0 comes from, and a portal download may need a token.
  Z5 asks whether `ste_check.py` already flags dashes. Check both before
  making any fix.
- **Not raised by the reviewers.** The spec says "works as in Hattorio" and
  "adapt" without saying what changes. The reviewers had Hattorio's files, so
  they could not notice this gap. A reader without those files could not
  either.

## Zoom-out reviewer (Z)

Verdict: passes with changes. The objective is clear: an empty mod that loads
in 2.1 with and without Space Age, behind every gate. The main risk is how
much the design builds before the mod has any code.

| ID | Severity | Scope | Finding and fix |
| --- | --- | --- | --- |
| Z1 | Major | Make targets (lines 88 to 101) against CI (125 to 135) | Line 90 says every gate runs the Make targets, but the CI jobs list the tools one by one. Each check is then wired up twice, and the two copies will drift apart. Fix: one Make target per CI job (`make text`, `make lua`, `make tools`, `make ingame`). `make fast` and `make check` combine them. |
| Z2 | Major | Local gates (204 to 218), Decisions "Local gates" (45) | An agent commit runs `make fast` twice, once in the Claude hook and once in the git hook. Fix: the Claude hook only prints the reminder. Move the staged-file changelog rule into the git hook or `make fast`, so humans get it too, or leave it to CI. |
| Z3 | Major | Commits (36), `commits.py` (62), CI job 3 (132), out of scope (267) | Nothing reads the Conventional Commit messages, because version bumps and the changelog are manual. The commit format, the changelog rule with its `no-changelog` label, and the PR checkbox overlap. Fix: drop `commits.py` and keep the convention in CLAUDE.md, or check only the PR title. |
| Z4 | Major | Changelog (37), `changelog.py` (60), mapping (170 to 180), `check_version.py` (85) | Keep a Changelog adds a second format, a generator, a lossy mapping and a sync check, and it weakens the reuse of Hattorio's `check_version.py`. Fix: edit `changelog.txt` directly as Hattorio does, or say why the extra tool is worth it. |
| Z5 | Major | Text check (103 to 123), `prose.py`, `text_check.py`, `ste_check.py`, Spelling (40) | An en-GB-only cspell dictionary already flags American spellings and already reads Lua and plain-text files. The American-spelling list duplicates it. `ste_check.py` may already flag dashes (not confirmed). Fix: cspell owns spelling. `text_check.py` keeps the humanizer findings and `.ste-allow`, perhaps on Markdown only until the mod has text. |
| Z6 | Major | Releases step 1 (151 to 152) | `release.yml` repeats every check from `check.yml`, as in Hattorio, so there are two gate lists that will drift apart. Fix: make `check.yml` callable (`workflow_call`) and call it from `release.yml`, or make both call the same Make targets. |
| Z7 | Nit | Coverage (42), `make check` (97), CI job 2 (131) | A 90% floor on an empty `core/` needs a special case to pass. Fix: set up luacov reporting now and add the floor in mod version 1. |
| Z8 | Nit | Releases step 5 (158 to 160), `publish_mod.sh` (66) | The publish job arrives in this project but stays untested until mod version 1. Fix: think about moving it to the first real release. |
| Z9 | Nit | `ROADMAP.md` (193 to 196) | The roadmap is a copy of `docs/design.md` that is kept in sync by hand. Fix: keep it to release headings that link to `design.md`, or add a status column to `design.md`. |
| Z10 | Nit | `docs/design.md` (188 to 190) | A humanizer pass during conversion could change the meaning of the source of truth. Fix: convert faithfully and commit, then run the humanizer as a separate, reviewed step. |
| Z11 | Nit | Testing item 2 (258), against `architecture.md` | The planted mistakes do not include a game-API name (`game`, `storage`, `script`, `defines`) in `core/`. That is the main architecture rule. Fix: add that planted mistake, and decide whether the `math.random` rule also covers `control.lua`. |
| Z12 | Nit | CLAUDE.md (220 to 236), PR template (238 to 241), changelog mapping (170 to 180) | These are content for the implementation plan, not design. Keep the facts that carry weight: the 99-dash rule and `factorio_version` "2.1". |
| Z13 | Nit | `make fast` budget (101) | Ruby, Node, Lua and Python all start on every commit, so 10 seconds may not hold. Fix: the hook checks staged files and CI checks the full tree. |

The reviewer said these parts work well: reuse of Hattorio's release,
version-check and packaging pattern, the pinned headless version, the tight
scope, and the approval gate before the portal upload.

## Inventive-catalyst reviewer (C)

Verdict: most of the design is balanced. The findings are places where the
spec accepts a limit that a known pattern removes.

| ID | Severity | Scope | False compromise and resolution |
| --- | --- | --- | --- |
| C1 | Major | Claude hook (209 to 218), PR template | "A hook cannot run a skill" is accepted as final. But a `PreToolUse` hook can block the commit (exit code 2) and tell the agent to run `/ste80-humanizer` and `/simplify` first. Resolution: after the pass, write a stamp keyed to the hash of the staged tree. The hook blocks while no current stamp exists. Cost: the stamp proves the step ran, not that it ran well. Each commit takes one more round trip. The stamp logic needs a test. |
| C2 | Major | Git hook and Claude hook | Both hooks run `make fast`, and the changelog rule runs only in the Claude hook, so human commits skip it. Resolution: the git hook owns every fixed check, including the changelog rule. The Claude hook checks that `core.hooksPath` is set (and runs `make setup` if not), then handles only C1. Cost: `--no-verify` skips the gate, with CI as the backstop. |
| C3 | Major | `.factorio-version` (182 to 184), ingame job | Keeping version moves deliberate does not mean nobody should be told about a new version. Steam updates the user's game, so it will run ahead of the version CI tests, and nothing will say so. Resolution: a weekly job reads Factorio's latest-release data and opens a PR or issue when a newer stable headless version exists. A human still merges it. Cost: the endpoint is unofficial and can change, so the job must fail loudly and must not open duplicates. |
| C4 | Major | Releases step 1 | Hattorio's `release.yml` copies the Lua and luacheck setup by hand, and its paths drift. On a tag push, `commits.py` and the changelog rule have no PR range or diff, and the spec does not say what they do then. Resolution: `check.yml` takes `workflow_call`, `release.yml` calls it first, and PR-only checks run on a condition. Cost: nested logs, explicit inputs and secrets, and cache keys that work for both triggers. |
| C5 | Nit | Commits, CI job 3 | A bad commit message shows up only in CI, and the fix is a history rewrite. Resolution: a `.githooks/commit-msg` hook runs `commits.py` on the message, with CI as the backstop. Cost: `commits.py` needs a single-message mode and must allow merge and revert messages. |
| C6 | Nit | `make fast`, 10-second budget, parity rule (90 to 91) | Full-tree scans will become slow as the repo grows. Resolution: each file-level check takes an optional file list (`make fast FILES=...`). Hooks pass the staged files and CI passes none. Cost: checks across files (changelog rule, docs-against-code, cspell dictionary) still run in full. |
| C7 | Nit | `links.yml` (142 to 143) | A link that stays broken opens a new issue every week. Resolution: update one open issue with a fixed label, and close it when the run passes. Cost: needs `issues: write`. |

Not verified, outside the catalyst's lens: the spec does not say where
`factorio-test` 3.2.0 comes from. A mod portal download usually needs a
username and token. Then the `ingame` job needs a secret and fails on fork
PRs. Pinning and caching it from its source release would avoid this.
