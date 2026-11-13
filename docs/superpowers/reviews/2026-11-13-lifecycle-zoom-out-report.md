# Stage 5: Initial Zoom Out Review

Target: `docs/superpowers/specs/2026-11-13-lifecycle-design.md` as of
commit 592abfe, lines 1 to 294 (the whole file).

Goldfish context: `docs/design.md` and `docs/architecture.md`.

Reviewers: `egm-zoom-out` (simplicity and scope) and `egm-inventive-catalyst`
(false compromises).

Neither reviewer found a Blocker. Both say the design passes with changes.

## Elephant notes

These notes come from the main session, which has the full design history.
They are not reviewer findings.

- **Checked and true.** Z1 and C2 report the same problem. The main session
  checked `base/prototypes/entity/enemies.lua` in Factorio 2.1.24. The
  `spitter-spawner` table is `small-biter` from 0 to 0.35 evolution, and
  `small-spitter` starts at 0.25. Below 0.25 evolution, a spitter egg would
  hatch only small biters. The in-game test at evolution 0 would fail.
- **Found by both reviewers.** Z9 matches C3: the incubator and larvae have
  no use in this slice. C3 adds that larvae hatch 1:1 and spoil three times
  faster, so incubation undoes the 10:1 egg ratio. Z4 matches C4 in part:
  both want one species table.
- **Against decisions the maintainer made.** The maintainer chose the egg
  ratio 10:1 with `items_per_trigger`, to be confirmed by the probe. C1
  proposes a random hatch with probability 1/10 per egg in the core. That
  keeps the average ratio and removes the rounding question. The maintainer
  chose loot after research. Z3 proposes plain prototype `loot` with no
  gate. These findings stay in the report, but the decisions stand unless
  the maintainer changes them.
- **Interaction.** Z3's reason ("1 to 3 eggs hatch nothing at 10:1")
  depends on the rounding that the probe has not measured yet. With C1's
  random hatch, 1 to 3 loot eggs hatch a monster 10 to 30 percent of the
  time.

## Zoom-out findings (egm-zoom-out)

Verdict: approve once the changes are made. Z1 to Z3 should be settled
before writing-plans.

### Z1. Major: spitter eggs hatch biters under the chosen weights

Where: Decisions "Hatch size", Items table, Hatching step 2.

The spec reads `result_units` from the species' spawner and uses the
vanilla weights. `spitter-spawner` lists `small-biter` at low evolution, so
early spitter eggs and larvae hatch biters. This breaks the Items table and
the species identity that slices 2 to 4 rely on.

Change: (a) filter the unit table to the egg's species before the pick, or
(b) accept mixed hatches and reword the Items table. (a) keeps species
identity. Add a unit test.

### Z2. Major: graphics referenced by path instead of copied from prototypes

Where: Decisions "Graphics", Machines, Data stage, Risks row 4.

Re-creating the full `graphics_set` of the chemical plant and the
biochamber by hand (layers, shadows, frame counts, shifts, scale, working
visualisations) is fragile. The usual way is to deep-copy the vanilla
prototype and change it. Purity does not forbid this: `data.lua` can pass
the source `graphics_set` and `working_sound` into the builder as
parameters. Busted passes small stubs. Risk row 4 and its test go away.

### Z3. Major: nest loot rebuilds the prototype `loot` field

Where: Decisions "First eggs", Nest loot, `core/loot.lua`, PR 3.

A spawner's `loot` field already drops 1 to 3 items on death without
script. Only the research gate needs code: a handler, a core module, a
force check and a PR. The gate's reason (front clutter) is weak at 10:1.

Change: (a) drop the gate and add `loot` to both spawners in the data
stage, or (b) keep the gate and say why it is worth the code. Before (a),
confirm that spawner loot drops whoever kills the spawner.

### Z4. Nit: species data in several places

Loot maps spawner to species, hatching maps species to spawner, effect IDs
repeat the species, and every row lists the species by hand. Put one
species table (name, spawner, effect ID, feed) in a core module that the
builder, hatching and loot all read. Slice 2 needs it too.

### Z5. Nit: the version 2 notes are out of scope

The track details repeat `docs/design.md` and will drift. The pentapod
note leaves a known error in `docs/design.md` (line 111). Delete the
section, keep the line in Out of scope, and fix `docs/design.md` now or
add the correction to its open questions.

### Z6. Nit: a unit test repeats the engine's load checks

"Every recipe ingredient and result names an item or fluid that exists"
needs a hand-kept list of vanilla names. The game refuses to load a recipe
with an unknown item, and `make ingame` loads both modes. Drop the test or
limit it to this slice's items.

### Z7. Nit: the locale test should use the existing helper

`spec/support/locale.lua` already has `L.value(text, section, key)`. Say
that the test uses it.

### Z8. Nit: a second feed item for one recipe

Spitter chow serves only `ao-breed-spitter`. Consider 1 spitter egg, 5
monster chow and sulfuric acid in the breeding recipe, and drop spitter
chow. Keep it if the maintainer wants a separate feed item.

### Z9. Nit: larvae ship with no consumer

The incubator, two larvae and two recipes have no use until slice 2.
Either move them to slice 2 or add one sentence on why they stay.

### Z10. Nit: PR order leaves the base game without eggs

After PRs 1 and 2, the base game has no egg source until PR 3. Swap PRs 2
and 3, or note that the gap is intended.

## Inventive catalyst findings (egm-inventive-catalyst)

Verdict: approve with advisory changes. The persona allows only Major or
Nit in review mode. Fix order: C2, C1, C3.

### C1. Major: the hatch ratio depends on unknown engine behaviour

Where: Decisions "Hatch ratio", Hatching step 1, Delivery, Risks row 3.

`items_per_trigger = 10` ties the balance to engine behaviour the spec does
not know. Risks row 3 says left-behind eggs "hatch, which removes them",
but 1 to 3 loot eggs are below the threshold.

Transform (Extraction plus Dynamics): use `items_per_trigger = 1`. Each
trigger asks `core/hatching.lua` for a yes or no with probability
`1 / egg_hatch_ratio`, from the stored generator. The average stays
1 in 10. Loot eggs get a 10 to 30 percent hatch chance. Busted tests the ratio,
and the probe only checks the position.

Side costs: one event per spoiled egg, so 100 handler calls when a full
stack spoils. Measure it in the probe. Hatches become random, but the
seeded generator keeps multiplayer deterministic.

### C2. Major: spitter eggs hatch biters at low evolution

Same as Z1. Transform (Segmentation): filter the table to the species in
the core, with a fallback for an empty table below the first spitter
point: the smallest unit of the species, or the first spawn point extended
down to 0. Add a unit test: spitter table, evolution 0, result is a
spitter. Side cost: a rule for which units belong to a species (a name
pattern or a list).

### C3. Major: the incubator undoes the flood protection

Where: Items, incubate recipes, Purpose.

One egg makes one larva that hatches 1:1 and spoils in 10 minutes, not 30.
Incubation is a ten-times hatch amplifier, and larvae have no use in this
slice.

Transform: (a) move the incubator and larvae to slice 2 with the loading
chamber, or (b) keep them behind a gate, such as the random hatch of C1
for larvae or a recipe locked until Ordnance loading. (a) grows slice 2.
(b) adds a temporary rule that slice 2 must remove.

### C4. Nit: loot uses names, hatching uses data

Derive a spawner's species from its `result_units` with the C2 rule, or
keep the name list under YAGNI and note the asymmetry.

### C5. Nit: silent failure paths

A missing `biter-spawner` makes every egg harmless, and a packed warehouse
destroys eggs with no signal. Check the unit tables in `on_init` and
`on_configuration_changed`, cache them in `storage`, and log one warning
if one is missing.

### C6. Nit: "Delivery" means two things

"The probe in Delivery" can mean the spec section or slice 3. Write "the
Delivery section below" or rename the section.
