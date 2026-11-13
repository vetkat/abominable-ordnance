# Stage 9: Implementation Readiness Test, round 1

Target: `docs/superpowers/plans/2026-11-13-lifecycle.md` as of commit
3c60414 (the whole file).

Goldfish context: the lifecycle spec, `docs/design.md`,
`docs/architecture.md`, the repository and the Factorio 2.1.24 data files.

| Reviewer | Standard | Status | Verdict |
| --- | --- | --- | --- |
| `egm-implementation-readiness` | implementation-readiness-standard | completed | Not ready: 4 Major, 10 Nit |
| `egm-codebase-details` | implementation-readiness-standard | completed | Not ready: 1 Blocker, 5 Major, 9 Nit |
| `egm-style` | persona rules | completed | Changes needed: 10 Major, 13 Nit |

The round is not clean.

## Elephant notes

These notes come from the main session. They are not reviewer findings.

- **Checked and true.** K1: the game changelog (2.0.48) adds
  `drop_full_stack` to `spill_item_stack`, and the original entry says it
  drops items "item bomb style". K5: `recycler/recycling.lua` line 175
  skips only recipes with `auto_recycle = false`.
- **Found by several reviewers.** Task order: R1, K3, T2. Line length:
  R2, K2. Probe count "six": R9, K8, T3. Numbers outside the balance
  module: R6, K9, T7. Pole sentence: R5, K11, T8. Early return in the
  hatch handler: R11, K14. `control.lua` header: R12, K10. Spoil helper
  variant: R12, T20. Task 0: R10, K7. Prerequisite: R7, K4.
- **Contested.** T10 asks for maintainer approval before each merge.
  CLAUDE.md says to squash merge the PR when `all-checks` passes. The
  rule in CLAUDE.md stands.
- **A design question for the maintainer.** Nest loot is always 1 to 3
  eggs, below the ratio of 10. With full stacks (K1), the probe's answer
  to Q3 decides whether loot eggs ever hatch.

## Implementation readiness findings (egm-implementation-readiness)

- R1. Major: the order of Task 4 contradicts itself, and Task 5 would
  stage `core/hatching.lua` into PR 1. Give one order: 0, 1, 2, 3, 5,
  then 4, 6, then 7, 8.
- R2. Major: six code lines exceed luacheck's 100 characters, so
  `make fast` fails.
- R3. Major: "Breeding pod" in `locale.cfg` fails the `ing-form` rule.
  Add a `.ste-allow` entry and stage it.
- R4. Major: the probe's fallback paths and the ground test's expected
  count are not planned for each outcome.
- R5. Nit: the pole sentence reads as an unconditional step.
- R6. Nit: numbers outside `core/balance.lua`.
- R7. Nit: no prerequisite unlocks military science.
- R8. Nit: a 30-word comment in `core/hatching.lua`.
- R9. Nit: "six" questions, and Q5 measures test time, not frame time.
- R10. Nit: Task 0's commit exists, and the label is not needed.
- R11. Nit: the hatch handler draws a random number for other mods'
  triggers.
- R12. Nit: the `control.lua` header, and the helper's second spoil
  variant.
- R13. Nit: the doc edits are summaries, not exact text.
- R14. Nit: tests call `set_recipe` before the research, and assume the
  test map has no nests.

## Codebase findings (egm-codebase-details)

- K1. Blocker: `spill_item_stack` drops one entity per item unless it
  gets `drop_full_stack = true`. The ground test, probe Q1 and nest loot
  rest on the wrong behaviour.
- K2. Major: same as R2.
- K3. Major: same as R1. The coverage reason for one commit per PR is
  also wrong: each task's own spec covers its module.
- K4. Major: the prerequisites should be `military-science-pack` and
  `chemical-science-pack`. `sulfur-processing` is redundant. The spec
  needs the same edit.
- K5. Major: the breeding and adopt recipes need `auto_recycle = false`.
  Without it, Space Age makes recycling recipes that turn eggs back into
  chow and `biter-egg`, and two recipes fight over one recycling name.
- K6. Major: the in-game tests build far from the origin on an unknown
  map. Add an arena helper that generates the chunks and clears enemies.
- K7. Nit: same as R10.
- K8. Nit: same as R9.
- K9. Nit: same as R6.
- K10. Nit: same as R12.
- K11. Nit: the given pole layout already works. Delete the sentence.
- K12. Nit: tests should use `require("core.species")`, like the shell.
- K13. Nit: put the locale coverage test in `spec/locale_spec.lua`.
- K14. Nit: same as R11.
- K15. Nit: add `enable_looted = true` to the loot spill, or say why not.

## Style findings (egm-style)

- T1. Major: the Goal has no main verb and says each egg hatches.
- T2. Major: same as R1.
- T3. Major: same as R9.
- T4. Major: Q5 records test time, not frame time.
- T5. Major: "stop the plan" contradicts "before PR 2".
- T6. Major: wrong task for `helpers.lua`, and unclear word order.
- T7. Major: same as R6.
- T8. Major: same as R5.
- T9. Major: "the first rule" has no clear referent.
- T10. Major: contested, see the Elephant notes.
- T11 to T23. Nits: the reviewer column name, absolute claims, unclear
  "it", comment wording, terms defined late, "both modes", the spoil
  helper variant, the headless-graphics claim, "nest" against
  "spawner", and the renamed ROADMAP item.
