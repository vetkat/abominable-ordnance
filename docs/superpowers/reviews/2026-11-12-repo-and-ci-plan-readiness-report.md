# Stage 9: Implementation Readiness, round 1

Target: `docs/superpowers/plans/2026-11-12-repo-and-ci.md` as of commit
ab6f0ca, the whole file. Context: the spec, `docs/architecture.md`,
`CLAUDE.md`, `.mdl-style.rb`, `tools/vendor/` and the humanizer checker.

Reviewers, all completed: `egm-implementation-readiness` (I),
`egm-codebase-details` (C) and `egm-style` (S). The maintainer was away,
so the main session resolved the findings on its own: it applied each
PROPOSE FIX and recorded each CONTEST and DECLINE below.

Two reviewers traced every pytest and busted test against its code and
found that each one passes as written.

## Resolution

| Finding | Raised by | Decision | What changed |
| --- | --- | --- | --- |
| The vendored `factorio-test` zip is never committed, so CI's `ingame` job fails | I-B1, C-B1, S-B1 | PROPOSE FIX | Task 13 commits the zip. The File map lists it. |
| `luacheck .` lints the Lua trees that the leafo actions install in the workspace | I-M1, C-B2 | PROPOSE FIX | `exclude_files` adds `.lua`, `.luarocks`, `.install` and `docs/archive`. |
| No step installs the tools before a task needs them | I-M2, C-M4 | PROPOSE FIX | New Task 0 checks every tool and gives the install command. |
| The 10-second rule for `make fast` is deferred, not decided | I-M3, S-M6 | PROPOSE FIX | Task 15 Step 5 adds the staged-files variant when the measured time is over 10 seconds. |
| The Claude hook misses multi-line commands, pathspecs, `-i` and `-o`, and `git add` inside a message | I-M4, C-M2 | PROPOSE FIX | `review_stamp.py` reads the commit's arguments with `shlex`. New tests cover each form. |
| The Makefile exports `LUA_PATH` and `LUA_CPATH`, which the Lua 5.4 luacheck also reads | C-M1 | PROPOSE FIX | It exports `LUA_PATH_5_2` and `LUA_CPATH_5_2`. |
| The planted mistake in Task 22 does not name a file | I-N7, C-M3, S-M11 | PROPOSE FIX | `core/planted.lua` with `return {}`, and the jobs that fail. |
| The commit blocks of Tasks 16 to 21 skip the review skills and run as one command | S-M3 | PROPOSE FIX | A Global Constraint and each block give the order and separate commands. |
| `BUSTED` is a placeholder inside runnable blocks | S-M12 | PROPOSE FIX | Task 0 defines a shell variable `$BUSTED`. |
| The failure log and the hand-back are not defined | S-M4 | PROPOSE FIX | The plan defines an attempt and names the maintainer. |
| Task 2's notes have no destination | S-M5, I-N8 | PROPOSE FIX | The ledger holds them. Task 14 says which findings get fixed and which get an entry. |
| Spec deviations are not recorded (mod code, staged files) | S-M6, S-M13, C-N4, I-N2 | PROPOSE FIX | Global Constraints list them. |
| `CLAUDE.md`: replace or merge? | S-M7 | PROPOSE FIX | "Replace the whole file." |
| File lists disagree with the steps (Tasks 9, 11, 17, 22) | S-M8, S-M9, C-N2, I-N4 | PROPOSE FIX | Lists corrected. |
| Task 22 Step 4 mixes two procedures | S-M10 | PROPOSE FIX | Before protection: direct pushes. After: PRs. |
| Task 3 does not say what happens to other "2.0" mentions | S-M14 | PROPOSE FIX | Recorded: the file had no other mention. |
| Task 10 gives no action when the planted file passes | S-M15 | PROPOSE FIX | Anchor the pattern, run again, hand back if it still passes. |
| Task 18 Step 7 packages before staging | S-M1 | PROPOSE FIX | Stage first. |
| Task 17 Step 6 checks before staging | S-M2 | PROPOSE FIX | Stage first. |
| The GitHub Action tags are not checked | I-M5, C-N10 | CONTEST | The main session looked up each tag on 2026-11-12 with `gh api .../releases/latest`: checkout v7.0.1, setup-python v7.1.0, setup-node v7.1.0, cache v6.1.0, upload-artifact v7.0.2, download-artifact v8.0.2, gh-actions-lua v13.1.0, gh-actions-luarocks v6.1.1. Task 20 records this. |
| The blob hash of `ste_check.py` is not checked | C-N10 | CONTEST | Checked on 2026-11-12: `gh api .../contents/scripts/ste_check.py` and `git hash-object` both give `1ddf0440...`. |
| The Arch busted path has the package version | I-N1 | PROPOSE FIX | The Makefile uses a wildcard. |
| `.luacov` include pattern is not anchored | I-N3, C-N9 | PROPOSE FIX | `^%.?/?core/`. |
| `.luacheckrc` drops `table` and has no entries for future stage files | C-N3 | PROPOSE FIX | Added. |
| cspell may skip dot-folders | C-N1 | PROPOSE FIX | `--dot`. |
| Absolute paths on the text check's command line | C-N7 | PROPOSE FIX | `main` makes them relative to the repository. |
| The `labeled` test is weak | C-N8 | PROPOSE FIX | The test matches the whole `types` list. |
| The cache path can drift from the workflow | C-N9 | PROPOSE FIX | check.yml sets `FACTORIO_CACHE`. |
| `gh run list` can find no run, or an old one | I-N6, C-N9 | PROPOSE FIX | Filter by branch and event, and wait. |
| The release run ID is a placeholder | I-N10, S-N9 | PROPOSE FIX | The command that gets it. |
| Hash mismatch has no action | I-N5 | PROPOSE FIX | Fetch the file from the upstream commit. |
| README Status and Install text left to the implementer | I-N9 | PROPOSE FIX | Exact text given. |
| Task 1 Step 3 count has nothing to compare with | I-N8, S-N3 | DECLINE | Task 1 is done. Its PDF has 14 sections and `docs/design.md` has them all. |
| Shell functions crash on missing files | C-N6 | DECLINE | The functional-core rules ask for a total core. The shells stay thin and may fail loudly. Cost if wrong: a traceback in place of a message. |
| `markdown_prose` fence handling differs from the checker | C-N5 | DECLINE | Nested fences do not occur in this repository. |
| Wording nits (S-N1, N2, N4 to N9) | S | PROPOSE FIX where cheap | Fixed the wrong task pairing (S-N6), the dry-run check (S-N7) and the vague steps in S-N9. The rest stays. |

No second round: the fixes do not change the plan's design, and the
executor's TDD runs check every code change.
