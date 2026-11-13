# Abominable Ordnance: slice 1, lifecycle

Date: 2026-11-13. Status: the maintainer approved the design in chat. An
EGM review (Stages 5 to 8) followed, with reports in
`docs/superpowers/reviews/2026-11-13-lifecycle-*.md`. This version applies
its findings and the maintainer's answers.

## Purpose

Design version 1 in `docs/design.md` ships as release 1.0.0. It is too
large for one plan, so it is built in four slices. Each slice has its own
spec, plan and PRs, and each slice is playable in the game on its own:

1. **Lifecycle** (this spec): breeding pod, eggs, feeds, hatching, nest
   loot and the Monster husbandry research.
2. **Ordnance**: incubator, larvae, loading chamber, loaded-larva
   prototypes, death effects, the acid cloud and the Ordnance loading
   research.
3. **Delivery**: long-range rocket ammo, the launcher for the base game
   and the Larva rockets research.
4. **Control**: feral behaviour, the stasis ward and the Stasis ward
   research.

Release 1.0.0 follows slice 4.

Goals of this slice:

1. A player can get biter and spitter eggs and breed them.
2. Eggs that spoil hatch a wild monster of their own species. The size
   follows enemy evolution.
3. Everything works the same with and without Space Age. The exceptions
   are the graphics and working sound of the breeding pod, and one extra
   recipe in Space Age.

Terms:

- **The maintainer** is vetkat, who owns the repository and approves every
  merge and release.
- **The agent** is Claude Code in this repository.
- **Species** means biter or spitter in this slice.
- **Hatch** means to create a monster from an item that spoils.
- **Wild** means on the `enemy` force. Feral behaviour is a different
  thing and comes in slice 4.
- **The core** is the pure Lua modules in `core/`, which never touch the
  game API. **The shell** is `data.lua` and the event handlers in
  `control.lua`, which call the core. `docs/architecture.md` has the
  rules.

## Facts found during design

The agent checked these facts on 2026-11-13. The sources are the Factorio
2.1.24 data files (`base` and `space-age`) and the Factorio wiki.

- Space Age has one egg-breeding recipe, `pentapod-egg`. It runs in the
  biochamber at Gleba pressure: 1 pentapod egg, 30 nutrients and 60 water
  make 2 pentapod eggs. The egg ingredient has `ignored_by_stats = 1`. The
  egg result has `ignored_by_stats = 1`, `ignored_by_productivity = 1` and
  `reset_freshness_on_craft = true`.
- Space Age has no recipe that breeds biter eggs. The captive biter
  spawner has one fixed recipe, `biter-egg`. Promethium science, the
  overgrowth soils and other recipes use `biter-egg`.
- `biter-egg` spoils in 30 minutes. Its `spoil_to_trigger_result` has
  `items_per_trigger = 25` and creates a `big-biter` on the enemy force at
  a free position. It does nothing on a space platform.
- `pentapod-egg` spoils in 15 minutes. It has `items_per_trigger = 1` and
  creates a `big-wriggler-pentapod-premature`.
- The wiki agrees on the spoil times and on what hatches. It gives no
  ratio for either egg.
- The base game has no biochamber, no nutrients and no `biter-egg`.
- The base `biter-spawner` and `spitter-spawner` list their units with
  evolution points. The `spitter-spawner` list starts with `small-biter`
  from evolution 0 to 0.35. `small-spitter` starts at 0.25.
- A comment in `base/prototypes/entity/enemies.lua` gives the weight
  rule. The weight is linear between two points and stays at the end
  value beyond the last point. The spawn chance of a unit is its weight
  divided by the sum of all weights.

## Decisions

| Question | Decision | Rejected, and why |
| --- | --- | --- |
| Egg items | The mod has its own `ao-biter-egg` and `ao-spitter-egg` in both modes. | Reuse Space Age's `biter-egg`: the base game does not have it, and mass breeding would undercut promethium science. |
| Captive spawner | It is not changed. In Space Age, an adopt recipe turns one `biter-egg` into one `ao-biter-egg`. | A second recipe on the spawner: it means editing a fixed recipe of a Space Age entity. |
| First eggs | Native spawners drop eggs when they die, after the killer's force researches Monster husbandry. | Prototype `loot` with no gate: artillery and turret creep would scatter eggs before the player uses the mod. |
| Breeding machine | The mod's own breeding pod in both modes. In Space Age it borrows the biochamber graphics. | The biochamber: the base game does not have it, so the two modes would differ. |
| Feed | Two crafted feeds: monster chow and spitter chow. | Raw fish: fish is scarce and caps breeding. One feed for both: less flavour. |
| Hatch size | Picked from the enemy evolution, over a fixed table of the species' own units. | Always small: it ignores the game's progress. Egg tiers: four times the items. Reading the spawner at runtime: the spitter spawner lists biters, so spitter eggs would hatch biters. |
| Hatch method | Native spoilage with a `script` trigger effect. A pure core module picks the unit. | A plain `create-entity` trigger, as Space Age uses: it cannot follow evolution. Script timers: they fight the engine and the stasis ward of slice 4. |
| Hatch ratio | 10 eggs hatch one monster (`items_per_trigger = 10`). The probe measures how this works in the game. | One per egg: a stack of 100 eggs at high evolution would hatch 100 behemoths. 25, as Space Age: eggs would be too safe. |
| Incubator and larvae | They move to slice 2. | Slice 1: larvae have no use yet and hatch one to one, which undoes the egg ratio. |
| Graphics | `data.lua` passes the vanilla machine graphics and sound to the builder, which tints a copy. The mod copies no game files. | Writing the sprite fields by hand: long, and a moved sprite in a game update breaks the mod. |
| Music | None in this slice. The music starts with the jazz pods of version 2. | The maintainer chose this. |
| Prototype names | All new prototypes start with `ao-`. | |

## Changes to `docs/design.md`

PR 1 makes these edits:

1. Monsters table: spitters come from nest loot and the breeding pod, not
   from a captive spawner with a spitter-feed recipe.
2. Monsters table: in the base game, biters come from nest loot. In Space
   Age, the captive spawner adds a second source through the adopt
   recipe.
3. Technical notes, spoiling and hatching: the hatch uses a `script`
   trigger and a core module, so the size follows evolution.
4. Monsters table: pentapods use Space Age's own `pentapod-egg` and its
   biochamber recipe. This takes effect in version 2.

## Game content

Every number in this section is a first guess. All numbers of this slice
live in `core/balance.lua`. The plan sets the numbers that this section
does not give.

### Items

| Item | Stack | Spoils in | When it spoils |
| --- | --- | --- | --- |
| `ao-biter-egg` | 100 | 30 min | Every 10 eggs hatch a wild biter |
| `ao-spitter-egg` | 100 | 30 min | Every 10 eggs hatch a wild spitter |
| `ao-monster-chow` | 100 | Does not spoil | Nothing |
| `ao-spitter-chow` | 100 | Does not spoil | Nothing |

A spoiled egg leaves no item behind.

`info.json` gets `"feature_flags": ["spoiling"]`, so items spoil in the
base game too.

### Breeding pod

The breeding pod (`ao-breeding-pod`) is an electric assembling machine
with its own crafting category, `ao-breeding`. It has no module slots. An
assembler crafts it from iron plates, steel, pipes and electronic
circuits.

In Space Age it copies the graphics and working sound of the biochamber,
with a tint. In the base game it copies those of the chemical plant, with
a tint. Its footprint and fluid boxes are its own, so they are the same in
both modes.

### Recipes

| Recipe | Machine and time | Ingredients | Results |
| --- | --- | --- | --- |
| `ao-monster-chow` | Chemical plant, 2 s | 1 `coal`, 1 `sulfur`, 20 `water` | 2 `ao-monster-chow` |
| `ao-spitter-chow` | Chemical plant, 2 s | 1 `ao-monster-chow`, 10 `sulfuric-acid` | 1 `ao-spitter-chow` |
| `ao-breed-biter` | Breeding pod, 15 s | 1 `ao-biter-egg`, 5 `ao-monster-chow` | 2 `ao-biter-egg` |
| `ao-breed-spitter` | Breeding pod, 15 s | 1 `ao-spitter-egg`, 5 `ao-spitter-chow` | 2 `ao-spitter-egg` |
| `ao-adopt-biter-egg` (Space Age only) | Breeding pod, 5 s | 1 `biter-egg`, 1 `ao-monster-chow` | 1 `ao-biter-egg` |
| `ao-breeding-pod` | Assembler | Iron plates, steel, pipes, electronic circuits | 1 `ao-breeding-pod` |

The two breeding recipes use the same flags as `pentapod-egg`. The egg
ingredient has `ignored_by_stats = 1`. The egg result has
`ignored_by_stats = 1`, `ignored_by_productivity = 1` and
`reset_freshness_on_craft = true`. So a bred egg starts fresh. The
breeding and adopt recipes also set `auto_recycle = false`, as both
vanilla egg recipes do, so Space Age's recycler cannot turn eggs back into
their ingredients.

### Research

Monster husbandry (`ao-monster-husbandry`) uses automation, logistic,
military and chemical science packs. Its prerequisites are Military
science pack and Chemical science pack. It unlocks the breeding pod
and every recipe above. It also turns on egg loot from native spawners
for the force that researches it.

## Runtime behaviour

### Species table

One core table describes each species: its egg item, its feed, its
spawner name, its hatch effect ID and its hatch units. The hatch units are
the species' own units from the vanilla spawner, with the vanilla
evolution points:

| Species | Spawner | Hatch units |
| --- | --- | --- |
| Biter | `biter-spawner` | `small-biter`, `medium-biter`, `big-biter`, `behemoth-biter` |
| Spitter | `spitter-spawner` | `small-spitter`, `medium-spitter`, `big-spitter`, `behemoth-spitter` |

The prototype builder, hatching and nest loot all read this table.

### Hatching

1. Each egg has a `spoil_to_trigger_result` with `items_per_trigger = 10`.
   The trigger runs a `script` trigger effect. The effect ID names the
   species, for example `ao-hatch-biter`.
2. The shell handles `on_script_trigger_effect`. It reads the surface and
   the position from the event, and the evolution of the `enemy` force on
   that surface. It takes a number in [0, 1) from the mod's random
   generator.
3. `core/hatching.lua` takes the species, the evolution factor and the
   number, and returns a unit name. It applies the vanilla weight rule
   from Facts to the species' hatch units. When every weight is 0, it
   returns the first unit of the species. For spitters this happens below
   evolution 0.25, and the result is `small-spitter`.
4. The shell finds a free position near the event position and creates
   the unit on the `enemy` force.
5. Nothing hatches when the event gives no usable surface or position,
   when the surface is a space platform, or when there is no free
   position.

Eggs that spoil on another planet hatch there, with the evolution of that
surface. Space Age's `biter-egg` behaves the same way.

The shell keeps a seed number in `storage`. For each random number it
makes a generator with `game.create_random_generator(seed)`, takes one
number, and stores the next seed from the same generator. A missing seed
starts at 1. So the control stage stays deterministic, and `storage` holds
only a number.

### Nest loot

1. The shell handles `on_entity_died`, with a filter for the type
   `unit-spawner`.
2. When the event has no force, nothing drops. When the force has not
   researched Monster husbandry, nothing drops.
3. `core/loot.lua` finds the species whose spawner has the dead spawner's
   name. A spawner of no species drops nothing.
4. `core/loot.lua` turns a random number into a count from 1 to 3.
5. The shell spills that many eggs of the species at the spawner's
   position, as one stack that a player picks up by walking over it.

### Core modules

| Module | Job |
| --- | --- |
| `core/names.lua` | Prototype names that several modules use. |
| `core/balance.lua` | Every number in this slice, including the hatch ratio, the loot range and the research cost. |
| `core/species.lua` | The species table. |
| `core/hatching.lua` | Picks a unit from a species, an evolution factor and a random number. |
| `core/loot.lua` | Maps a spawner to a species, and a random number to an egg count. |
| `core/prototypes/lifecycle.lua` | Builds every prototype table of this slice. |

### Data stage

`data.lua` stays a short shell. It passes the source machine's graphics
and working sound to the builder, which tints a copy:

```lua
local Lifecycle = require("core.prototypes.lifecycle")
local source = mods["space-age"] and data.raw["assembling-machine"]["biochamber"]
  or data.raw["assembling-machine"]["chemical-plant"]
data:extend(Lifecycle.prototypes({
  space_age = mods["space-age"] ~= nil,
  graphics_set = source.graphics_set,
  working_sound = source.working_sound,
}))
```

`core/prototypes/lifecycle.lua` is pure. It works only on its parameters.
busted runs it with stub tables and with no `data`, `mods` or `settings`
globals. So a builder that reads those globals fails its tests.

## Testing

### Unit tests (busted, part of `make fast`)

- `core/hatching.lua`:
   - the weight rule below the first point, between two points and beyond
     the last point, with exact values from the species table
   - a spitter at evolution 0 gives `small-spitter`
   - the pick at 0 and just below 1
- `core/loot.lua`:
   - both spawner names, and an unknown spawner
   - the count at 0 and just below 1
- `core/prototypes/lifecycle.lua`, built with Space Age on and off:
   - The adopt recipe exists only with Space Age.
   - The pod uses the graphics set and working sound from its
     parameters, with a tint.
   - The breeding recipes carry the flags of `pentapod-egg`.
   - Every ingredient and result is an item of this slice or one of
     `biter-egg`, `coal`, `sulfur`, `water` and `sulfuric-acid`.
   - Every item, entity, recipe and technology has a locale entry in
     `locale/en/locale.cfg`. The test uses `L.value` from
     `spec/support/locale.lua`.
- The existing architecture test keeps `core/` free of the game API. The
  coverage floor applies to the new modules.

### In-game tests (factorio-test, part of `make check`, both modes)

- The new items, the pod, the recipes and the research exist.
- The test forces 10 eggs in a chest to spoil at once. One unit of the
  egg's species appears near the chest.
- A biter spawner killed by a force with the research spills 1 to 3
  biter eggs. Without the research it spills none.
- A breeding pod with 1 egg and 5 chow makes 2 eggs.
- With the factorio-test tag `space-age`: the adopt recipe exists and
  makes an egg.

## Delivery

### Probe

The first plan task is a throwaway in-game probe. It answers these
questions, and the spec records the answers:

1. Does a `script` trigger from spoilage give a usable surface and
   position? The probe checks eggs in a chest and eggs on the ground,
   because nest loot lies on the ground. It records which event fields
   are set.
2. Which API call forces a spoil in a test?
3. What happens when fewer than 10 eggs spoil: one hatch, or none?
4. In the Space Age run, what hatches when 25 `biter-egg` items and 1
   `pentapod-egg` spoil in a chest?
5. What is the frame time when a full chest of eggs spoils at once?

If the probe shows that eggs below 10 never hatch, eggs left on the
ground vanish without a monster. The maintainer then chooses between that
and a random hatch per egg with a chance of 1 in 10 in the core. If the
probe shows that the trigger gives no usable position, the plan stops
before PR 2 and the spec changes.

### Pull requests

The slice ships in three PRs. Each PR title is a Conventional Commit, and
each PR adds an entry under Unreleased in `CHANGELOG.md`:

1. Content: items, the pod, recipes, research and the changes to
   `docs/design.md`.
2. Hatching.
3. Nest loot.

In the base game, eggs exist only after PR 3. The maintainer accepts
this, because only the slice as a whole has to be playable.

`ROADMAP.md` changes in PR 1:

- The item "Breeding pod and incubator" gets a note: slice 1 delivers
  the pod, and slice 2 the incubator. The item ticks in slice 2.
- The item "Spoil outcomes" stays open until slice 2 adds larvae. This
  slice delivers egg hatching.

## Risks

| Risk | Answer |
| --- | --- |
| The `script` trigger gives no usable position. | The probe checks it first. Without a position, nothing hatches, and the plan stops before PR 2. |
| A stack of 100 eggs that spoils at high evolution hatches 10 monsters, most of them big or behemoth. | This is the intended risk. The ratio lives in `core/balance.lua`. |
| Fewer than 10 eggs may never hatch. | The probe measures it. The fallback is a random hatch per egg. |
| A warehouse of eggs that spoils at once causes a frame spike. | The probe measures the frame time. 10 eggs per trigger already cuts the events by ten. |

## Open questions

- **Do loot eggs ever hatch?** Nest loot is always 1 to 3 eggs, one
  stack below the ratio of 10. The probe finds what a stack below 10
  does when it spoils. With no hatch, loot eggs that a player leaves
  behind vanish. With one hatch, every loot pile hatches one monster.

  The maintainer decides after the probe. If the maintainer wants
  neither result, the fallback is a random hatch per egg, with a chance
  of 1 in 10.

## Out of scope

- The incubator, larvae, loading and payloads (slice 2).
- Launchers and ammo (slice 3).
- Feral behaviour and the stasis ward (slice 4).
- Worms, pentapods and demolisher hatchlings (versions 2 and 3).
- Original graphics. This slice uses tinted copies of vanilla graphics.
- Music (version 2, with the jazz pods).
