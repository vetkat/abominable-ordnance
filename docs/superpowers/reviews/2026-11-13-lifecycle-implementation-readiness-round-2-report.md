# Stage 9: Implementation Readiness Test, round 2 (re-audit)

Status: resolved. The maintainer chose auto accept on 2026-11-13. Every
proposed fix is applied. R9 stays contested, and R7 and T14 are declined.

Target: `docs/superpowers/plans/2026-11-13-lifecycle.md` as of commit
7a01b75 (the whole file). This is the one re-audit that EGM allows.

| Reviewer | Status | Verdict |
| --- | --- | --- |
| `egm-implementation-readiness` | completed | Not ready: 6 Major, 6 Nit |
| `egm-codebase-details` | completed | Minor revisions: 3 Major, 4 Nit |
| `egm-style` | completed | Not ready: 7 Major, 7 Nit |

All reviewers confirm that the round 1 fixes are correct. No Blocker. The
round is not clean, because the fixes and a closer reading found new Major
gaps. All of them are small edits.

## Elephant notes

- **Found by several reviewers.** The shadowed `text` in the locale test:
  R1, K1. The probe without chunk generation: R5, K3. The probe outcome
  table: R6, T1. The missing red run in Task 4: R11, T5. The duplicate
  commit message: R10, K7, T10. The "no force" loot test: K5, T6. The
  place of `### Probe results`: K6, T11. The redundant table row: R12,
  T8.
- **Conflicting advice.** R9 wants absolute require paths in the in-game
  tests. Round 1 (K12) asked for `core.species`, and K2 of this round
  accepts it. Keep `core.species`.
- **The cap.** EGM allows one re-audit per stage. The open findings below
  are recorded for the maintainer.

## Major findings

| ID | Finding | Fix |
| --- | --- | --- |
| R1, K1 | The new locale test shadows the block's `text`, so luacheck fails. | Use the block's `text`. |
| K2 | The factorio-test list in `control.lua` grows past 100 characters. | Write the list one entry per line in Task 4, and add lines in Tasks 6 and 8. |
| R2, K4 | The comment "the pod's recipes are enabled" fails the passive rule. | "so it can use the pod's recipes". |
| R3 | "Slice 1 (lifecycle) is done." fails the passive rule. | "Slice 1 (lifecycle) ships in this release." Add the PR 3 roadmap line to the spec. |
| R4 | `make ingame` stops after the failing base run, so Q4 never runs. | Run `MODE=base` and `MODE=space-age` as separate commands. |
| R5, K3 | The probe does not generate its chunks. | Generate the chunks first, and report the number of ground entities. |
| R6, T1 | The probe table has no action for several outcomes. | Rows for: no event or many in a chest; no event or many on the ground; neither spoil call works; Q4 record only; Q5. |
| T2 | The spec still says the probe measures frame time. | Change the spec to "test time". Record "no time printed" if factorio-test prints none. |
| T3 | No point where the plan waits for the loot-egg answer. | Task 5 starts only after the maintainer answers. |
| T4 | The `Balance` fields are in Step 4, not Step 3, and are not only numbers. | Fix the reference and the type. |
| T5, R11 | Task 4 has no red run for the in-game content test. | Write the test before `data.lua` and run it to see it fail. |
| T6, K5 | The "no force" loot test may not reach the nil-force branch. | Narrow Review Focus 3 to "drops nothing when a spawner dies by `entity.die()`". |
| T7 | The PR routine has no path for a failed check. | Fix the cause on the same branch and push. Auto-merge stays on. |

## Nits

R7 (land tiles in the arena), R8 (two lines at exactly 100 characters),
R10, K7 and T10 (commit message), R12 (dump size), T8 (redundant row),
T9 (Q4 runs only with Space Age), T11 and K6 (place of probe results),
T12 (wait for the icon check before the commit), T13 (Task 8 uses
`Helpers`), T14 (tech description before loot exists).

## Resolution proposal

- **PROPOSE FIX:** every Major finding above, with the fix in its row.
  Also the nits R8 (wrap the two 100-character lines), R10, K7 and T10
  (a new commit message), R12 (dump only the count and the first event,
  and drop the redundant row), T9, T11 and K6, T12 and T13.
- **CONTEST:** R9. Round 1 (K12) set `require("core.species")` in the
  in-game tests, and K2 of this round confirms it resolves.
- **DECLINE:** R7 (land tiles in the arena: the tests have not failed on
  water, and the probe would show it) and T14 (the technology text names
  nest loot one PR early, and the spec accepts partial PRs).
