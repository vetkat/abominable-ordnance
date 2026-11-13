# Stage 7: Critic Review, round 1

Target: `docs/superpowers/specs/2026-11-13-lifecycle-design.md` as of
commit 592abfe, lines 1 to 294 (the whole file).

Goldfish context: `docs/design.md` and `docs/architecture.md`.

Reviewers and standards:

| Reviewer | Standard | Status | Verdict |
| --- | --- | --- | --- |
| `egm-design` | feature-spec-standard | completed | Not approved: 1 Blocker, 8 Major, 8 Nit |
| `egm-structural` | feature-spec-standard | completed | Fail: 1 Blocker, 4 Major, 8 Nit |
| `egm-style` | persona rules | completed | Changes requested: 6 Major, 18 Nit |

The round is not clean. It has two Blockers (the same finding) and
unsettled Major findings.

## Elephant notes

These notes come from the main session, which has the full design history.
They are not reviewer findings.

- **One Blocker, found twice.** D1 and S1: the spec records no rejected
  alternatives. The brainstorm did weigh alternatives for most rows (egg
  items, captive spawner, breeding machine, feed, hatch size, hatch
  method, hatch ratio, nest loot, music). The spec only lost them. The fix
  is to write them down, not to redo the design.
- **Checked and true.** D2 repeats Z1 and C2 from Stage 5. The main
  session checked the 2.1.24 `spitter-spawner` table.
- **Checked against the API.** T4: `ignored_by_productivity = 1` on a
  result of 2 removes one egg from the productivity bonus. Productivity
  still adds to the net gain of one egg. The spec's "productivity does not
  copy eggs" overstates this.
- **Found in several stages.** "The probe in Delivery": C6, U1, S4, T2,
  D11. The left-behind eggs contradiction: C1, U3, D3, T5. Graphics by
  path: Z2, D7, T21. The list of Space Age differences: U10, T1, D13. The
  `pentapod-egg` flags: U2, T3. The version 2 notes: Z5, U4, S9, T18. The
  interpolation rule: D5, T12. The item-name test: Z6, D14. "Vanilla
  weights": S10, T9. Maintainer credit: S2, D12.
- **New design questions for the maintainer.** D4 (a warehouse that
  spoils in one tick), D6 (eggs hatching off Nauvis and in odd places),
  D8 (incubator productivity and larva freshness).

## Design findings (egm-design)

### D1. Blocker: no alternatives section

Lines 66 to 80. The feature-spec standard fails a spec that proposes one
path without showing the rejected options. The Decisions table gives one
answer per row. Hatch method, hatch size, egg items, breeding machine and
nest loot have no rejected option and no trade-off. Add an "Alternatives
considered" section.

### D2. Major: spitter eggs hatch biters below 0.25 evolution

Lines 92, 151 to 156 and 242 to 243. `spitter-spawner` lists
`small-biter` at {0.0, 0.3} to {0.35, 0}. The in-game test at evolution 0
will fail or pass by accident. Filter by species, accept mixed hatches, or
pin the test.

### D3. Major: claims in both directions about rounding

Lines 77, 91 to 92, 242 to 245, 259 to 265 and 284. Line 77 holds only if
remainders round down. Line 284 holds only if they round up. The in-game
test spoils one egg, which never hatches with round-down. Spoil 10 eggs
in the test. Make both claims depend on the probe result. Say which
result blocks PR 2.

### D4. Major: mass spoilage in one tick

Lines 77, 145 to 159 and 283. Batch crafting aligns spoil timers. A steel
chest of 4,800 eggs gives 480 triggers in one tick, each with a prototype
read, a core call, a position search and `create_entity`. Measure it in
the probe, add a deterministic queue in `storage`, or accept the spike
with a reason.

### D5. Major: the interpolation rule is not stated

Lines 155 to 156 and 220 to 224. "In the same way as the engine" gives no
rule below the first point, above the last point, for normalising, or for
mapping the random number. The tests have no expected values. Write the
rule and its source, or let the probe confirm it.

### D6. Major: the probe covers only a chest

Lines 157 to 159, 253 to 257 and 282. Eggs also spoil on belts, in
inserter hands, on the ground (nest loot), in a character, in robots,
wagons, silos, cargo pods and the hub. Not every place has an owner
entity. Eggs taken to other planets would hatch Nauvis units with that
surface's evolution. Make the probe a matrix, give a nil-safe rule for
each place, and decide whether hatching off Nauvis is intended.

### D7. Major: borrowed graphics in a pure builder

Lines 79, 109 to 114, 198 to 201 and 285. Hard-coded sprite fields break
the game for every user when Space Age moves a sprite. The in-game test
cannot catch it, because the game fails to load. Have `data.lua` pass
deep copies of the graphics and sounds into the builder.

### D8. Major: incubator flags and modules are not stated

Lines 105 to 132. Module slots and allowed effects are missing for both
machines. Incubator productivity would make larvae from nothing. A larva
inherits its egg's spoil fraction, so an old egg makes a larva that
hatches within seconds. State the slots, effects and flags.

### D9. Major: departures from `docs/design.md` are not recorded

Lines 66 to 80 and 212 to 214. The spec changes the spitter source (design
line 109), the base-game biter source (line 108) and the spoil trigger
(lines 342 to 345). Only the pentapod correction is recorded. Add a list
of corrections to `docs/design.md`, or plan the edits.

### D10. Nit: missing prerequisite

Lines 136 to 139. A tech that uses chemical packs needs the Chemical
science pack technology as a prerequisite.

### D11. Nit: "the probe in Delivery"

Line 63. Say "the Delivery section of this spec" or "the first plan task".

### D12. Nit: maintainer credit without a link

Lines 3, 205 and 264 to 265. Link the decisions or write them in a
neutral voice.

### D13. Nit: Goal 3 lists too few differences

Lines 29 to 31. The working sound, the fluid boxes and the footprint also
follow the borrowed machine.

### D14. Nit: the item-name test has no source of names

Lines 228 to 229. busted has no `data.raw`. Say where the known names come
from.

### D15. Nit: the architecture test does not ban `data` or `mods`

Lines 198 to 199 and 236. Extend the test or soften the claim.

### D16. Nit: search radius and missing spawners

Lines 152 and 157 to 159. Give the free-position search radius. Add a nil
guard for a removed spawner.

### D17. Nit: the random number's range

Lines 153 to 154, 174 and 223 to 226. Say whether it is [0,1), [0,1] or
an integer.

## Structural findings (egm-structural)

### S1. Blocker: no evaluation of alternatives

Same as D1. Add an Alternatives section, or "Alternatives rejected" and
"Why" columns in the Decisions table.

### S2. Major: decisions credited to the maintainer with no link

Same as D12. Lines 3 to 4 and 205.

### S3. Major: Risks does not meet the standard

Lines 278 to 285. The heading should be "Risks & Mitigations". Row 2 has
no mitigation. Missing risks: rounding of `items_per_trigger`, multiplayer
desync, many triggers in one tick, and mod compatibility. No security or
limits statement.

### S4. Major: ambiguous cross-reference

Same as D11. Use a link to the Delivery section.

### S5. Major: no problem statement

Lines 6 to 21. Purpose describes the slicing, not the player problem this
slice solves.

### S6. Nit: goals and non-goals are apart and have no headings

Put both under one heading with H3 subsections.

### S7. Nit: no "Proposed architecture" heading

Data stage and Core modules sit under Runtime behaviour. Group them under
one H2 with Data stage and Control stage as H3s.

### S8. Nit: file references are code spans, not links

Lines 8, 40 to 41, 213, 268 and 274.

### S9. Nit: version 2 material in the middle

Lines 203 to 214, 79 and 294. Music appears three times and pentapods
twice. Merge into Out of scope.

### S10. Nit: two descriptions of the hatch weights

Line 75 says "vanilla spawner". Lines 151 to 153 read the prototype at
runtime. Write "the species' spawner prototype".

### S11. Nit: item names in the Recipes table

Row 126 tells `biter-egg` from "biter egg" only by code font. Use
prototype names.

### S12. Nit: list formatting in Unit tests

Mixed nested indents, lowercase fragments next to full sentences.

### S13. Nit: Delivery mixes the probe and the PR plan

Split it into two H3s so the probe can be linked.

## Style findings (egm-style)

### T1. Major: Goal 3 contradicts the body

Same as D13 and U10. Add the working sound.

### T2. Major: "the probe in Delivery"

Same as D11.

### T3. Major: the `pentapod-egg` flags

Lines 51 to 52 against 128 to 132. Facts and Recipes list different flags
and still say "copy". List the exact flags in Facts.

### T4. Major: "productivity does not copy eggs" overstates the flag

Line 131. `ignored_by_productivity = 1` on 2 results leaves the net gain
of one egg under productivity. "Copy" also has two meanings three lines
apart. Write "productivity adds eggs only on the net gain".

### T5. Major: the in-game test can fail by design

Lines 242 to 243. One egg may hatch nothing at 10:1. Spoil 10 eggs or a
larva, and write "a unit of the egg's species".

### T6. Major: "a chest" is one stack

Line 283. 10 monsters is one stack of 100. Write "a stack of 100 eggs at
high evolution hatches 10 monsters, most of them behemoths".

### T7 to T24. Nits

- T7: facts come from several sources, not only Space Age data files.
- T8: "reads like one biter per egg" hedges. Quote the wiki or drop it.
- T9: same as S10.
- T10: "the probe confirms" assumes the result. "Flood" has no measure.
- T11: "over space" and "on a space platform" for one condition.
- T12: same as D5.
- T13: the `core/balance.lua` list leaves out the hatch ratio, research
  costs and machine recipes.
- T14: drop "yet" in "has no use yet".
- T15: name the incubator's sprite source.
- T16: "vanilla", "base game" and "mode" are used loosely.
- T17: "finds the API call" is stated twice.
- T18: same as Z5 and S9. Drop the preference, or make it a decision.
- T19: join "may not ... Then ..." into one conditional sentence.
- T20: "clutters the front for artillery players" is vague.
- T21: same as D7. Name the module and the real failure.
- T22: "coverage floor", "5 chow" and "the tag `space-age`" are
  undefined.
- T23: "its egg half" is inaccurate. Unloaded larvae hatch in this slice
  too.
- T24: mixed capitals in nested test bullets.
