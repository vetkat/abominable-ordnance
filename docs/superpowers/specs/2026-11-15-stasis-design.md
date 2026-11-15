# Abominable Ordnance: slice 5, stasis ward

Date: 2026-11-15. Status: draft for review. The agent (Claude, working
overnight) wrote this spec from `docs/design.md`, with the maintainer's
permission to continue with slice 5. Three EGM rounds followed, and round
3 found no new Blocker or Major issue. The maintainer allowed the build
once EGM agrees, so the build follows the probe gate in "Delivery".

"Answers" lists what `docs/design.md` already decides. "Proposals" lists
the agent's own calls. "Calls for the maintainer" lists the ones the
maintainer should confirm, each with the default the build uses.

This slice builds the base ward only. The Aquilo materials idea is an
open question for the maintainer, and this spec does not design it.

## Purpose

Design version 1 is the first playable release in `docs/design.md`.
Slice 5 is its last slice. It lets a player slow the spoiling of
lifecycle items in storage and transport.

The lifecycle items come from earlier slices:

- Slice 1 (`docs/superpowers/specs/2026-11-13-lifecycle-design.md`):
  biter and spitter eggs. An egg spoils in 30 minutes and hatches.
- Slice 2 (`docs/superpowers/specs/2026-11-14-ordnance-design.md`):
  biter and spitter larvae. A larva spoils in 10 minutes and hatches a
  wild monster.
- Slice 3 (`docs/superpowers/specs/2026-11-14-launcher-design.md`): six
  larva rockets. A larva rocket spoils in 5 minutes and hatches its
  loaded monster.

Goals of this slice:

1. Each lifecycle item has a warded version that spoils 20 times more
   slowly.
2. A recipe packs an item into its warded version. Another recipe unpacks
   it. The spoil progress carries over both ways, with no script.
3. Warded items stack and travel by belt, train and rocket.
4. The Stasis ward research unlocks the ward and its recipes.
5. Everything works the same with and without Space Age.

## Terms

Terms are as in the slice 1 to 3 specs. The most important ones:

- **Monster husbandry.** The slice 1 research that unlocks breeding.
- **Ordnance loading.** The slice 2 research that unlocks loading.
- **Tamed force.** `ao-tamed`, the force of the mod's own monsters. It
  has a cease-fire with player forces and is at war with the natives.
- **Loaded monster.** A monster that hatched from a loaded larva or a
  larva rocket. Its payload goes off when it dies.
- **Payload icon.** The small icon in the corner of a larva rocket's
  icon that shows its payload.
- **Control branch.** One of the four branches of the research tree in
  `docs/design.md`. Stasis ward is its first tech.

New terms:

- **Lifecycle item.** An egg, a larva or a larva rocket of the mod. There
  are 10 in version 1: 2 eggs, 2 larvae and 6 larva rockets.
- **Warded item.** The version of a lifecycle item that spoils 20 times
  more slowly, for example "Warded biter egg".
- **Ward.** The item that a pack recipe uses up and an unpack recipe gives
  back. It does not spoil.
- **Spoil progress.** How far an item is through its spoil time, from 0%
  (fresh) to 100% (spoiled).
- **Probe.** A throwaway test mod that runs before the build, in a real
  Factorio, to confirm facts the API docs leave open.

## Facts found during design

The agent read these in `.factorio-api/factorio/library/`:

- A recipe result has `always_fresh` and `reset_freshness_on_craft`
  (`ItemProductPrototype`). The docs say `always_fresh` makes a result
  fresh, whatever the freshness of its ingredients.
- A recipe has `allow_quality`, `can_set_quality`,
  `allow_productivity`, `maximum_productivity`, `main_product`,
  `allow_decomposition`, `allow_as_intermediate`,
  `allowed_module_categories` and `auto_recycle` (`RecipePrototype`).
- A result's `ignored_by_productivity` is an amount, and the engine
  ignores it when the recipe sets `allow_productivity = false`
  (`ItemProductPrototype`). So the build does not set it.
- A script can set `LuaItemStack.spoil_tick`. The docs do not say that a
  script can set `spoil_percent`.
- With more than one product and no `main_product`, a recipe needs its
  own icons and subgroup (`RecipePrototype`, `main_product`).
- An item has `spoil_ticks`, `spoil_to_trigger_result` and
  `auto_recycle` (`ItemPrototype`).
- The slice 1 and 2 probes showed that a spoil trigger runs in a
  character's inventory, in a chest and on a belt.

**Inferred, not checked: freshness.** With neither freshness field set, a
result takes its spoil progress from its ingredients. The docs do not say how
the engine averages freshness, or how an ingredient that does not spoil
(the ward) counts. `docs/design.md` "Stasis ward" relies on this. The
probe checks it.

**Inferred, not checked: quality.** The docs give no text for
`allow_quality`. Nothing says that `false` stops the quality roll from
quality modules. Nothing says how it works with `can_set_quality`, or
that a crafted item keeps the quality of its ingredient. The probe checks
both.

If the freshness inference holds, the progress carries over as a percentage, not
as ticks. A larva rocket at 40% of its 5 minutes becomes a warded rocket
at 40% of its 100 minutes. Its timer then runs 20 times more slowly.
Unpacked, it becomes a rocket at 40% plus the progress it made while
warded.

The probe must confirm the facts in the table below. A fallback says what
the build does if the probe shows otherwise:

| Fact to confirm | Fallback |
| --- | --- |
| Freshness gate: a pack result takes the spoil progress of its lifecycle item, and the ward does not change it. An unpack of a warded rocket at about 40% gives a rocket at about 40% and a ward. Both hold in an assembler as well as in a hand craft | Stop: write the probe results to the plan's probe-results section, open no build PR, and report to the maintainer. The design depends on it |
| Quality modules in an assembler give no quality roll on pack or unpack | Stop and ask the maintainer. Candidate fix: `allowed_module_categories = {}` on both recipes |
| An uncommon item packed with an uncommon ward unpacks to an uncommon item and an uncommon ward | Stop and ask the maintainer. Candidate fix: `allowed_module_categories = {}` on both recipes |
| A cancelled hand craft gives the ingredients back at their old progress | Record what happens, and note it in Risks |
| An ingredient that spoils during a pack in an assembler | Record what happens, and accept it. Note it in Risks |
| A warded item that spoils in a cargo wagon, in a rocket silo, and in a space platform hub | Record what happens in each place, and note it in Risks |

## Answers

`docs/design.md` already decides these:

| Question | Answer |
| --- | --- |
| What the ward is | Each lifecycle item has a warded version with a very long spoil time |
| How it works | Plain recipes. A recipe result keeps its ingredients' freshness. No script |
| Where it travels | Warded items stack and travel by belt, train or rocket |
| Rejected alternative | A script-managed container, or items with tags |
| Research | Stasis ward, the first tech of the Control branch, with military and chemical science |

## Alternatives considered

| Choice | Rejected alternative | Why rejected |
| --- | --- | --- |
| A ward item used up by packing and given back by unpacking | A ward that packing uses up for good | Shipping would use up a ward each time, so long chains need many wards. The maintainer can switch. See "Calls for the maintainer" |
| A ward item | No ward item, so packing costs only time | Without a cost, a player can ward every item, and spoiling stops mattering. The ward gives the feature a cost |
| One multiplier for every warded spoil time | A fixed time for every warded item | A rocket that spoils in 5 minutes and an egg that spoils in 30 would get the same protection, so the egg's ward would be worth less |
| The craft category `crafting` | A new machine | Version 1 already has three machines. Any assembler can pack, and so can a player |
| Warded rockets are plain items | Warded rockets as launcher ammo | The launcher would hold rockets with 20 times their spoil time, so rockets would not hatch next to the launcher. A player unpacks a rocket before loading it |
| One builder that takes an explicit list of version 1 items | A builder that wards every item with a spoil trigger | Version 2 items, such as embryos, would get warded versions without a design decision |

`docs/design.md` says that a ward "can hold any item in this table". That
table also lists version 2 items. They get warded versions later, through
a change to the explicit list. Version 1 wards eggs, larvae and larva
rockets only.

## Proposals

The agent made these calls. The maintainer can change any of them:

The numbers are in "Game content".

- **The ward item.** "Stasis ward", made from plastic bars, a steel plate
  and an electronic circuit. All three exist with and without Space Age.
  Its stack is the same as the larva rocket casing.
- **Pack and unpack.** Pack: 1 lifecycle item + 1 ward → 1 warded item.
  Unpack: 1 warded item → 1 lifecycle item + 1 ward.
- **Warded spoil time.** The item's own spoil time times `stasis.factor`.
- **When a warded item spoils.** It runs the same spoil effect as its
  lifecycle item. A warded egg hatches like an egg, and a warded rocket
  hatches its loaded monster. The ward is lost. A warded item can still
  hatch in storage, so storage keeps its risk.
- **Stack sizes.** The same as the lifecycle item: eggs 100, larvae 20,
  larva rockets 10.
- **Research.** Stasis ward needs Ordnance loading, so the pack recipes
  for larva rockets never appear before larva rockets exist.
- **No free quality or productivity.** Pack and unpack set
  `allow_quality = false`, `allow_productivity = false` and
  `maximum_productivity = 0`. Otherwise a pack and unpack loop with
  quality modules would raise any item to legendary for free, and
  productivity would make eggs and wards from nothing. `can_set_quality`
  keeps its default. The probe checks that this stops the roll and keeps
  an existing quality.
- **A ward of the same quality.** A recipe set to a quality needs every
  item ingredient at that quality. So an uncommon egg needs an uncommon
  ward. The ward's recipe stays open to quality, so players can make
  wards of every quality.
- **No loops in the crafting tools.** Pack and unpack set
  `allow_decomposition = false` and `allow_as_intermediate = false`. So
  the "Total raw" tooltip ignores the loop, and a hand craft never chains
  through a warded item.
- **Recycler (Space Age).** The pack and unpack recipes set
  `auto_recycle = false`, as for the other lifecycle recipes. The ward's
  own recipe stays recyclable, like the casing's. The warded items set
  item-level `auto_recycle = false`, so the recycler makes no
  self-recycling recipe for them.
- **Unpack recipes.** Each sets `main_product` to its lifecycle item. It
  still gets its own icon (the item's icon with the ward icon in the
  corner) and its own locale name, for example "Unpack a warded biter
  egg".
- **Subgroup.** All 21 recipes, the ward and the warded items use the new
  subgroup `ao-stasis`, in the vanilla item group
  `intermediate-products`. So they sit together in the crafting menu.

## Calls for the maintainer

| Call | Default the build uses |
| --- | --- |
| Stasis ward materials: Aquilo materials in Space Age, and a substitute without it (`docs/design.md` open question) | Not designed. The base ward uses plastic, steel and a circuit in both modes. An Aquilo tier can follow |
| Stasis ward's place in the tree. `docs/design.md` shows it as the first Control tech with no prerequisite | It needs Ordnance loading |
| A warded item that spoils | It hatches like its lifecycle item, and the ward is lost |
| Ward loss for eggs. Every 10 spoiled warded eggs hatch one monster, but every egg uses up one ward | 100 warded eggs that spoil lose 100 wards and hatch 10 monsters |
| Does unpacking give the ward back? | Yes, every time |
| Spoil progress carries over as a percentage | A rocket packed at 95% stays at 95% while warded. After unpacking, it spoils in about 15 s |
| Warded rockets as launcher ammo | No. A player unpacks a rocket first |
| Warded spoil time | `stasis.factor` in "Game content" |
| Ward recipe and stack | `stasis.ward` in "Game content". The stack follows the casing |
| Research cost | `stasis.research` in "Game content" |
| A quality item needs a ward of the same quality | Yes. The ward's recipe stays open to quality |

## Game content

All numbers go in `core/balance.lua`:

| Name | Value |
| --- | --- |
| `stasis.factor` | 20 (warded spoil time = factor × item spoil time) |
| `stasis.ward` | stack 50, time 2 s, 2 plastic, 1 steel, 1 circuit |
| `stasis.pack_time` | 1 s |
| `stasis.research` | count 150, time 30, packs red, green, military and blue |

### Items

| Item | Type | Stack | Spoil |
| --- | --- | --- | --- |
| `ao-stasis-ward` | item | 50 | None |
| `ao-warded-<item>` for each lifecycle item, for example `ao-warded-biter-egg` | item | As the lifecycle item | 20 × the item's time, then the item's spoil effect |

A warded item copies its lifecycle item's spoil trigger, including
`items_per_trigger`. Eggs use 10, so every 10 spoiled warded eggs hatch
one monster. Larvae and larva rockets use 1, so each one hatches. At 20
times the item's own time, an egg lasts 10 hours, a larva 200 minutes
and a larva rocket 100 minutes.

A warded item shows its lifecycle item's icon. A small ward icon sits in
its corner, in the same way as the payload icon on a larva rocket.

### Recipes

| Recipe | Ingredients | Result | Unlocked by |
| --- | --- | --- | --- |
| `ao-stasis-ward` | 2 plastic bars, 1 steel plate, 1 electronic circuit, 2 s | 1 ward | Stasis ward |
| `ao-ward-<item>` | 1 lifecycle item, 1 ward, 1 s | 1 warded item | Stasis ward |
| `ao-unward-<item>` | 1 warded item, 1 s | 1 lifecycle item (main product), 1 ward | Stasis ward |

No result sets `always_fresh` or `reset_freshness_on_craft`. All recipes
use the category `crafting`. The pack and unpack recipes follow the
quality, productivity, loop and recycler rules in "Proposals".

### Research

| Tech | Needs | Cost | Effect |
| --- | --- | --- | --- |
| `ao-stasis-ward` | Ordnance loading | 150 × (red, green, military, blue), 30 s | Unlocks the ward, every pack recipe and every unpack recipe |

## Runtime behaviour

The ward needs no runtime code. A warded item that spoils runs the
`script` effect of its lifecycle item, for example `ao-hatch-biter` or
`ao-hatch-biter-explosive`. The slice 1 and 2 handlers key on the effect
ID, not on the item name. So a warded egg or larva hatches a wild monster
on the natives' force. A warded rocket hatches its loaded monster on the
tamed force, as a plain rocket does. An in-game test checks this.

On a space platform, the existing handlers do nothing (`control.lua`
returns early when `surface.platform` is set). A warded item that spoils
there is lost with its ward. See "Risks".

Old saves: the slice adds items, recipes and one research, and changes no
existing prototype. `on_configuration_changed` already resets technology
effects. The slice adds no `storage` field and needs no migration.

## Architecture

The rules in `docs/architecture.md` apply. New and changed modules:

| Module | Layer | Job |
| --- | --- | --- |
| `core/prototypes/stasis.lua` | core | Builds the ward, the warded items, the pack and unpack recipes, the subgroup and the research from the source prototypes it gets |
| `core/names.lua` | core | `STASIS_TECH`, `WARD`, and the prefixes `ao-warded-`, `ao-ward-` and `ao-unward-` |
| `data.lua` | shell | Asserts that `plastic-bar`, `steel-plate` and `electronic-circuit` exist. Keeps the results of `Lifecycle.prototypes` and `Ordnance.prototypes` in local variables, passes them to the stasis builder, and extends all three |
| `locale/en/locale.cfg` | data | Names for every new item, recipe, subgroup and research |

`Lifecycle.prototypes` returns one mixed list of prototypes.
`Ordnance.prototypes` returns a mixed list and a list of recipe names.
Neither returns an item list. So `data.lua` keeps both lists and passes
them in, and the builder indexes them by name.

The builder picks the sources from an explicit list of names. It builds
that list from `Names`, `Species` and `Payloads`. The list holds the 2
eggs, the 2 larvae and the 6 larva rockets. A version 2 item gets a
warded version only through a deliberate change to that list.

The larva rockets are `type = "ammo"`. So the builder makes each warded
item fresh with `Common.item`, and never copies the source item, so no
`ammo_type` carries over. From the source it takes `spoil_ticks` ×
`stasis.factor`, the stack size, and a copy of `spoil_to_trigger_result`
made with `Common.copy`, so the two items share no table. It also reuses
`Common.icon`, `Common.technology` and `Common.no_recycling`. The warded
icon uses the corner-icon pattern of `loaded_icon` in
`core/prototypes/ordnance.lua`.

## Testing

### Unit tests (busted)

- Every version 1 lifecycle item has exactly one warded item, one pack
  recipe and one unpack recipe. No other item gets one.
- A warded item spoils in 20 times its item's time and runs the item's
  spoil effect, with the same `items_per_trigger`.
- No pack or unpack result sets `always_fresh` or
  `reset_freshness_on_craft`.
- Every unpack recipe sets `main_product` to its lifecycle item, its own
  icons and the subgroup `ao-stasis`. The subgroup belongs to the item
  group `intermediate-products`.
- Every pack and unpack recipe sets `allow_quality = false`,
  `allow_productivity = false`, `maximum_productivity = 0`,
  `allow_decomposition = false`, `allow_as_intermediate = false` and
  `auto_recycle = false`.
- A warded rocket has type `item` and no `ammo_type`. Its spoil trigger
  is a copy, not the source's table.
- The ward's own recipe does not set `auto_recycle = false`. Every warded
  item sets item-level `auto_recycle = false`.
- The research needs Ordnance loading and unlocks the ward and every pack
  and unpack recipe.
- Every new prototype has a locale name (`spec/locale_spec.lua`).

### In-game tests (factorio-test, both modes)

The tests set spoil progress through `LuaItemStack.spoil_tick`, which the
docs let a script set. They never wait for a full spoil time.
`spoil_tick` is an absolute game tick. For a progress `p`, a test sets it
to `game.tick + ceil((1 - p) * spoil_ticks)` right after it inserts the
item. "About 40%" means 40% plus or minus 2 percentage points.

- An assembler packs a larva rocket at 40% into a warded rocket at about
  40%. Unpacking gives the rocket back at about 40%, and a ward.
- A warded egg set to 99% spoil progress in a chest is still unspoiled a
  few seconds later.
- A warded larva rocket that spoils hatches its loaded monster on the
  tamed force.
- A warded biter egg that spoils (10 eggs) hatches one wild monster.

## Delivery

### Probe

Before the build, the probe checks the facts in the table in "Facts found
during design". The plan follows the fallback for each fact that fails.
The freshness gate or a quality fact can fail. Then the agent writes the
probe results to the plan's probe-results section. It opens no build PR
and reports to the maintainer.

### Pull requests

1. **Stasis ward.** The ward, the warded items, the recipes, the
   research, the locale and the tests. The slice is small, so it ships
   as one PR.

The PR follows the workflow in `CLAUDE.md`, with a CHANGELOG entry.

## Risks

- **Item count.** The slice adds 1 ward, 10 warded items, 21 recipes and
  1 subgroup. Each new lifecycle item in version 2 adds 1 item and 2
  recipes. That is the "Ammo count" risk in `docs/design.md`, and the
  count stays linear.
- **The progress carries over as a percentage.** A rocket packed at 95%
  stays at 95% of 100 minutes. After unpacking, it spoils in about 15 s.
  Players must unpack an item shortly before they use it.
- **A ward of the same quality.** A quality lifecycle item needs a ward
  of the same quality to pack. Breeding with quality modules can make
  quality eggs, so players may need wards of several qualities.
- **Quality behaviour is not proven.** The docs do not describe
  `allow_quality`. The probe checks it, and the build stops if it fails.
- **Lost wards.** A warded item that spoils loses its ward. For eggs, 10
  wards are lost for each monster. The maintainer decides if this cost
  stays.
- **Silently lost on platforms.** A warded item that spoils on a space
  platform hatches nothing, and the item and its ward are lost. The
  longest warded time is 10 hours for an egg and 100 minutes for a larva
  rocket. A trip between planets usually takes a few minutes, so this
  happens only to items that wait on a platform for a long time.
- **Spoiling during a craft, in transit or in a cancelled craft.** The
  probe records what the engine does. The build accepts it and notes it
  here.

## Changes to `docs/design.md` and `ROADMAP.md`

- Reword every place that says the ward pauses or stops the spoil timer,
  so that it says the ward slows it 20 times. There are five places:
  "Store and ship" in the pillars (about line 54, "Stasis wards pause the
  spoil timer"), "Spoiled larvae" (about line 258, where "spoils outside
  a stasis ward" implies no spoiling inside one), "Stasis ward" in
  "Logistics and delivery" (about lines 282 to 283, "the spoil timer
  continues where it stopped"), the research tree node (about line 334,
  "Pauses spoiling") and "Version 1 feature list" (about line 371,
  "Stasis ward that pauses and resumes the spoil timer"). Tick the last
  one.
- Research tree: show that Stasis ward needs Ordnance loading, if the
  maintainer agrees.
- Open question "Warded items": answer it with the maintainer's choice.
- Keep "Stasis ward materials" open until the maintainer decides.
- `ROADMAP.md`: reword and tick the stasis ward item in the same way.
  Also tick "The first four research techs". With this slice, all four
  version 1 techs exist: Monster husbandry, Ordnance loading, Larva
  rockets and Stasis ward.

## Out of scope

- The Aquilo tier of the ward and any Space Age-only materials.
- Warded embryos and warded hybrid eggs, design version 2.
- A ward that holds more than one item.
