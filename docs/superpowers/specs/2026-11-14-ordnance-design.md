# Abominable Ordnance: slice 2, ordnance

Date: 2026-11-14. Status: approved. The agent wrote this spec overnight
from `docs/design.md` and the slice 1 spec, at the maintainer's request.
An EGM review (Stages 5 to 8) followed, with reports in
`docs/superpowers/reviews/2026-11-14-ordnance-*.md`.

On 2026-11-14 the maintainer accepted the agent's proposal for each of
Q1 to Q8 and asked for the plan and the build. "Answers" lists the
choices.

## Purpose

Slice 2 of design version 1 turns eggs into ammunition. The slice list
is in `docs/superpowers/specs/2026-11-13-lifecycle-design.md` (the slice
1 spec). This slice adds the incubator, larvae, the loading chamber,
loaded larvae, the loaded monster with its death effects, the acid trail
and the Ordnance loading research.

Goals of this slice:

1. A player can turn eggs into larvae, and larvae into loaded larvae
   with one of three payloads: explosive rocket, sulfuric acid barrel or
   poison capsule.
2. A loaded larva that spoils becomes its loaded monster where it
   spoils. The monster attacks the natives near it, and its payload
   triggers when it dies.
3. A larva with no payload that spoils hatches a wild monster, as an egg
   does.
4. Everything works the same with and without Space Age, except the
   machine graphics.

Slice 2 has no launcher (slice 3) and no feral behaviour or stasis ward
(slice 4). So in this slice a player delivers a loaded larva by hand.

Terms are as in the slice 1 spec. In particular, **the egg ratio** is
`items_per_trigger = 10` on eggs: every 10 spoiled eggs hatch one
monster. **The natives** are the `enemy` force. **Both modes** means with
and without Space Age. New terms:

- **Larva**: the ammunition stage of a species. An incubator makes it
  from eggs.
- **Payload**: the ordnance item in a loaded larva.
- **Loaded larva**: an item for one species and one payload.
- **Loaded monster**: the unit that a loaded larva becomes. It is on the
  tamed force and carries its payload.
- **Tamed force**: a new force, `ao-tamed`. It is hostile to `enemy` and
  at cease-fire with every player force.
- **Acid trail**: the live effect of an acid-loaded monster. It leaves a
  small acid puddle under the monster at a fixed interval.

## Facts found during design

The agent checked these facts on 2026-11-14 in the Factorio 2.1.24 data
files (`base`) and the API annotations.

- `explosive-rocket` and `poison-capsule` are both an item and a
  projectile of the same name. The `poison-capsule` projectile creates a
  `poison-cloud` entity where it lands.
- The base game generates `sulfuric-acid-barrel` in its
  `data-updates.lua`, from the fluid. A recipe in the mod's `data.lua`
  can name it, because the game checks recipe ingredients after the last
  data stage.
- `explosive-rocketry` unlocks the explosive rocket and needs `rocketry`
  and `military-3`.
- `base` has `acid-splash-fire-spitter-small` up to
  `acid-splash-fire-spitter-behemoth`: the acid puddles that spitters
  leave.
- A mod has one handler per event. A second `script.on_event` call for
  the same event replaces the first, even with other filters.
- `LuaSurface.create_entity` puts a new entity on the `enemy` force
  unless the call names a force.

From the mod's own code: `Hatching.pick` and `Hatching.available` pick a
unit by evolution from the species table, and `control.lua` already has
an `on_entity_died` handler for nest loot. Slice 2 reuses both.

The agent did not check these facts in Space Age. The probe does.

## Decisions (proposed)

| Topic | Proposal | Rejected, and why |
| --- | --- | --- |
| Larva ratio (Q1) | The incubator makes 1 larva from 10 eggs. A larva hatches 1 monster. | 1 egg to 1 larva: 10 eggs then make 10 monsters, and the incubator undoes the egg ratio. |
| Loaded monster (Q2) | A vanilla unit, created by the shell. `storage` keeps its payloads by unit number. | One unit prototype per species, size and payload (2 × 4 × 3 = 24 now, hundreds later): `docs/design.md` warns about prototype count. One tinted copy per species and size (8 now): more prototypes for a visual cue only. |
| Death effects | The shell creates vanilla entities where the monster dies: the `explosive-rocket` projectile aimed at the death spot, a `poison-cloud`, or an acid puddle. Each is on `ao-tamed`, with the monster as its cause. | New explosion prototypes: more files, and they drift from vanilla balance. |
| Acid trail | At a fixed interval the shell creates a small acid puddle under each acid-loaded monster. | A smoke that follows the unit: the agent did not check if the game has one. A smoke made again at each interval also works. |
| Monster size (Q3) | The loaded monster's size follows enemy evolution, with the slice 1 table. | Always small: a small biter dies too fast for its payload to matter. Tiers per larva: four times the items. |
| Force (Q4) | Loaded monsters join `ao-tamed`. They attack only natives. Their death effects may hurt the player's buildings. | The player force: the player cannot then tell their army from their monsters. |
| Machines (Q5) | The incubator borrows the centrifuge graphics. The loading chamber borrows assembling machine 3. Both are tinted, in both modes. | Both on the biochamber in Space Age: three machines would look the same, and the base game has no biochamber. |
| Research | Monster husbandry also unlocks the incubator and its recipes, as the research tree in `docs/design.md` shows. A new technology, Ordnance loading, unlocks the loading chamber and the load recipes. | A separate incubator technology: it adds a research step with no new choice. |
| Research prerequisites | Ordnance loading needs Monster husbandry and `explosive-rocketry`. `explosive-rocketry` unlocks the explosive rocket, and its own prerequisite `military-3` unlocks the poison capsule. | Monster husbandry alone: the player could build the chamber before they can make two of the payloads. |
| Loaded larva items | `core/prototypes/ordnance.lua` generates them from two lists: species and payloads. Six items in this slice. | `item-with-tags`: tags do not stack, and normal recipes cannot make them. |
| Delivery in this slice (Q6) | By hand: the player drops the loaded larva near the target and walks away. It spoils there. | A thrown capsule: slice 3 decides how loaded larvae travel. |
| Payload items (Q7) | 1 filled barrel per acid load. The barrel is used up. | Return the empty barrel: Ordnance loading would also need `fluid-handling`. |
| Nest loot from monster kills (Q8) | A nest that `ao-tamed` kills drops eggs, as if a researched force killed it. | No eggs from monster kills: the mod's own weapon would stop the egg supply. |
| Space platforms | Larvae and loaded larvae that spoil on a platform are used up and create nothing, as eggs are. | Hatch on platforms: a monster on a platform has nothing to attack and can damage the platform. |

The maintainer accepted every row on 2026-11-14.

## Game content

Every number is a first guess and lives in `core/balance.lua`. The plan
sets the numbers that this section does not give.

### Items

| Item | Stack | Spoils in | When it spoils |
| --- | --- | --- | --- |
| `ao-biter-larva`, `ao-spitter-larva` | 20 | 10 min | Each larva hatches one wild monster of its species |
| `ao-<species>-larva-<payload>` (6 items) | 10 | 5 min | Each item becomes one loaded monster on `ao-tamed` |

`<payload>` is `explosive`, `acid` or `poison`. A spoiled larva leaves no
item behind. The spoil trigger uses `items_per_trigger = 1`.

### Machines

| Machine | Graphics | Crafting category | Module slots |
| --- | --- | --- | --- |
| `ao-incubator` | Centrifuge, tinted | `ao-incubation` | None |
| `ao-loading-chamber` | Assembling machine 3, tinted | `ao-loading` | None |

Both machines use electricity and have no fluid boxes.

### Recipes

| Recipe | Machine | Ingredients | Result | Unlocked by |
| --- | --- | --- | --- | --- |
| `ao-incubate-<species>` | Incubator | 10 eggs | 1 larva | Monster husbandry |
| `ao-load-<species>-<payload>` | Loading chamber | 1 larva and 1 payload item | 1 loaded larva | Ordnance loading |
| `ao-incubator` | Assembler | Steel, electronic circuits, pipes | Incubator | Monster husbandry |
| `ao-loading-chamber` | Assembler | Steel, advanced circuits, iron gear wheels | Loading chamber | Ordnance loading |

Every larva and loaded larva result resets freshness, as Space Age does
for `pentapod-egg`. The incubate and load recipes have
`auto_recycle = false`, so Space Age's recycler cannot turn a larva back
into eggs.

## Runtime behaviour

### Tamed force

1. In `on_init` and `on_configuration_changed`, the shell creates
   `ao-tamed` if it is missing. It sets cease-fire both ways between
   `ao-tamed` and every player force, and keeps `ao-tamed` hostile to
   `enemy`.
2. In `on_force_created`, the shell sets cease-fire both ways between
   the new force and `ao-tamed`.

### Spawning a monster

Slice 1 gives every hatched monster an `attack_area` command around its
hatch spot. Without a command, a unit stands still until something
provokes it. Every hatch in this slice uses the same spawn step: pick
the unit, find a free position, create the unit on a force, and give it
the command.

### Larva hatch

A larva uses its species' egg effect ID, with one item per trigger. So
the slice 1 hatch handler hatches it as it hatches eggs (changed during
the build, after the simplify review).

### Loaded hatch

1. A loaded larva spoils and fires its `script` effect. Each of the six
   items has its own effect ID. A pure lookup gives the species and the
   payload for an ID.
2. The shell picks the unit by evolution from the species table, finds a
   free position near the spoil position, and creates the unit on
   `ao-tamed`.
3. The shell spawns the unit as above. It also sets the unit's AI so the
   engine does not destroy it when a command fails.
4. The shell stores the payload list (one payload in this slice) in
   `storage` by unit number, and registers the unit with
   `script.register_on_object_destroyed`.
5. With no surface, no position, or on a space platform, nothing
   happens.

### Death

1. The one `on_entity_died` handler has two filters: unit spawners for
   nest loot, and units for loaded monsters. It sends each death to the
   right path. Nest loot counts a kill by `ao-tamed` as a kill by a
   researched force (Q8).
2. For a unit with a `storage` entry, a pure core function turns the
   payload list and the death position into a list of entities to
   create. The shell creates each one on `ao-tamed`, with the dead unit
   as the cause.
3. The `on_object_destroyed` handler removes the `storage` entry, also
   when the unit leaves the game without dying.

### Acid trail

At a fixed interval, the shell creates a small acid puddle on
`ao-tamed` under each acid-loaded monster that is still valid.

## Architecture

| File | Content |
| --- | --- |
| `core/species.lua` | Each species gets its larva name. |
| `core/payloads.lua` | The three payloads and their effects. Pure data and lookups. |
| `core/prototypes/ordnance.lua` | Builds the prototypes of this slice from the species and payload lists. |
| `core/balance.lua` | The numbers of this slice. |
| `control.lua` | The shell. See Runtime behaviour. |

The plan decides the shared helpers between the two prototype builders,
and which builder owns Monster husbandry.

## Testing

### Unit tests (busted)

- The prototype builder: names, counts, recipes, flags and unlocks.
- The payload lookups, and the effect list for each payload.
- The lookup from effect ID to species and payload.

### In-game tests (factorio-test, both modes)

- An incubator makes a larva from 10 eggs. A loading chamber makes a
  loaded larva.
- A spoiled larva hatches one wild monster.
- A spoiled loaded larva creates one monster on `ao-tamed`, on the
  ground and in a player's inventory.
- A loaded monster attacks a nearby spawner.
- A loaded monster that dies creates its death effect, and its `storage`
  entry goes away.
- An acid-loaded monster leaves an acid puddle.
- The tamed force is hostile to `enemy` and at cease-fire with `player`,
  and with a player force created after `on_init`.
- Nest loot still drops after this slice.

## Delivery

### Probe

Before PR 1, a throwaway probe answers these questions in both modes:

1. Where does a loaded larva spoil and hatch: in a player's inventory,
   in a chest, on a belt and on the ground? Which position fields does
   the event carry in each place?
2. Does a unit that the shell creates on `ao-tamed` with an attack-area
   command attack a nearby spawner?
3. Does an `explosive-rocket` projectile created at its own target
   explode at once and deal its damage?
4. Which forces do the rocket, `poison-cloud` and the acid puddle damage
   when they are on `ao-tamed`?
5. Does `on_object_destroyed` fire after `on_entity_died` for the same
   unit?

If a loaded larva cannot hatch in a player's inventory, the agent tells
the maintainer before PR 3. Effects on `ao-tamed` may hurt the player's
buildings (Q4). The probe records what the engine does.

### Pull requests

1. Incubator and larvae: the prototypes, the larva hatch and its tests.
2. Loading chamber, loaded larvae and the Ordnance loading research.
3. Loaded monsters: the tamed force, the loaded hatch, death effects and
   the acid trail.

Between PR 2 and PR 3, loaded larvae spoil into nothing. The maintainer
accepts this, because only the slice as a whole has to be playable.

## Risks

| Risk | Answer |
| --- | --- |
| A loaded larva spoils in the base: in a chest, on a belt or in a machine output. | The monster appears there and attacks nothing until natives come. This is the design's "dangerous to handle". Slice 4 adds the stasis ward. |
| A death effect hurts the player's own buildings. | Allowed (Q4): it is the design's "dangerous to handle". The probe records what the engine does. |
| A save that already has the mod gets no tamed force. | `on_configuration_changed` creates it. |
| Another mod removes a vanilla payload or effect prototype. | The plan adds a check before each `create_entity`, as slice 1 does for units. |
| Many acid-loaded monsters make the acid trail slow. | One puddle per monster per interval. The interval lives in `core/balance.lua`. |

## Changes to `docs/design.md` and `ROADMAP.md`

PR 1 makes these edits:

1. Lifecycle table: the incubator makes a larva from 10 eggs.
2. Version 1 list: the mod generates the loaded larva items. Loaded
   monsters are vanilla units that the shell tracks, so the mod
   generates no entity prototypes for them.
3. Technical notes: the items are built in `data.lua`, not in
   `data-final-fixes`.
4. Ordnance loading table: the sulfuric acid live effect is an acid
   trail, not a poison cloud.
5. Research tree: Ordnance loading needs Monster husbandry and
   `explosive-rocketry`.
6. Technical notes, launching: slice 3 hatches loaded monsters through
   the same `script` effect, so that the shell registers the payload.

PR 3 ticks "Breeding pod and incubator", "Loading chamber with three
payloads" and "Spoil outcomes" in `ROADMAP.md`.

## Answers

The maintainer accepted the agent's proposal for each question on
2026-11-14:

1. Larva ratio: 10 eggs make 1 larva.
2. A loaded monster is a vanilla unit that the shell tracks.
3. Loaded monster size follows enemy evolution.
4. One force, `ao-tamed`. Loaded monsters attack only natives in this
   slice. Their death effects may hurt the player's own buildings.
5. The incubator borrows the centrifuge graphics, and the loading
   chamber borrows assembling machine 3.
6. Delivery by hand, with a 5-minute spoil time.
7. Each acid load uses up 1 filled barrel.
8. Nests that `ao-tamed` kills drop eggs.

## Out of scope

- Launchers and long-range ammo (slice 3).
- Feral behaviour and the stasis ward (slice 4).
- More payloads, more slots, worms, pentapods and hybrids (version 2).
- One tamed force per player force for PvP (version 3).
