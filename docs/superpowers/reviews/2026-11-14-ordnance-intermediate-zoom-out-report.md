# Stage 8: Intermediate Zoom Out Review

Target: `docs/superpowers/specs/2026-11-14-ordnance-design.md`, the whole
file. The spec did not change after Stage 5.

Goldfish context: `docs/design.md`, `docs/architecture.md`, the slice 1
spec and the reports of Stages 5, 6 and 7.

Status: the agent applied the "act now" items to the draft on
2026-11-14. The maintainer decides I5 and I6.

Reviewer: `egm-zoom-out`. Verdict: changes requested. No Blocker from the
zoom-out view. 6 Major, 4 Nit.

The reviewer confirmed in the code that `control.lua` has one
`on_entity_died` registration and no `on_init` yet, and that the
prototype helpers in `core/prototypes/lifecycle.lua` are all local.

## The main risk is length

Stages 5 to 7 ask for about 60 changes. The rule: the spec takes a
change only if it states behaviour, a rule or a decision. File layout,
helper names, numbers and guards go to the plan. New sections replace
prose, not add to it.

## Findings

- **I1. Major.** Act now: a Probe section with a stop rule, as in
  slice 1, then a short Risks table. The probe covers spoilage in an
  inventory, a chest and on a belt, an idle unit made by the script, a
  projectile made at its own target, and cloud and puddle damage by
  force. Testing gets the five missing tests and the unit and in-game
  split.
- **I2. Major.** Act now: "Runtime behaviour" with numbered steps for
  the larva hatch, loaded hatch, death, acid effect and force setup. It
  holds one `on_entity_died` handler with both filters, the spawn routine
  (a command and AI settings), `force` and `cause` on every effect
  entity, and the handler that removes the `storage` entry. Cut the
  Architecture table to file names.
- **I3. Major.** Act now, in one sentence: the mod creates the force and
  sets cease-fire both ways in `on_init` and `on_configuration_changed`,
  and for each new force in `on_force_created`.
- **I4. Major.** Act now: "Changes to `docs/design.md` and `ROADMAP.md`"
  as a short numbered list. Drop or mark the "no such smoke" claim.
- **I5. Major.** The maintainer decides (new Q8): nests that `ao-tamed`
  kills drop no eggs, because the research gate reads the killer's
  force.
- **I6. Major.** The maintainer decides these changes to Q1 to Q7: Q2
  (one tinted unit per species and size), Q6 (throwable capsule now), Q5
  (incubator recipe in the breeding pod), Q4 (split AI targets from blast
  damage), Q7 (return the empty barrel, `fluid-handling`, and a Decisions
  row), Q1 (ask as eggs per round), Q3 (define "payload cap" or drop it).
- **I7. Nit.** Act now: drop `size` unless the spec says what it
  changes, and store payloads as a list.
- **I8. Nit.** Act now: one sentence under the Decisions table on the
  status of the rows.
- **I9. Nit.** Act now: one sentence on the gap between PR 2 and PR 3.
- **I10. Nit.** Act now: give the slice 1 path and define the egg ratio,
  say "acid trail", narrow `auto_recycle` to the incubate and load
  recipes, and say whether a larva on a platform is used up.

## Triage

| Act now | Move to the plan | Decline | Maintainer decides |
| --- | --- | --- | --- |
| I1, I2, I3, I4, I7, I8, I9, I10 | ZO-02 (shared helpers, owner of Monster husbandry), S5, the numbers of S6, D10, ZO-11, IC-7, `on_forces_merged`, N7 | S6 subsections, N1, the 64-force note, IC-9, S15, C10, C11, the bulk of the style nits | I5 (Q8), and I6 for Q1 to Q7 |
