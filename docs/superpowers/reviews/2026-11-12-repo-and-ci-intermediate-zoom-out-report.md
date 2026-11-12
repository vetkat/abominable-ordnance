# Stage 8: Intermediate Zoom Out Review

Target: `docs/superpowers/specs/2026-11-12-repo-and-ci-design.md` as of
commit dd3ab51, lines 1 to 267. Later edits moved the lines.
It has not changed since Stage 5. The reviewer (`egm-zoom-out`) read the
spec, the three earlier reports and the Stage 5 context files.

## Verdict

Still passes with changes. There is no new Blocker from a simplicity view.

Four of the five bugs that Stage 7 called the biggest come from machinery
that Stage 5 already called optional:

| Stage 7 bug | Comes from |
| --- | --- |
| R6 (Dependabot against `commits.py`), R21 (push and merge commits) | Z3: `commits.py` |
| R4 (is `changelog.txt` committed, how `Unreleased` maps), part of R3 | Z4: the Keep a Changelog generator |
| R7 (the changelog rule differs by place) | Z2: two hooks |
| R10 (publish without a required reviewer), the secret in R2 | Z8: a publish job before anything is published |

R5 (how factorio-test is installed) is the fifth bug. It does not come from
extra machinery.

The cheapest fix for each is to remove or narrow the machinery, not to add
text that explains it. If the spec took every Stage 6 and 7 request
literally, it would grow by about half. Most of that belongs in the
implementation plan. Moving the Z12 content (CLAUDE.md rule list, PR
template, changelog mapping table) to the plan at the same time keeps the
spec's growth small.

## Findings

| ID | Severity | Covers | Take on in the spec |
| --- | --- | --- | --- |
| F1 | Major | R1 | A short "Why" column in the Decisions table, not a full Alternatives section. Only four choices are contested: Keep a Changelog against a hand-edited `changelog.txt`, mdl against markdownlint, factorio-test against a plain load test, the Claude hook against the git hook alone. "The user's choice" is a valid reason. Do not list review suggestions as options the user rejected. |
| F2 | Major | R2 | At most four risk lines: downloads are pinned and cached; hooks can be bypassed and CI is the backstop; text-check false positives go in `.ste-allow`; the vendored checker is pinned to an upstream commit. The other risks go away with F4, F7 and Z2. |
| F3 | Major | R3, R4, U7 | Hattorio's `check_version.py` already makes the tag optional. One sentence: without a tag, `info.json` must match the newest `CHANGELOG.md` section and `Unreleased` is allowed; with a tag, the section must be dated. `changelog.py` turns `Unreleased` into `Version: <info.json version>`. Simplest: `changelog.txt` is a build artefact, never committed, so the "they match" check goes. |
| F4 | Major | R5 | One Decisions row: factorio-test comes from a source that needs no token, at a pinned version next to `.factorio-version`, cached like the server. Rule: no secret in `check.yml`. Runner, flags and cache keys go in the plan. |
| F5 | Major | R6, R21, Z3 | One decision: squash merge; the PR title is the commit message, and CI checks it. `dependabot.yml` sets `commit-message.prefix: ci`. Then `commits.py` needs no push mode and no merge-message handling. Or drop it (Z3). |
| F6 | Major | R7, Z2, C2, U6 | The changelog rule runs per PR in CI only, with the `no-changelog` label. The Claude hook only prints the reminder. No local per-commit variant. |
| F7 | Major | R10, Z8 (now Major) | Either (a) leave the `publish` job and `publish_mod.sh` out until mod version 1, or (b) keep them with two rules: `mod-portal` has a required reviewer, and a tag that is not on `main` fails. In both cases, replace "works as in Hattorio" with the actual steps. |
| F8 | Major | R12, U1 to U3, U8, U9 | No glossary section. One link or clause where each name first appears. Give the PDF's path. Most EGM and superpowers names sit in the CLAUDE.md section, which moves to the plan (Z12). |
| F9 | Major | R8, Z1 | Do not pin every tool. One sentence: CI pins Lua, Factorio and factorio-test; other tools float, and CI is the source of truth. One Make target per CI job (Z1). Say that PR-only checks sit outside Make. |
| F10 | Nit | R13, Z11 | Replace the planted-mistake bullets with "each gate has a test that fails on a planted mistake". Keep only the two that carry an architecture rule: `math.random` in `core/`, and a game-API name in `core/`. Point to `docs/architecture.md` for the invariants. Check 4 (load the dry-run zip) is a one-time manual check. |
| F11 | Nit | R27, C7 | `links.yml` fails, and that is all. GitHub already notifies the owner. Drop "opens an issue" and `issues: write`. |
| F12 | Nit | Layout, 72 to 76 | `CLAUDE.md`, `.mdlrc`, `.mdl-style.rb` and `docs/architecture.md` already exist. Say they are kept or edited, not created. |
| F13 | Nit | R9, R18, R20, R22 to R24, R26, R29, R30 | Plan content, not spec content. Keep one design rule from R18: a `.ste-allow` entry names a rule, so a file-only entry cannot turn off every rule. |
| F14 | Nit | R11, R14 to R17, R19, R25, R28, R31, R33 to R36 | Cheap wording edits. Take them on as they are. |

## Effect on the Stage 5 findings

| Finding | Change |
| --- | --- |
| Z3 | Strengthened by R6 and R21. |
| Z8 | Raised from Nit to Major. |
| Z2, Z1 | Confirmed by R7 and R8. |
| Z4 | Its cost is now concrete (F3). The decision stays with the user. |
| Z12 | Worth more now: moving that content offsets the new text. |

## Elephant notes: decisions for the user

The edits mostly follow from the findings. These points need the user:

1. **Commit format (F5).** Squash merge with a PR-title check, keep
   `commits.py` on every commit, or drop the check.
2. **Publish job (F7).** Leave it out until mod version 1, or keep it with a
   required reviewer and a `main`-only tag rule.
3. **`changelog.txt` (F3).** Build artefact only, never committed.
   Keep a Changelog stays.
4. **Claude hook (F6 against C1).** Reminder only, or block the commit until
   the humanizer and `/simplify` have run (the stamp idea from C1).
5. **New Factorio versions (C3).** Add a weekly job that reports a newer
   stable version, or leave version moves fully manual.
6. **`links.yml` (F11).** Fail only, or open one issue that it keeps up to
   date.
