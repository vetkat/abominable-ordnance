# Stage 7: Critic Review, round 1

Target: `docs/superpowers/specs/2026-11-12-repo-and-ci-design.md` as of
commit dd3ab51, lines 1 to 267. Later edits moved the lines.
Goldfish context as in Stage 5.

Reviewers, all completed:

- `egm-design` (D), against the feature-spec standard: 2 Blockers, 9 Majors,
  10 Nits.
- `egm-structural` (S), against the feature-spec standard: 1 Blocker,
  6 Majors, 7 Nits.
- `egm-style` (T), no standard: 10 Majors, 13 Nits.

Findings that several reviewers raised are merged below. The IDs show who
raised each one. Labels from earlier stages (Z, C, U) refer to
`zoom_out_report.md` and `comprehension_report.md`.

## Blockers

| ID | Raised by | Scope | Finding |
| --- | --- | --- | --- |
| R1 | D-B1, S-1 | Decisions (29 to 48), whole document | No Alternatives Considered section. The standard fails a spec that gives one path without rejected options and reasons. Obvious candidates: mdl against markdownlint-cli2, generated `changelog.txt` against Hattorio's hand-edited one, factorio-test against a plain load test, vendored `ste_check.py` against a pinned dependency, Claude hook against the git hook alone, duplicated release checks against `workflow_call`, manual versions against release-please. |
| R2 | D-B2, S-2 | Whole document | No Risks and Mitigations section. Missing at least: external downloads (headless server, factorio-test) failing or changing, the `FACTORIO_API_KEY` secret and fork PRs, the vendored checker as copied code that CI runs, local tool versions drifting from CI, false positives from the text checker, the `make fast` budget, and hooks that `--no-verify` or a reworded command can bypass. |

## Majors

| ID | Raised by | Scope | Finding |
| --- | --- | --- | --- |
| R3 | D-M1 (also U7) | 96, 153 to 154, 167, 197, 250, 260 | `check_version.py` cannot pass in the state this project leaves. `make fast` runs it on every commit, the version stays 0.1.0 under `Unreleased`, and the check wants a dated section. The dry run has no tag. Define the rule for commits, for releases and for the dry run, with tests for each. |
| R4 | D-M2 | 37, 60, 96, 99, 155 | Is `changelog.txt` committed? Line 37 says it is generated at build time; line 60 checks that "they match". Also say how `Unreleased` maps to Factorio's format, which needs a `Version:` line. |
| R5 | D-M3 (also C, Stage 5) | 23 to 24, 43, 98, 134 | How factorio-test reaches the server is not specified. Portal downloads need a token, the usual runner is a Node CLI that the toolchain does not list, and the version is not pinned. With a token, fork and Dependabot PRs fail the required `ingame` check. |
| R6 | D-M4 | 36, 44, 132, 145 | Dependabot's default messages ("Bump x from 4 to 5") fail `commits.py`, so every Dependabot PR is blocked. Set a `ci` prefix in `dependabot.yml` or exempt the bot. |
| R7 | D-M5 (also Z2, C2, U6) | 137 to 140, 206 to 213 | The changelog rule differs by place. In CI it is per PR and the `no-changelog` label skips it. In the Claude hook it is per commit with no skip, which conflicts with small TDD commits. The git hook does not run it. |
| R8 | D-M6, S-3, T-M4 (also Z1, U11) | 88 to 101, 125 to 135 | "Every gate runs these targets" is not backed. CI jobs list tools, `commits.py` and the changelog rule are in no target, and no tool versions are pinned (`make setup` installs nothing). The 10-second budget is not measured (T-M5). |
| R9 | D-M7, S-7 | 52 to 86, 99 | The layout is incomplete as a scaffolding checklist. Hattorio's `package.py` exits on missing `SHIP` entries that this mod lacks. `core/` must ship but the spec does not say so. An empty `core/` is not tracked by git. `tools/tests/`, `thumbnail.png`, `.gitignore` and `build/` are missing. Lines 72 to 79 change the list format. |
| R10 | D-M8, T-M3 (also Z6, C4) | 149 to 164 | "Works as in Hattorio" is wrong in four places: release notes, which checks run again, the dated-section rule, and required approval. A `mod-portal` reviewer is optional in Hattorio, so without it a tag publishes automatically. Permissions are workflow-wide, and nothing checks that the tag is on `main`. Hattorio's `check-credentials` mode is not mentioned. |
| R11 | D-M9, T-M1 | 107, 115 to 116 | The spec fails its own text check: "color" and "behavior" are in plain quotes, not code spans. Also say whether specs and plans fall under the text check. |
| R12 | S-4, T-M8 (also U1, U2, U3, U8) | 38, 83, 149, 188, 191, 202, 224, 230, 266 | Outside names with no link or path: Hattorio, functional-core, the PDF design doc, EGM, superpowers, Keep a Changelog, Conventional Commits, factorio-test. |
| R13 | S-5, D-N7, T-N4 (also Z11, U4) | 57, 243 to 261 | "Each gate fails on a planted mistake", but the list leaves out cspell, luacheck, the coverage floor, lychee, locale text, `.ste-allow`, the Claude hook and the 99-dash separator. The "invariants" that `math.random` relies on are never listed. No release step loads the dry-run zip in the headless server, though check 4 says it does. |
| R14 | S-6, D-N9 | 6 to 13 | Purpose says what is built, not why gates come before features or what goes wrong without them. No explicit Goals list (S-10). |
| R15 | T-M2 | 163, 184, 248 | "Prove" overclaims. The dry run checks steps 1 to 3 only. CI shows the gates pass on a new version; it does not prove the move is right. Line 248 should say "acceptance criteria". |
| R16 | T-M6 (also U15) | 12, 55, 164, 168, 193, 265 | "Design Version 1", "mod version 1" and release numbers mix. Define one term early. |
| R17 | T-M7 (also U17) | 4, 17, 41, 85, 159, 195 | "The user" reads as a player in a mod repo. "The agent" is never defined. "We" adds a third voice. Name the roles once. |
| R18 | T-M9 (also U12) | 121 to 123 | The `.ste-allow` format is ambiguous. State the fields and syntax. A file-only entry would turn off every rule (D-N5). |
| R19 | T-M10, S-12 (also U14) | 179 to 180 | "Starts with exactly 99 dashes on each entry" mixes the file's first line with every entry. Hattorio checks only the first line. |

## Nits

| ID | Raised by | Scope | Finding |
| --- | --- | --- | --- |
| R20 | D-N1 | 127, 134 | A matrix job gives one check name per entry, so "all four" required jobs means five or more names. Use an aggregator job. |
| R21 | D-N2 | 127, 132 | `commits.py` and the changelog rule need a PR context; say what they do on push. Merge commits fail `commits.py`, so state the merge strategy (squash?). |
| R22 | D-N3 | 261 | Admins bypass branch protection unless "Do not allow bypassing" is set. Check 5 fails for the owner otherwise. |
| R23 | D-N4 | 21, 98 | No download URL or SHA-256 for the headless server. |
| R24 | D-N5 | 67 | Record the vendored checker's upstream commit in `THIRD_PARTY.md`. |
| R25 | D-N6, S-14, T-N1 | 17 to 27 | Facts have no sources or dates ("as of 2026-11-12"). |
| R26 | D-N8 | 138 to 139 | The mod-code list leaves out `graphics/` and `thumbnail.png`. `prototypes/` and `settings*.lua` are not in the layout (U16). |
| R27 | D-N10 (also C7) | 142 to 143 | `links.yml` needs `issues: write` and must not open a new issue every week. |
| R28 | S-8 | 137, 166, 170, 206, 209 | Bold run-in labels act as subsections. Make them H3s and use one label style. |
| R29 | S-9 | 182 to 184 | `.factorio-version` is under Releases but controls `make ingame` and CI. Move it. |
| R30 | S-11 | 93 to 99 | The "Who runs it" column mixes actors and times. |
| R31 | S-13, T-N9 | 151, 162 | The dry run is not started by a tag, so "steps 1 to 3" needs a note. Put `dry-run` in a code span. |
| R32 | T-N2 | 191 to 192 | "Finished and updated for 2.1" has no completion test. `architecture.md` is still titled "Factorio 2.0 mods". |
| R33 | T-N3 | 228 | "Significant change" is subjective; point to the mod-code rule. |
| R34 | T-N5, T-N6 (also U13) | 252, 254 | "A dash" should be "an em or en dash". "A broken `mdl` rule" should be "a file that breaks an `mdl` rule". |
| R35 | T-N7, T-N8 | various | Term drift: American/US spelling, Claude hook/Claude Code hook, repo/repository, text/prose, gate/check. Skill names are formatted two ways. |
| R36 | T-N10 to T-N13 | 46, 210, 218, 225, 245 | Wording: "as far as it goes", "the tools too", "does these steps", "built test first", and "the repo is the source of truth" (for what?). |

## Elephant notes

- **Contest candidate.** T-M1 calls "humanizer" an American spelling. It is
  the name of the tool (`ste80-humanizer`), so the fix is to write the tool
  name in code where it is meant, not to change the spelling.
- **Against user decisions.** R1 asks for a rejected option per choice. Some
  choices were the user's own (mdl over markdownlint-cli, Keep a Changelog).
  The reason to record is "the user's choice", plus any reason the user gave
  (for mdl: chosen even though markdownlint-cli was already installed).
- **Biggest real problems.** R3 (version check with no tag), R5
  (factorio-test install and secrets), R6 (Dependabot against `commits.py`),
  R7 (changelog rule) and R10 (portal publishes without a required reviewer)
  would each break CI or a release. The rest is documentation.
