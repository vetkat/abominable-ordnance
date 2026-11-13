# Abominable Ordnance: slice 1, lifecycle

Date: 2026-11-13. Status: the maintainer approved the design in chat. The
spec waits for the maintainer's review and an EGM review.

## Purpose

Design version 1 ships as release 1.0.0. It is too large for one plan, so
it is built in four slices. Each slice has its own spec, plan and PRs, and
each slice is playable in the game on its own:

1. **Lifecycle** (this spec): breeding pod, incubator, eggs and larvae,
   hatching, nest loot and the Monster husbandry research.
2. **Ordnance**: loading chamber, loaded-larva prototypes, death effects,
   the acid cloud and the Ordnance loading research.
3. **Delivery**: long-range rocket ammo, the vanilla launcher and the
   Larva rockets research.
4. **Control**: feral behaviour, the stasis ward and the Stasis ward
   research.

Release 1.0.0 follows slice 4.

Goals of this slice:

1. A player can get biter and spitter eggs, breed them, and turn them into
   larvae.
2. Eggs and larvae that spoil hatch a wild monster. The size follows enemy
   evolution.
3. Everything works the same with and without Space Age. The only
   exceptions are the graphics of the breeding pod and one extra recipe in
   Space Age.

Terms:

- **The maintainer** is vetkat, who owns the repository and approves every
  merge and release.
- **The agent** is Claude Code in this repository.
- **Species** means biter or spitter in this slice.
- **Hatch** means to create a monster from an item that spoils.
- **The shell** and **the core** have the meanings in
  `docs/architecture.md`.

## Facts found during design

The agent checked these facts in the Space Age 2.1.24 data files on
2026-11-13.

- Space Age has one egg-breeding recipe, `pentapod-egg`. It runs in the
  biochamber at Gleba pressure: 1 pentapod egg, 30 nutrients and 60 water
  make 2 pentapod eggs. The result has `reset_freshness_on_craft = true`.
  The egg has `ignored_by_stats` and the result has
  `ignored_by_productivity`.
- Space Age has no recipe that breeds biter eggs. The captive biter
  spawner has one fixed recipe, `biter-egg`. Promethium science, the
  overgrowth soils and other recipes use `biter-egg`.
- `biter-egg` spoils in 30 minutes. Its `spoil_to_trigger_result` creates
  one `big-biter` per 25 eggs (`items_per_trigger = 25`), on the enemy
  force, at a free position. It does nothing over space.
- The base game has no biochamber, no nutrients and no `biter-egg`.

## Decisions

| Question | Decision |
| --- | --- |
| Egg items | The mod has its own `ao-biter-egg` and `ao-spitter-egg` in both modes. |
| Captive spawner | It is not changed. In Space Age, an adopt recipe turns one `biter-egg` into one `ao-biter-egg`. This keeps the balance of promethium science. |
| First eggs | Native spawners drop eggs when they die, after the killer's force researches Monster husbandry. |
| Breeding machine | The mod's own breeding pod in both modes. In Space Age it borrows the biochamber graphics. The biochamber cannot run the breeding recipes, so all breeding plays the jazz. |
| Feed | Two crafted feeds: monster chow and spitter chow. |
| Hatch size | The script picks the unit from the enemy evolution on the surface, with the weights of the vanilla spawner. |
| Hatch method | Native spoilage with a `script` trigger effect. A pure core module picks the unit. |
| Hatch ratio | One item hatches one monster. `items_per_trigger` is the lever if this is too harsh. |
| Graphics | Tinted vanilla and Space Age sprites, referenced by path. The mod copies no game files. |
| Jazz | A CC BY or CC0 track that the maintainer picks. A vanilla machine sound is the placeholder until then. |
| Prototype names | All new prototypes start with `ao-`. |

## Game content

Every number in this section is a first guess. All numbers live in
`core/balance.lua`.

### Items

| Item | Stack | Spoils in | When it spoils |
| --- | --- | --- | --- |
| `ao-biter-egg` | 100 | 30 min | Hatches a wild biter |
| `ao-spitter-egg` | 100 | 30 min | Hatches a wild spitter |
| `ao-biter-larva` | 50 | 10 min | Hatches a wild biter |
| `ao-spitter-larva` | 50 | 10 min | Hatches a wild spitter |
| `ao-monster-chow` | 100 | Does not spoil | Nothing |
| `ao-spitter-chow` | 100 | Does not spoil | Nothing |

In this slice a larva has no use yet. Slice 2 loads it.

`info.json` gets `"feature_flags": ["spoiling"]`, so items spoil in the
base game too.

### Machines

Both machines are electric assembling machines with a crafting category of
their own. An assembler crafts each one from iron plates, steel, pipes and
electronic circuits.

- **Breeding pod** (`ao-breeding-pod`, category `ao-breeding`). In Space
  Age it uses the biochamber graphics with a tint. In the base game it uses
  the chemical plant graphics with a tint. Its `working_sound` is the jazz
  loop, with an audible distance of about 6 tiles. The startup setting
  `ao-jazz` (default on) turns the jazz off. The pod then uses a vanilla
  machine sound.
- **Incubator** (`ao-incubator`, category `ao-incubation`). It uses a
  tinted vanilla sprite.

### Recipes

| Recipe | Machine and time | Ingredients | Results |
| --- | --- | --- | --- |
| `ao-monster-chow` | Chemical plant, 2 s | 1 coal, 1 sulfur, 20 water | 2 monster chow |
| `ao-spitter-chow` | Chemical plant, 2 s | 1 monster chow, 10 sulfuric acid | 1 spitter chow |
| `ao-breed-biter` | Breeding pod, 15 s | 1 biter egg, 5 monster chow | 2 biter eggs |
| `ao-breed-spitter` | Breeding pod, 15 s | 1 spitter egg, 5 spitter chow | 2 spitter eggs |
| `ao-incubate-biter` | Incubator, 10 s | 1 biter egg | 1 biter larva |
| `ao-incubate-spitter` | Incubator, 10 s | 1 spitter egg | 1 spitter larva |
| `ao-adopt-biter-egg` (Space Age only) | Breeding pod, 5 s | 1 `biter-egg`, 1 monster chow | 1 biter egg |

The two breeding recipes copy the flags of `pentapod-egg`. The egg
ingredient has `ignored_by_stats = 1`. The egg result has
`ignored_by_stats = 1`, `ignored_by_productivity = 1` and
`reset_freshness_on_craft = true`. So productivity does not copy eggs, and
a bred egg starts fresh.

### Research

**Monster husbandry** (`ao-monster-husbandry`) needs military and
chemical science packs. Its prerequisites are Military 2 and Sulfur
processing. It unlocks the two machines and every recipe above. It also
turns on egg loot from native spawners for the force that researches it.

## Runtime behaviour

### Hatching

1. Each egg and larva has a `spoil_to_trigger_result` with
   `items_per_trigger = 1`. The trigger runs a `script` trigger effect.
   The effect ID names the species, for example `ao-hatch-biter`.
2. The shell handles `on_script_trigger_effect`. It reads the surface and
   the position from the event. It reads the evolution of the `enemy`
   force on that surface. It reads `result_units` of the species' spawner
   prototype at runtime, so a mod that changes the spawner table also
   changes the hatch. It takes a number from the mod's random generator.
3. `core/hatching.lua` takes the species' unit table, the evolution factor
   and the random number. It returns a unit name, or nil. It interpolates
   the weights between spawn points in the same way as the engine.
4. The shell finds a free position near the event position and creates
   the unit on the `enemy` force. On a space platform, or with no free
   position, it does nothing. This is how Space Age handles `biter-egg`.

The mod makes its random generator with `game.create_random_generator()`
in `on_init`, and keeps it in `storage`. `on_configuration_changed` makes
one if it is missing. So the control stage stays deterministic.

### Nest loot

1. The shell handles `on_entity_died`, with a filter for the type
   `unit-spawner`.
2. When the event has no force, nothing drops. When the force has not
   researched Monster husbandry, nothing drops.
3. `core/loot.lua` maps the spawner name to a species: `biter-spawner` to
   biter and `spitter-spawner` to spitter. Any other spawner gives no
   species and nothing drops.
4. `core/loot.lua` turns a random number into a count from 1 to 3.
5. The shell spills that many eggs of the species at the spawner's
   position.

### Core modules

| Module | Job |
| --- | --- |
| `core/balance.lua` | Every number in this slice: spoil times, stack sizes, recipe amounts and times, loot range, jazz distance. |
| `core/hatching.lua` | Picks a unit from a unit table, an evolution factor and a random number. |
| `core/loot.lua` | Maps a spawner to a species, and a random number to an egg count. |
| `core/prototypes/lifecycle.lua` | Builds every prototype table of this slice. |

### Data stage

`data.lua` stays a short shell:

```lua
local Lifecycle = require("core.prototypes.lifecycle")
data:extend(Lifecycle.prototypes({
  space_age = mods["space-age"] ~= nil,
  jazz = settings.startup["ao-jazz"].value,
}))
```

`core/prototypes/lifecycle.lua` is pure. It gets the two flags as
parameters and never reads `data`, `mods` or `settings`. So busted can
build the prototypes for both modes. The Space Age parts are the
biochamber graphics and the adopt recipe.

`settings.lua` defines the startup setting `ao-jazz`.

## Notes for version 2

Version 2 adds pentapods. They should use Space Age's own `pentapod-egg`
and its biochamber recipe, not a copy. `docs/design.md` says "Pentapod
eggs from Gleba nests" and gets that correction in version 2.

## Testing

### Unit tests (busted, part of `make fast`)

- `core/hatching.lua`:
   - the weights below the first spawn point, between two points and above
     the last point
   - the pick at the two ends of the random range
   - an empty table, which gives nil
- `core/loot.lua`: both spawner names, an unknown spawner, and the count
  range at the two ends of the random range.
- `core/prototypes/lifecycle.lua`, built with Space Age on and off:
   - Every recipe ingredient and result names an item or fluid that exists
     in the base game, in Space Age or in this slice.
   - The adopt recipe exists only with Space Age.
   - The pod graphics come from the biochamber only with Space Age.
   - The `jazz` flag changes the pod's `working_sound`.
   - The breeding recipes carry the flags of `pentapod-egg`.
   - Every item, entity, recipe, technology and setting has a locale
     entry in `locale/en/locale.cfg`. This is a new test. The existing
     `spec/locale_spec.lua` checks only the syntax of the file.
- The existing architecture test keeps `core/` pure. The coverage floor
  applies to the new modules.

### In-game tests (factorio-test, part of `make check`, both modes)

- The new items, machines, recipes and the research exist.
- The test forces an egg in a chest to spoil at once. A unit of the
  right species appears near the chest. The first plan task finds the API
  call that forces the spoil, for example `LuaItemStack.spoil()` or a write to
  `spoil_percent`.
- A biter spawner killed by a force with the research spills 1 to 3
  biter eggs. Without the research it spills none.
- A breeding pod with 1 egg and 5 chow makes 2 eggs.
- With the tag `space-age`: the adopt recipe exists and makes an egg.

## Delivery

The plan starts with the largest risk. Its first task is a throwaway
in-game probe. It checks that a `script` trigger from spoilage inside a
chest gives a usable surface and position. It also finds the call that
forces a spoil in a test. If it does not, the shell uses the position of the
inventory's owner entity, and this spec gets an update.

The slice ships in four PRs. Each PR title is a Conventional Commit, and
each PR adds an entry under Unreleased in `CHANGELOG.md`:

1. Content: items, machines, recipes, research and the `ao-jazz` setting,
   with the placeholder sound.
2. Hatching.
3. Nest loot.
4. The jazz track. Its licence must allow redistribution in a mod. CC BY
   attribution goes in `THIRD_PARTY.md`. The loop is a mono `.ogg` of 20
   to 40 seconds that loops without a gap.

PR 4 waits for the maintainer to pick the track. PRs 1 to 3 do not wait.
Candidates found on 2026-11-13: Sascha Ende, "Sexy Scene Instrumentals"
volumes 9 and 10 (CC BY 4.0, attribution optional by the author).

`ROADMAP.md`: PR 4 ticks "Breeding pod with the smooth jazz sound, and
incubator", because the item names the jazz. The item "Spoil outcomes"
stays open until slice 2 adds loaded larvae. This slice does its egg half.

## Risks

| Risk | Answer |
| --- | --- |
| A `script` trigger from spoilage in an inventory gives no usable position. | The first plan task tests it. The fallback is the owner entity's position. |
| One-to-one hatching swarms a base when a chest of eggs spoils. | This is the intended risk. `items_per_trigger` in `core/balance.lua` can soften it. |
| Spawner loot clutters the front for artillery players. | Loot needs the research. Eggs that are left behind hatch, which removes them. |
| The biochamber graphics change in a later Space Age version. | The builder references them by path. The in-game test in the Space Age run fails when a path is gone. |

## Out of scope

- Loading, payloads and loaded larvae (slice 2).
- Launchers and ammo (slice 3).
- Feral behaviour and the stasis ward (slice 4).
- Worms, pentapods and demolisher hatchlings (versions 2 and 3).
- Original graphics. This slice uses tinted sprites.
