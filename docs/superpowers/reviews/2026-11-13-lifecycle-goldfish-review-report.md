# Goldfish Annotated Review Report

Status: resolved. The maintainer chose auto accept on 2026-11-13. F1 to
F20 are applied. E1 is recorded as an open question in the spec and in
`docs/design.md`. C1 and the declined nits are not applied.

**Target:** `docs/superpowers/plans/2026-11-13-lifecycle.md` (full file),
with one matching edit to the spec. Stage 9, round 1.

The findings are grouped by issue. IDs refer to the Stage 9 report.

## Escalated

### E1. Do loot eggs ever hatch? (Elephant note, from K1 and R4)

- **Scope:** Task 1 Step 6, Task 6 ground test, spec Nest loot.
- **Description:** Nest loot is always 1 to 3 eggs, below the ratio
  of 10. With full stacks on the ground, the probe's answer to Q3 decides it:
  if a stack below 10 gives no event, loot eggs never hatch. If it gives
  one, every loot pile hatches one monster.
- **Suggestion:** ESCALATE. This is a gameplay choice. The plan keeps the
  current design until the probe answers Q3, then asks the maintainer.

## Proposed fixes

### F1. Blocker: spill full stacks (K1)

- **Scope:** Task 1 (Q1 test), Task 6 (ground test), Task 8 (loot shell).
- **Change:** add `drop_full_stack = true` to every `spill_item_stack`
  call. The ground test also asserts that it found exactly one
  item-on-ground entity.

### F2. Major: one task order (R1, K3, T2)

- **Change:** swap Tasks 4 and 5, so the numbers follow the order of
  work: Task 4 is the data-stage shell (PR 1), Task 5 is the hatch pick
  (PR 2). Update the PR table, the cross-references and the Interfaces
  blocks. Replace "Tasks 2 to 5 form PR 1" with "Tasks 2, 3 and 4 form
  PR 1, with one commit at the end of Task 4". Drop the coverage reason.

### F3. Major: lines over 100 characters (R2, K2)

- **Change:** wrap the six lines in the plan's code.

### F4. Major: the locale text and the -ing rule (R3)

- **Change:** add
  `ing-form | locale/en/locale.cfg | breeding | the name of the breeding pod`
  to `.ste-allow`, and list `.ste-allow` in the files and the staging
  list of the PR 1 task.

### F5. Major: a rule for each probe outcome (R4, T5, T13)

- **Change:** replace the bullet list in Task 1 Step 6 with a table:
   - No position for a chest, or none for the ground: finish PR 1, tell
     the maintainer, and stop before PR 2.
   - A full stack of 10 on the ground gives one event: the ground test
     expects 1.
   - A stack of 9 gives no event: tell the maintainer that loot eggs never
     hatch (E1). Keeping it needs no plan change. A random hatch per egg
     means stopping to re-plan.
   - A stack of 9 gives one event: tell the maintainer that each loot pile
     hatches one monster (E1).

### F6. Major: the research prerequisites (K4, R7)

- **Change:** prerequisites `{ "military-science-pack",
  "chemical-science-pack" }` in the plan and in the spec. Add a unit test
  that lists them.

### F7. Major: `auto_recycle = false` (K5)

- **Change:** add `auto_recycle = false` to the breeding and adopt
  recipes, assert it in the flags test, and add it to the spec's Recipes
  section.

### F8. Major: an arena for in-game tests (K6, R14)

- **Change:** add `Helpers.arena(surface, position)`, which generates the
  chunks around the position and destroys enemy entities there. Every
  in-game test calls it first. The pod tests research Monster husbandry
  before `set_recipe`.

### F9. Major: wording of the Goal, the probe and cross-references

Findings: T1, T3, R9, K8, T4, T6.

- **Change:** the Goal from T1. "five" probe questions. Q5 records "the
  number of events and the test time (not frame time)". Cross-references
  name the right task and step.

### F10. Major: the balance constraint (T7, R6, K9)

- **Change:** narrow the constraint to "every balance number". Move the
  pod's stack size, pollution and mining time into `Balance.pod`.

### F11. Major: the pole sentence (T8, R5, K11)

- **Change:** delete it. The layout already works.

### F12. Major: the architecture claim (T9)

- **Change:** name what the architecture test checks, and say that the
  builder's busted run catches reads of `data`, `mods` or `settings`.

### F13. Nit: Task 0 (R10, K7)

- **Change:** Step 1 commits only the edits from this review. Drop the
  `no-changelog` label step.

### F14. Nit: early return in the hatch handler (R11, K14)

- **Change:** return before `random()` when the effect ID belongs to no
  species.

### F15. Nit: the `control.lua` header and the spoil helper (R12, K10, T20)

- **Change:** give the new header text, and the `spoil_percent` variant
  of `Helpers.spoil`.

### F16. Nit: exact text for the doc edits (R13, T23)

- **Change:** give the final Markdown for the ROADMAP, CHANGELOG and
  `docs/design.md` edits, wrapped at 80 characters.

### F17. Nit: require paths in tests (K12)

- **Change:** `require("core.species")` in the in-game tests.

### F18. Nit: the locale test (K13)

- **Change:** put the coverage test in `spec/locale_spec.lua`.

### F19. Nit: loot that a player picks up by walking (K15)

- **Change:** add `enable_looted = true` to the loot spill, as vanilla
  loot does.

### F20. Nit: comment length and column name (R8, T11, T19)

- **Change:** split the comment in `core/hatching.lua`. Rename the column
  to "`/simplify` reviewers". Define "both modes" once in Global
  Constraints.

## Contested

### C1. T10: maintainer approval before each merge

- **Suggestion:** CONTEST. `CLAUDE.md`, Workflow step 5, says: "When
  `all-checks` passes, squash merge the PR." The plan follows it.

## Declined

T12, T14 to T18, T21 and T22: wording nits in comments and terms that do
not change what an executor does.
