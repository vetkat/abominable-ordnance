# Stage 6: Comprehension Test

Target: `docs/superpowers/specs/2026-11-13-lifecycle-design.md` as of
commit 592abfe, lines 1 to 294 (the whole file). The reviewer read the
document alone.

Reviewer: `egm-comprehension`.

## What this proposes

Slice 1 is the "Lifecycle" slice of a Factorio mod, Abominable Ordnance. It
is the first of four slices that together make release 1.0.0. The slice
adds the mod's own biter and spitter eggs, which are kept separate from
Space Age's `biter-egg`. It also adds two crafted feeds, monster chow and
spitter chow, and two machines. The breeding pod turns 1 egg plus chow into
2 eggs. The incubator turns an egg into a larva. A research called Monster
husbandry unlocks all of this, and it also makes native biter and spitter
spawners drop 1 to 3 eggs when a force that has the research kills them.
When eggs spoil, every 10 of them hatch one enemy unit, and each spoiled
larva hatches one. The hatch uses native spoilage with a `script` trigger.
The shell handles the trigger event, and a pure core module picks the unit
from the spawner's `result_units` table, weighted by the enemy evolution on
that surface. Space Age changes only the pod's graphics and adds one recipe
that converts Space Age's `biter-egg` into the mod's egg. The slice ships in
three PRs (content, hatching, nest loot). An in-game probe runs first to
confirm how spoil triggers behave inside a chest.

## How the existing system works, per this document

The mod splits its code into a pure "core" (Lua modules under `core/`,
unit-tested with busted, with an architecture test that keeps them pure)
and a "shell" (`data.lua` and the control-stage event handlers that call
the core). The document defines these two words only by pointing to
`docs/architecture.md`. In Space Age, the captive biter spawner makes
`biter-egg` with a fixed recipe. That egg spoils in 30 minutes and hatches
one `big-biter` per 25 eggs on the enemy force, and nothing over space.
`pentapod-egg` is bred in the biochamber with flags that stop productivity
from duplicating eggs. The base game has no eggs, no biochamber and no
nutrients. Testing has two tiers: busted unit tests (`make fast`) and
in-game factorio-test runs in both modes (`make check`). Releases track
`CHANGELOG.md` and `ROADMAP.md`.

## Elephant notes

These notes come from the main session. They are not reviewer findings.

- The paraphrase matches the intent. The reader understood the design
  without help.
- U1 matches C6 from Stage 5. U3 overlaps C1 and Z3 from Stage 5: what 1 to
  3 loot eggs do depends on a rounding rule nobody has measured yet.
- U4 is about the "Notes for version 2" section, which Z5 from Stage 5
  proposes to delete.

## Findings

### U1. Major: "the probe in Delivery" can be read two ways

Lines 62 to 63 and 77. "Delivery" is slice 3 and also a section of this
spec. A reader can think the ratio check waits for slice 3, which
conflicts with "before PR 2". Line 77 names the probe before it is
defined. Write "the probe in this slice's first plan task (see the
Delivery section below)", or rename the section.

### U2. Major: the `pentapod-egg` flags are inconsistent

Lines 51 to 52 against lines 128 to 132 and 232. Facts gives the egg
`ignored_by_stats` and the result `ignored_by_productivity`. Recipes says
"copy the flags", but also gives the result `ignored_by_stats = 1`. "The
egg" could mean the ingredient or the item. List the exact flags on the
ingredient and on the result in Facts. Then say "identical" or name the
difference.

### U3. Major: what happens to eggs left on a battlefield is unclear

Lines 77, 174, 260 to 261 and 284. Line 284 says left-behind eggs hatch,
but 1 to 3 loot eggs may give "one hatch or none". The spec never says
what a spoiled egg turns into: is it removed, or does it leave a spoil
result? Line 283 says "a chest", but 10 behemoths matches one
stack of 100. State the spoil result of eggs and larvae. Make the line
284 answer cover both probe outcomes. Write "a stack of 100 eggs".

### U4. Major: "jazz pod" is never defined

Lines 79, 205 to 210 and 294. The reader cannot tell what a jazz pod is.
"The jazz pod is the first one" can mean the first machine or the first
track. It is unclear whether a track is a whole volume or a loop cut from
one. Define the jazz pod in one sentence, or cut the paragraph to a
pointer to the version 2 design.

### U5. Major: the fallback position is too loose

Lines 253 to 257 and 282. "The position of the inventory's owner entity"
needs an event field that names the inventory or entity. Name that field
(for example the source or target entity of `on_script_trigger_effect`),
or make it part of what the probe records.

### U6. Nit: "shell" and "core" are defined only by a path

Lines 40 to 41. Add a one-line gloss for each.

### U7. Nit: "EGM review" is not expanded

Line 4. Expand it or link it.

### U8. Nit: design versions are not explained

Lines 8, 79, 205, 212 and 292. Say that `docs/design.md` defines the
design versions.

### U9. Nit: "wild" and "feral"

Lines 27 and 91 to 94 against line 18. Define a wild monster as a unit on
the `enemy` force, and say that feral is a separate slice 4 idea.

### U10. Nit: the list of Space Age differences is incomplete

Lines 29 to 31 and 200 to 201 name graphics and the adopt recipe. Lines
111 to 112 add the working sound. Say "graphics and sound".

### U11. Nit: "biter egg" against `biter-egg`

Line 126. Only the code font tells the mod's item from Space Age's item.
Use prototype names in the recipe table.

### U12. Nit: the machine recipes are not in the Recipes table

Lines 105 to 107 and 138. Add both machine recipes with first-guess
numbers.

### U13. Nit: the research cost is not complete

Lines 136 to 137. List the full pack set, the unit count and the time, or
say they live in `core/balance.lua`.

### U14. Nit: two gaps in the hatching steps

Lines 150 to 156. Name the spawner of each species in step 2. Say that
nothing hatches when the core returns nil.

### U15. Nit: project test terms are not explained

Lines 218, 236 to 237, 239 and 249. Gloss `make fast`, `make check`, the
architecture test, the coverage floor and the `space-age` tag.

### U16. Nit: "the builder" and the missing-path check

Line 285. Name `core/prototypes/lifecycle.lua`. Say that the game refuses
to load a mod with a missing sprite path, so the Space Age run fails.

### U17. Nit: "its egg half" is unclear

Lines 274 to 276. Write "This slice delivers egg and larva hatching. Slice
2 adds the loaded-larva outcomes."
