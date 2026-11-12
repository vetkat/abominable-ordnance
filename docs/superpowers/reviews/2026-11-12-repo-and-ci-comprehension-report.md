# Stage 6: Comprehension Test

Target: `docs/superpowers/specs/2026-11-12-repo-and-ci-design.md` as of
commit dd3ab51, lines 1 to 267. Later edits moved the lines.
The reviewer (`egm-comprehension`) read the document alone, with no
context files.

The reviewer could paraphrase every section, so there are no Blockers.

## What this proposes

The project builds the repository, tooling and quality checks for a Factorio
mod before the mod has any features. The goal is an empty mod that loads in
Factorio 2.1, with and without Space Age, while every check runs on it. The
checks are:

- Markdown lint, spelling and link checks.
- A prose "text check" for style, dashes and American spelling.
- Lua lint, unit tests and a coverage floor.
- Python tool tests.
- Version, changelog and commit-format checks.
- In-game tests on a headless Factorio server.

All of them run through Make targets. A git pre-commit hook and a Claude Code
hook run the fast subset locally. GitHub Actions runs the full set on every
push and PR, and `main` is protected. A release workflow, started by a tag,
builds the zip, makes a GitHub release and, after manual approval, uploads to
the mod portal. This project only proves the release workflow with a dry run,
leaves the version at 0.1.0 and publishes nothing.

## How the existing system works, per this document

The repository holds only this design so far. Several things already exist
outside it:

- **Hattorio:** another project, apparently an earlier mod by the same author.
  It already has a version checker, a packager, a portal upload script, a
  release workflow, Lua lint and test config, and a "docs against code" test
  pattern. All of these are adapted here. Its `factorio_version` still says
  "2.0".
- **A PDF design doc** for the mod. It will become `docs/design.md`.
- **Notes from "the functional-core work".** They will become
  `docs/architecture.md`.
- **An external humanizer checker** (`ste_check.py`). It is vendored into the
  repo.

Factorio 2.1.24 is current. Factorio 2.1 rejects mods marked "2.0". The free
headless server includes Space Age. `factorio-test` supports 2.1 from version
3.1.2.

## Findings

| ID | Severity | Scope | Finding |
| --- | --- | --- | --- |
| U1 | Major | "Hattorio" (lines 83 to 86, 149, 202, 266) | Never defined or linked. Six files are adapted from it and "`release.yml` works as in Hattorio", but a reader cannot tell what "adapt and do not copy as is" changes, apart from the `CHANGELOG.md` note. |
| U2 | Major | "functional-core skill" and "functional-core work" (38, 191, 224) | Never explained or linked. A reader cannot tell what `.mdl-style.rb` will hold, or what the "Factorio notes" are and where they live. |
| U3 | Major | Source of `docs/design.md` (12, 46, 188 to 190) | The PDF has no path. "Through the humanizer" could mean the `ste_check.py` checker (reports only) or the `/ste80-humanizer` skill (rewrites). |
| U4 | Major | Lua invariants and the `math.random` gate (57, 246, 258) | `spec/` holds "invariants", but none are listed. The reader must guess a "no randomness in core" rule, and no section says which gate (luacheck or busted) enforces it. |
| U5 | Major | "Docs against code" tests (57, 84) | Named, never described. Which docs are checked against which code, and what does a failure look like? |
| U6 | Major | Which changelog check runs where (96, 132 to 140, 206 to 212) | Three checks exist: the `changelog.txt` sync, `check_version.py` and the changelog rule. `make fast` names "version and changelog checks" without saying which. The Claude hook runs the rule "on the staged files" next to `make fast`, so the git hook seems not to enforce it. How does the `no-changelog` label work locally, where there is no PR? |
| U7 | Major | `check_version.py` with no tag (35, 96, 153 to 154, 162) | `make fast` runs it on every commit, and the dry run starts without a tag. What does it compare then? An unreleased 0.1.0 has no dated section, so the "dated section" rule would fail unless it is skipped outside releases. |
| U8 | Major | "EGM" (4, 47, 230 to 232, 241) | Never expanded or linked, nor are `/egm:egm-review` and `/egm:egm-drift-report`. It is a required step, but a reader cannot tell what it produces or what passing means. |
| U9 | Nit | Other tools and skills (71, 214 to 215, 225 to 231) | superpowers, `/simplify` and `/ste80-humanizer` are workflow steps with no description or link. |
| U10 | Nit | What `ste_check.py` checks (25 to 27, 113) | The spec does not say what the checker finds, so a reader cannot predict what `.ste-allow` entries will be needed. |
| U11 | Nit | Make targets against CI jobs (90 to 91, 127 to 135) | "Every gate runs these targets" conflicts with CI jobs that list tools one by one. Do the jobs call sub-targets or the tools? |
| U12 | Nit | `.ste-allow` format (121 to 123) | No syntax or example. Does a file entry exempt every rule for that file? |
| U13 | Nit | "A dash in a Markdown file" (252) | Line 114 bans em and en dashes only. "A dash" could include hyphens. Say "an em dash". |
| U14 | Nit | The 99-dash line (179 to 180) | "Starts with exactly 99 dashes on each entry" is hard to parse. It probably means each version block starts with a line of 99 dashes. |
| U15 | Nit | Version names (12, 55, 164, 168, 193) | "Design Version", "mod version 1" and release numbers are three schemes. The mapping (Design Version N becomes N.0.0) comes only at line 168. Define it near Purpose. |
| U16 | Nit | `prototypes/` and `settings*.lua` (139) | The changelog rule names them, but the repository layout does not. Say they are future paths. |
| U17 | Nit | "The agent" and "the user" (4, 17, 159, 195) | The spec assumes an AI agent works on the repo and one owner approves releases. One sentence on roles would help a human contributor. |

## Elephant notes

- U1 confirms the gap noted after Stage 5: "as in Hattorio" means nothing to a
  reader without Hattorio.
- U6 is the same problem as Z2 and C2 in `zoom_out_report.md`: the changelog
  rule runs only in the Claude hook.
- U11 is the same as Z1.
- U7 is new and real: `check_version.py` needs a mode without a tag, for
  `make fast` and the dry run.
