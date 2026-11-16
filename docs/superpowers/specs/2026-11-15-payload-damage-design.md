# Abominable Ordnance: payload damage targets

Date: 2026-11-15. Status: approved by EGM after 3 rounds and a final
check. The maintainer decided the target rules on 2026-11-15. The agent
wrote this spec from those rules and rewrote it after each EGM round.

"Answers" lists the maintainer's decisions. "Proposals" lists the agent's
own calls. "Calls for the maintainer" lists the calls that change how the
game feels, each with the default that the build uses.

## Purpose

Slices 2 and 3 gave each payload a death effect and gave each larva
rocket a landing blast. Today these follow two different rules:

- The landing blast (slice 3, `blast` in `control.lua`) hurts only
  forces at war with the launcher's force. It never hurts the tamed force
  or neutral entities such as trees and rocks.
- The death effects (slice 2, `Payloads.on_death`) create vanilla
  entities: an explosive rocket, a poison cloud and acid puddles. Each
  vanilla entity decides its own targets. The vanilla poison cloud hurts
  every entity whose prototype breathes air. The vanilla acid puddle
  hurts units at war with the tamed force and slows them.

The maintainer wants one rule per payload. The payload decides what its
landing blast and its death effect hurt. Each payload uses its own damage
type.

Goals:

1. The landing blast and the death effect of a payload hurt the same set
   of targets, with the payload's damage type. The amounts differ.
2. Explosive hurts everything. Poison hurts organics. Acid hurts
   everything except rocks.
3. The effects keep their looks: an explosion, a green cloud, acid
   puddles.
4. Each tick runs at most a fixed number of detonations and hazard hits,
   also with many long-lasting clouds and pools and with chains of
   deaths. Work above the limit waits for later ticks.
5. Everything works the same with and without Space Age, in multiplayer
   and in old saves.

## Terms

The earlier specs define most terms:
[slice 2](2026-11-14-ordnance-design.md),
[slice 3](2026-11-14-launcher-design.md) and
[slice 4](2026-11-14-feral-design.md). The short versions:

- **Launcher.** The larva launcher from slice 3. It fires larva rockets,
  and each rocket lands with a blast before its monster appears.
- **Core and shell.** `docs/architecture.md` splits the code. Core
  modules in `core/` are pure: they take values and return values. Shell
  code in `control.lua` and `shell/` talks to the game.
- **Batched pass.** A handler that visits a fixed number of entries of a
  `storage` table per tick, with a cursor. `Trail.batch` in
  `core/trail.lua` returns the next entries and the new cursor.
  `Trail.forget` moves the cursor past an entry before the entry leaves
  the table.
- **Both modes.** The game with and without Space Age.
- **Version 2 payloads.** Grenade, slowdown, flamethrower, Tesla and
  atomic bomb, which `docs/design.md` plans for design version 2.

New terms:

- **Target class.** A group of entities that a payload can hurt:
  organics, rocks and buildings.
- **Organic.** An entity whose prototype has the `breaths-air` flag.
  Vanilla gives this flag to units, spawners, worms, characters and
  trees. Space Age also gives it to Gleba plants, pentapods and the
  segments of demolishers. Vanilla poison picks its targets the same way.
- **Rock.** A `simple-entity` whose prototype sets
  `count_as_rock_for_filtered_deconstruction`, as the vanilla rocks do.
  The game allows this field only on a `simple-entity`, so the shell
  reads it only there.
- **Building.** Any other entity with health.
- **Mobile target.** A target of type `unit` or `character`. Only these
  get the acid slowdown.
- **Hazard.** A long-lasting damage area in `storage`: a poison cloud or
  an acid pool from a death. Trail puddles are not hazards.
- **Look-alike.** A copy of a vanilla effect prototype that shows the
  same picture but deals no damage of its own.
- **Detonation.** One death effect waiting in the detonation queue.

## Facts found during design

The agent checked these in `.factorio-api/factorio/library/` and in the
vanilla 2.1.24 data:

- `LuaEntity.damage(damage, force, type, source, cause)` damages any
  entity with health. The force is the attacker's force. It raises
  `on_entity_died` at once when the entity dies.
- `LuaEntityPrototype.has_flag("breaths-air")` is readable at runtime.
  `LuaEntityPrototype.count_as_rock_for_filtered_deconstruction` is
  readable only on a `simple-entity` prototype.
- `LuaSurface.find_entities_filtered` takes `position`, `radius`, `type`
  and `name`. A type list narrows the search.
- The vanilla `poison-cloud` is a `smoke-with-trigger` that lasts 20 s.
  Its damage action hits entities with `breaths-air` within a radius of
  11 tiles.
- The vanilla `acid-splash-fire-spitter-big` is a `fire` entity. It deals
  no `damage_per_tick`. Its damage and a slowdown sticker
  (`acid-sticker-big`) come from `on_damage_tick_effect`. It lives 32 s
  and can spread to 100 copies.
- The vanilla `big-explosion` is an `explosion` entity. It shows a
  picture and deals no damage.
- The damage types `explosion`, `poison` and `acid` exist in vanilla.

The probe in "Delivery" must confirm the facts in the table below. Each
has a fallback:

| Fact to confirm | Fallback |
| --- | --- |
| `damage` with the tamed force hurts tamed monsters, and with the feral force hurts feral monsters | Damage with the `enemy` force for hits on the monster's own force. Those kills then count for the natives |
| `damage` with the tamed force hurts the player force, which has a cease-fire with it | Damage with the `enemy` force for hits on player forces. Those kills count for the natives and drop no nest loot |
| `damage` with the launcher's force (a player force) hurts a tamed monster, which has a cease-fire with it | Damage with the `enemy` force for hits on the tamed force. Those kills count for the natives |
| `damage` with the `neutral` force hurts players and tamed monsters (a landing with no launcher) | Damage with the `enemy` force for those targets |
| `damage` still hurts when the attacker's force has `friendly_fire = false` | Same as the rows above, for that force only |
| A look-alike copy of `poison-cloud` with its action removed shows the cloud and deals no damage | Use a plain `smoke` with the cloud's animation |
| A look-alike copy of the acid fire with no `on_damage_tick_effect`, no spreading and a short lifetime shows the puddle and deals no damage | Draw the puddle with `rendering.draw_animation` for the hazard's duration |
| Trees take `poison` and `acid` damage, and rocks take `explosion` damage | Accept the vanilla resistances and say so in Risks |

## Answers

The maintainer decided these on 2026-11-15:

| Payload | Hurts | Damage type |
| --- | --- | --- |
| Explosive | Natives, players, your buildings, tamed monsters, trees, rocks | `explosion` |
| Poison | Natives, players, tamed monsters, trees | `poison` |
| Acid | Natives, players, your buildings, tamed monsters, trees. Not rocks | `acid` |

The rules apply to both the landing blast and the death effect. The
landed monster still appears after the landing blast, so its own blast
never hurts it. Friendly fire on your own buildings and tamed monsters is
intended.

The version 2 payloads have a draft rule set. `docs/design.md` records it
as an open question to revisit in version 2.

## Alternatives considered

| Choice | Rejected alternative | Why rejected |
| --- | --- | --- |
| Script damage with look-alike prototypes | Keep the vanilla entities and their own damage | The vanilla acid puddle hurts only enemies of its force, and the poison cloud ignores buildings. Neither can hurt the tamed force's own monsters |
| Script damage with look-alike prototypes | Vanilla damage where it matches, script damage for the missing targets | Two damage sources per effect. Targets that both reach take double damage |
| Classes from prototype flags (`breaths-air`, rock flag) | A hard-coded list of entity types | Types miss Gleba plants (`plant`), demolisher segments (`segment`) and modded creatures. The flags are what vanilla poison already uses |
| Hazards in a batched pass | A `script` trigger in the look-alike's own action | One event per cloud per interval, so the cost grows with clouds |
| Hazards in a batched pass | A single hit on death, with no long-lasting damage | A poison cloud and an acid pool are meant to last |
| One acid hit per trail puddle | A short hazard for each trail puddle | About 3 hazards per acid monster would fill the hazard pool and slow the death hazards |
| A detonation queue | Detonate inside `on_entity_died` | A blast that kills a loaded monster raises its death at once, so a dense cluster recurses deeply |
| `shell/damage.lua` | All damage code in `control.lua` | About 200 more lines in a file of 300. The in-game tests also call the class check, see "Architecture" |

## Proposals

The agent made these calls:

- **One pure rule.** `Payloads.hits(payload_name, class)` in
  `core/payloads.lua` returns true when the payload hurts that target
  class. `Payloads.damage_type(payload_name)` returns `explosion`,
  `poison` or `acid`.
- **Classes from prototypes.** `shell/damage.lua` keeps the class sets in
  a module-level cache. The first call after a load reads
  `prototypes.entity` once and builds a set of organic names, a set of
  rock names and the type list of each set. A search uses the type list,
  then checks the name. Acid searches all entities and skips rock names.
  Every client builds the same sets from the same prototypes, and nothing
  goes into `storage`.
- **The landing blast follows the payload.** The rocket's payload decides
  the targets and the damage type. The amount and radius stay as in
  slice 3 (35 in 3.5 tiles). The launcher's force deals it, and the
  launcher is the cause. With no launcher, the `neutral` force deals it,
  as in slice 3.
- **Deaths use a queue.** `set_off` adds one detonation per payload to
  `storage.detonations`. A rocket that lands with no free spot, for
  example in water, also adds its detonation to the queue, with the
  tamed force. A batched pass runs up to `detonation_batch` detonations
  per tick. So a blast that kills more loaded monsters adds their
  detonations to the queue and never recurses.
- **Explosive death is one hit.** The detonation creates `big-explosion`
  and deals the damage once.
- **Poison and acid deaths are hazards.** The detonation creates the
  look-alike and adds a hazard with its first hit already due. The hazard
  pass deals that first hit, then one hit every `hazard_interval` ticks
  until the hazard ends.
- **The kill counts for the monster's force.** The tamed force deals the
  death damage, or the feral force for a feral monster
  (`FeralShell.force_of`). A hazard has no cause, because the monster no
  longer exists.
- **The trail comes from the payloads.** The trail pass reads
  `Payloads.trail(entry.payloads)` each time. A stored vanilla puddle
  name from an old save no longer matters. The trail hit does not depend
  on the look-alike: if another mod removed the vanilla puddle, the hit
  still applies.
- **Every hit checks validity.** Before each hit, the shell checks
  `target.valid`. A detonation or hazard whose surface no longer exists,
  or whose force no longer exists after a merge, leaves its table without
  damage.
- **Slice 3 code goes.** `Forces.blast_hits` and the slice 3 test "the
  blast does not hurt a loaded monster" go in PR 1. A new test checks
  each payload's target set.

## Calls for the maintainer

The build uses the default in each row:

| Call | Default |
| --- | --- |
| Poison cloud | 20 s, radius 11 as vanilla, 8 poison damage every 0.5 s |
| Acid pool on death | 15 s, radius 3, 10 acid damage every 0.5 s |
| Acid slows | The pool puts `acid-sticker-big` on every mobile target it hits, following the acid rule. A late visit with a summed hit puts the sticker on once |
| Acid trail | One hit of 5 acid damage in radius 1 per puddle. No long-lasting puddle damage |
| Trail targets | The trail never hurts the monster that dropped it. Other monsters, tamed or feral, take the hit |
| Explosive death | 150 explosion damage in a 4-tile radius, one hit |
| Landing blast | 35 damage in a 3.5-tile radius, one hit, the payload's damage type |
| Friendly fire on your base | On. Your turrets do not fire back at tamed monsters, and alerts can repeat. A mod setting that switches it off can come later |
| Feral kills | Natives that a feral monster's death effect kills drop no nest loot, because `Forces.earns_loot` is false for the feral force |
| Probe fallback | If a probe row fails, the `enemy` force deals those hits, and those kills count for the natives |
| Busy ticks | At most `hazard_hits` hazard hits and `hazard_visits` visits per tick. The hits stop when the targets they damaged reach `hazard_targets`. Above that, a hazard ticks less often, but each visit catches up, so the total damage before resistances stays the same. A flat resistance subtracts once per summed hit, so a late hazard deals a little more to such a target |

## Game content

All numbers go in `core/balance.lua`, under `Balance.payload_damage`:

| Number | Value | Notes |
| --- | --- | --- |
| `explosive.damage` | 150 | One hit on death |
| `explosive.radius` | 4 | Tiles |
| `poison.damage` | 8 | Per interval |
| `poison.radius` | 11 | Tiles, as the vanilla cloud |
| `poison.ticks` | 1200 | 20 s |
| `acid.damage` | 10 | Per interval |
| `acid.radius` | 3 | Tiles. The five puddles sit at the death spot and 1.5 tiles to each side, so radius 3 covers them |
| `acid.ticks` | 900 | 15 s |
| `trail.damage` | 5 | One hit per puddle |
| `trail.radius` | 1 | Tiles |
| `hazard_interval` | 30 | Ticks between two hits of one hazard |
| `hazard_hits` | 10 | Hazard hits (searches) per tick |
| `hazard_visits` | 50 | Hazards visited per tick, with or without a hit |
| `hazard_targets` | 200 | Targets that hazard hits damage per tick, before the pass stops |
| `detonation_batch` | 5 | Detonations run per tick |

`Balance.blast` keeps its 35 damage and 3.5-tile radius.

The data stage adds three look-alike prototypes: a poison cloud, a big
acid puddle and a small acid puddle. Each copies the vanilla picture and
deals no damage. None spreads. A look-alike lasts as long as its hazard.
The trail puddle lasts as long as the vanilla small puddle shows.

If another mod removed the vanilla prototype, the data stage skips that
look-alike, and the effect shows nothing. The damage still applies.

## Runtime behaviour

### Landing blast

`blast` in `control.lua` takes the rocket's payload. It finds the
targets of the payload's classes within the blast radius and damages
each with the payload's damage type. The monster appears after the
blast, as in slice 3. With no free spot, the rocket's payload goes into
the detonation queue with the tamed force. This is the death effect of
the monster that could not appear, so it follows the death rule, as in
slice 3.

### Death

`set_off` keeps its place in `on_entity_died`. It adds one detonation
per payload to `storage.detonations`, with the surface index, position,
payload name and force name. The detonation pass runs each one:

- **Explosive.** It creates `big-explosion` and damages the targets in
  `explosive.radius` once.
- **Poison.** It creates the look-alike cloud and adds a hazard.
- **Acid.** It creates the five look-alike puddles and adds one hazard
  that covers them.

### Hazards

A hazard holds the surface index, the position, the payload name, the
force name, the end tick and the tick of its last hit. `storage.hazards`
holds them by a number from `storage.hazard_counter`. A batched pass
with its own cursor (`storage.hazard_cursor`) visits hazards from the
cursor on. In one tick it visits at most `hazard_visits` hazards and
never visits the same hazard twice.

A visit counts the whole intervals since the last hit, up to the end
tick. With no whole interval, the visit does no search and costs no hit.
Otherwise it deals the damage once for each interval, as one hit of the
summed amount, and moves the last-hit tick. Each such hit counts against
`hazard_hits`.

Each target that a hit damages counts against
`hazard_targets`. When the targets reach it, no further hit runs that
tick. A hit that does not run keeps its last-hit tick, and the cursor
stays at its hazard.

When the tick has no hits or visits left, the cursor
stays at the next hazard. The next tick carries on from there. So a
hazard that the pass reaches late still deals its full damage before
resistances.

The detonation deals no hit itself. It sets the hazard's last-hit tick
one interval before the current tick. So the first hit is due at once,
and the hazard pass deals it within the budget. A hazard past its end
tick leaves the table. The pass calls `Trail.forget` before it removes a
hazard.

The acid slowdown uses `create_entity` with the sticker name, the target
and its position. The shell checks `target.valid` after the hit, so a
target that the hit killed gets no sticker.

### Acid trail

The trail pass from slice 2 drops the small look-alike puddle and deals
one acid hit with `trail.radius`. The hit skips the monster's own unit.

### Old saves

`on_init` and `on_configuration_changed` create `storage.hazards`,
`storage.detonations`, the counter and the cursors. Vanilla clouds and
puddles from an old save burn out on their own. Acid monsters from an
old save get their trail from `Payloads.trail`, so they drop the
look-alike and stop making vanilla puddles.

## Architecture

| Module | Layer | Job |
| --- | --- | --- |
| `core/payloads.lua` | core | `hits`, `damage_type`, `trail`, and `on_death`, which now returns one plan per payload: the entities to create and the hit or hazard |
| `core/trail.lua` | core | The shared helpers of every batched pass: `Trail.batch`, `Trail.forget` and `Trail.start` (the start of a pass). The hazard and detonation passes reuse them. When the hazard pass stops partway through a batch, it sets its cursor to the first hazard it did not visit, not to the cursor that `Trail.batch` returned |
| `core/prototypes/ordnance.lua` | core | The look-alike prototypes, built from vanilla looks that `data.lua` passes in |
| `shell/damage.lua` | shell | Builds the class sets, finds targets, deals damage, runs detonations and hazards |
| `control.lua` | shell | Calls `shell/damage.lua` from the landing, the death and the trail, and runs the passes |
| `data.lua` | shell | Picks the vanilla looks for the look-alike prototypes |

`docs/architecture.md` keeps shell code in `control.lua` unless the
in-game tests also call it. The in-game tests call `Damage.class_of` to
check the class sets, so `shell/damage.lua` meets that rule. The PR also
updates the example in `docs/architecture.md`, because
`Payloads.on_death` now returns plans that `shell/damage.lua` runs.

## Testing

### Unit tests (busted)

- `Payloads.hits` for each payload and each target class.
- `Payloads.damage_type` for each payload.
- `Payloads.on_death` returns the right plan for each payload.
- The catch-up count of intervals for a hazard visited late, and no hit
  for a visit with no whole interval.
- The hazard pass stops at `hazard_hits` hits or `hazard_visits` visits,
  never visits a hazard twice in one tick, and resumes at the cursor.
- The look-alike prototypes have the vanilla pictures, no damage, no
  spreading and the hazard's lifetime.
- Every number lives in `Balance.payload_damage`.

### In-game tests (factorio-test, both modes)

- `Damage.class_of` puts a biter and a tree in organics, a vanilla rock
  in rocks and a chest in buildings.
- An explosive landing hurts a native, a player chest, a tamed monster,
  a tree and a rock.
- A poison landing hurts a native, a tamed monster and a tree, and not a
  player chest or a rock.
- An acid landing hurts a native, a player chest, a tamed monster and a
  tree, and not a rock.
- A rocket that lands in water sets its payload off through the queue,
  with the tamed force.
- An explosive death hurts the same targets as its landing, once.
- A poison death keeps hurting a native in the cloud for its duration,
  and stops after it.
- With more hazards than `hazard_hits`, each hazard still deals its full
  damage by its end tick.
- An acid monster's trail hurts a player chest it walks past, and never
  the monster itself.
- An acid pool slows a native unit and does not slow a chest.
- Two explosive monsters next to each other: the first death kills the
  second through the queue, with no recursion.
- A detonation for a force that a merge removed leaves the queue and
  deals no damage.
- An old-save entry with the vanilla trail name drops the look-alike.
- A feral monster's death damage counts for the feral force, and a nest
  it kills drops no eggs.
- Space Age only: a poison cloud hurts a Gleba plant and a demolisher
  segment.

## Delivery

### Probe

Before the build, a throwaway probe checks the facts in the table in
"Facts found during design". The plan follows the fallback for each fact
that fails.

### Pull requests

1. **Target rules.** The class sets, `Payloads.hits`, `damage_type`, the
   landing blast, the detonation queue, the water landing and the
   explosive death. It removes `Forces.blast_hits` and its slice 3 test.
2. **Hazards.** The look-alike cloud and pool, the hazard pass, and the
   poison and acid deaths.
3. **Acid extras.** The acid trail hit, the small look-alike puddle and
   the acid slowdown.

Each PR leaves the mod in a playable state. In PR 1, poison and acid
detonations already use the queue, but they still create the vanilla
cloud and puddles, with the vanilla targets. PR 2 replaces them with
look-alike prototypes and hazards. Until PR 3, the trail keeps its vanilla
puddle, and acid pools do not slow.

## Risks

- **Base damage.** An acid monster now damages your base as it walks.
  Players may lose belts and walls they did not expect to lose. The
  changelog says so.
- **Busy ticks.** `hazard_hits` limits the searches per tick. A hit on a
  dense spot, such as a cloud over a large nest, damages many entities in
  one search. The limit counts searches, not entities, so such a tick
  costs more.
- **Resistances.** Vanilla resistances still apply. Some buildings resist
  acid or explosions, so the damage they take is lower.
- **Other mods.** A modded creature without `breaths-air` counts as a
  building. Poison then skips it, as vanilla poison does.
- **Damage across forces.** If the probe falls back to the `enemy` force,
  kills on your own side count for the natives.

## Changes to `docs/design.md` and `ROADMAP.md`

The worktree already has these edits:

- "Ordnance loading": a paragraph on what each payload hurts.
- "Technical notes", "Launching" and "Live and death effects": the script
  deals the blast and the death damage by the payload's target rule.
- "Open questions": the version 2 draft target rules, marked "revisit in
  version 2".
- `ROADMAP.md`: a line "Payload damage follows the payload" under 1.0.0.

## Out of scope

- The version 2 payloads and their rules. Their draft is an open question
  in `docs/design.md`.
- Changes to the damage amounts of vanilla weapons.
- A mod setting that switches friendly fire off.
- The pheromone flare.
