# Stage 8: Intermediate Zoom Out Review

Target: `docs/superpowers/specs/2026-11-13-lifecycle-design.md` as of
commit 592abfe, lines 1 to 294 (the whole file). The spec did not change
after Stage 5.

Goldfish context: `docs/design.md`, `docs/architecture.md` and the reports
of Stages 5, 6 and 7.

Reviewer: `egm-zoom-out`. Verdict: approve with changes. No Blocker from a
simplicity view.

## Elephant notes

These notes come from the main session. They are not reviewer findings.

- **Against a maintainer decision.** I9 drops the Space Age egg counts
  from the probe. The maintainer asked for that measurement on
  2026-11-13, after the wiki gave no ratio. It costs a few lines in a
  throwaway probe. It stays unless the maintainer drops it.
- **Two decisions for the maintainer before the plan.** I2 (a fixed
  species table, not a runtime read of the spawner) and I3 (move the
  incubator and larvae to slice 2).
- **I2 changes a stated reason.** The spec reads `result_units` at
  runtime so that other mods' spawner changes carry through. I2 drops
  that. Version 1 targets the base game and Space Age only, so the loss
  is small.

## Findings

### I1. Major: answer the alternatives Blocker in proportion

D1 and S1 are valid: the spec lost the trade-offs of the brainstorm. Add
one "Rejected" column to the Decisions table with a short phrase per row
that had a real alternative. Do not add a separate section. Act now.

### I2. Major: a fixed species table instead of the runtime read

Covers Z1, C2, D2, D5, D16, C4, C5, S10 and T9. Put one table per species
in a core module, with only that species' units and evolution points,
copied from the vanilla tables. `core/hatching.lua` interpolates over this
fixed data, so unit tests get exact values. The shell reads no prototype,
so the spawner guard and the cache go away. Loot and hatching share the
table. State the rule in one sentence: linear between neighbouring
points, clamped at both ends, weights normalised, cumulative pick on a
number in [0, 1). Act now.

### I3. Major: the incubator and larvae have no use and undo the ratio

Covers Z9, C3, D8, T23 and U17. Move the incubator, both larvae and both
incubate recipes to slice 2, where the loading chamber uses them. If they
stay, say why and state that a larva keeps its egg's freshness. In both
cases add "Machines in this slice have no module slots." This closes D8
and makes T4 moot. The maintainer decides.

### I4. Major: fix the rounding text, do not redesign

Covers C1, U3, D3, T5, T6 and Z3's reason. Keep `items_per_trigger = 10`.
The in-game test spoils 10 eggs. Risks row 3 states both outcomes:
rounding up hatches leftovers, rounding down leaves them inert. Row 2
says "a stack of 100 eggs". Delivery says which probe result blocks PR 2.
C1 is 10 times as many events, which makes D4 worse. Keep C1 as the
named fallback if the probe shows leftovers are lost. Text now, C1 to the
plan.

### I5. Major: pass the graphics in from `data.lua`

Covers Z2, D7 and T21. `data.lua` passes deep copies of the source
machine's graphics and working sound into the builder. busted passes
stubs. Risk row 4 goes away. Act now.

### I6. Major: decline the spoil-location matrix

D6. The probe covers a chest and the ground, because nest loot lies on
the ground. The spec gets one rule: with no usable surface or position,
nothing hatches. U5's field becomes something the probe records. One
sentence accepts hatching off Nauvis, as Space Age's `biter-egg` does.

### I7. Major: decline the per-tick queue

D4. Nothing shows a bottleneck, and 10:1 already cuts the triggers by
ten. The probe can spoil one large batch and note the frame time. No
queue and no new risk row.

### I8. Nit: decline the Risks restructure and the security statement

S3. The mod has no network, file or authentication surface. Determinism
is covered by the stored generator. Keep the table, minus row 4.

### I9. Nit: drop the Space Age egg counts from the probe

The mod's own 10-egg and under-10 cases answer the ratio question. Drop
the counts and the hedged wiki sentence (T8). Write "the probe measures",
not "confirms" (T10). See the Elephant note.

### I10. Nit: busted already proves the builder is pure

D15. Banning `data` would flag common local names. busted has no `data`,
`mods` or `settings` globals, so a builder that reads them fails its
tests. Reword the sentence. Do not change the architecture test.

### I11. Nit: shrink the item-name test

Z6 and D14. Limit it to this slice's names and the few outside names it
uses (`biter-egg`, `coal`, `sulfur`, `water`, `sulfuric-acid`), or drop
it. The locale test reuses `L.value` (Z7).

### I12. Nit: delete "Notes for version 2"

Z5, U4, S9 and T18. Music and pentapods stay in Out of scope.

### I13. Nit: list the changes to `docs/design.md`

D9. Four bullets: the spitter source, the base-game biter source, the
script trigger, and the pentapod correction. The edit itself is a PR 1
task.

### I14. Nit: batch of cheap wording fixes

- Split Delivery into "Probe" and "Pull requests". Refer to "the probe
  (see Probe below)". Covers C6, U1, D11, S4, T2 and S13.
- List the exact `pentapod-egg` flags in Facts (U2, T3, T4).
- Goal 3: "graphics and working sound" (U10, T1, D13).
- Define "wild" as "on the `enemy` force" (U9).
- Add the Chemical science pack technology as a prerequisite (D10).
- The balance module holds every number in this slice (T13).

### I15. Nit: decline proposals that reverse maintainer decisions

Z3 (no loot gate), Z8 (drop spitter chow) and Z10 (PR order), unless the
maintainer reopens them.

### I16. Nit: the remaining findings add length, not clarity

Decline S2, D12, S5, S6 to S8, S12, U6 to U8, U15, C5, T7, T11, T14 to
T17, T19, T20, T22 and T24. Move U5, D16, U12, U13 and Z4 to the plan.

## Triage

Act now: I1, I2, I3 (maintainer), I4, I5, I6, I9 (see note), I10, I11,
I12, I13, I14.

Move to the plan: C1 as the probe's fallback, the probe on a chest and
the ground, a frame-time note for D4, U5, D16, D17, Z4, Z7, U12, U13, and
the `docs/design.md` edit in PR 1.

Decline: D1's full section, D6's matrix, D4's queue, S3's restructure,
D15's test change, Z3, Z8 and Z10 unless reopened, C5, and the nits in
I16.
