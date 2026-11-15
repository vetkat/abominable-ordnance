# Abominable Ordnance: slice 4, feral behaviour

Date: 2026-11-14. Status: approved. The agent wrote this
spec from `docs/design.md` while the maintainer was away. The maintainer
allows the build after an EGM review finds no new Blocker or Major issue.

EGM review: 6 rounds. The maintainer accepted every default in "Calls for
the maintainer" on 2026-11-15 and asked for one more round. Round 4 found
one new Major issue in the failed-target rule, and round 5 a gap in its
fix. This version fixes both: a failed attack now marks the monster, not
the target. Round 6 found no new Blocker or Major issue.

"Answers" lists what `docs/design.md` already decides. "Proposals" lists
the agent's own calls. "Calls for the maintainer" lists the calls that
the maintainer should confirm, with the default that the build uses.

## Purpose

Design version 1 is the first playable release in `docs/design.md`.
Slice 4 delivers the design pillar "Dangerous to handle". Slices 2 and 3
made loaded monsters that always stay on the player's side. This slice
lets them go feral.

A feral monster leaves the tamed force and joins a feral force that is
hostile to everyone. It keeps fighting until it dies, and it attacks
players and their buildings too. Its payload still goes off when it
dies.

Goals of this slice:

1. A loaded monster goes feral when a player comes within its feral
   radius.
2. A loaded monster goes feral when it has had nothing to fight for
   5 minutes.
3. A loaded monster has a small chance to go feral over time. The chance
   grows with each payload it carries.
4. Feral monsters fight players, the tamed force and the natives, and
   they never stand still for good.
5. The cost per tick stays fixed: a fixed batch of monsters per tick,
   and one search per player every 30 ticks.
6. Everything works the same with and without Space Age, in
   multiplayer, and in old saves.

## Terms

The earlier specs define these terms:
[slice 1](2026-11-13-lifecycle-design.md),
[slice 2](2026-11-14-ordnance-design.md) and
[slice 3](2026-11-14-launcher-design.md). The short versions:

- **The natives.** The `enemy` force: native units, spawners and worms.
- **The tamed force.** `ao-tamed`. It has a cease-fire with every player
  force and is at war with the natives.
- **A loaded monster.** A unit with an entry in `storage.loaded`. The
  entry holds the unit and its payloads.
- **Payload.** An item that a loaded larva carries, for example an
  explosive rocket. It goes off when the monster dies.
- **Payload count.** The number of payloads in the entry. In version 1
  it is always 1. "Expand Orifices", a design version 2 research, adds a
  second and a third slot.
- **Researched force.** A force that finished the Monster husbandry
  research. Its kills drop nest loot.

New terms:

- **The feral force.** `ao-feral`. It is at war with every force except
  `neutral`.
- **Feral radius.** The distance from a loaded monster at which a player
  makes it go feral.
- **Too-close scan.** The search around each player for loaded monsters
  within their feral radius.
- **Batch check.** The test of one loaded monster for the idle and
  unstable triggers. A batched pass runs it, like the acid trail in
  `core/trail.lua`.
- **Idle.** A tamed loaded monster is idle while no entity of the
  natives stands within 32 tiles of it. Any type counts, so the Space
  Age natives (spider units on Gleba, segmented units on Vulcanus) count
  too. A passing acid stream or fire of the natives can also reset the
  idle clock. The design accepts that.

## Facts found during design

The agent checked these in `.factorio-api/factorio/library/`:

- A script can set `LuaEntity.force`.
- `game.create_force` raises `on_force_created` at once. The game allows
  64 forces, so at most 61 forces made by mods or scenarios.
- `LuaSurface.count_entities_filtered` takes `position`, `radius`,
  `force`, `type` and `limit`.
- A `defines.command.wander` command without `ticks_to_wait` wanders
  forever. With `ticks_to_wait`, the command ends after that time. A
  wandering unit still fights enemies that come near.
- `on_ai_command_completed` gives the unit number and a
  `defines.behavior_result`. A command that cannot reach its target
  ends with `fail`.
- `LuaCommandable.has_command` tells if a unit has a command.
- `LuaSurface.find_nearest_enemy_entity_with_owner` takes `position`,
  `max_distance` and `force`, and returns the nearest entity with an
  owner that is an enemy of that force, or nil.
- `game.create_random_generator` is the mod's random source.
  `control.lua` keeps its seed in `storage.seed`.
- `on_entity_died` does not run for `LuaEntity.destroy()`. Only
  `on_object_destroyed` runs.

The probe in "Delivery" must confirm these. Each has a fallback:

| Fact to confirm | Fallback |
| --- | --- |
| Writing `unit.force = "ao-feral"` makes the unit attack its old allies and the player | Replace the unit, as "Replacing a unit" describes |
| A feral unit with a wander command attacks a player or a building that comes near | The completion handler sends a feral unit hunting again when its command ends, and the batch check restarts one that waits for it |
| One `find_nearest_enemy_entity_with_owner` search with radius 64 in a dense test base costs little | Lower `seek_distance` to 48 |
| The natives attack units of a force that is at war with them | None needed: the tamed force already fights this way |
| An `attack_area` at a target across water ends with `behavior_result.fail` | Treat `success` as a failure when the target is still valid and more than `search_radius` away |
| After a distraction command fails, the unit's original command resumes | If it does not, give the wander as for any other failure |

## Answers

`docs/design.md` already decides these:

| Question | Answer |
| --- | --- |
| Triggers | Too close, idle for 5 minutes, unstable chance per payload per minute |
| Feral force | Its own force, hostile to everyone, so the natives fight it too |
| Payload | A feral monster's payload still goes off when it dies |
| Feral radius | Grows with payload count and monster size. About 5 tiles for a one-slot biter |
| Too-close scan | Every 30 ticks, a search around each player, not every unit against every player |
| Re-taming | Only the pacifier facehugger, in design version 3 |
| Force limit | The mod adds one feral force |

## Alternatives considered

| Choice | Rejected alternative | Why rejected |
| --- | --- | --- |
| Search around each player | Measure every loaded monster against every player | The cost grows with monsters × players |
| One feral force | A feral force for each player force | Each PvP team would cost one more force of the 64 |
| Batch check on a cursor, as `core/trail.lua` does | A 10 s wander command whose completion runs the check | It takes over the monsters' AI every 10 s, it skips fighting monsters, a failed command can loop, and old saves need a restart of each command. `docs/architecture.md` names the cursor pattern for per-unit work |
| Batch check on a cursor | One pass over all monsters each second | The cost grows with the number of monsters |
| Change the unit's force | Always destroy and recreate the unit | A force change keeps the unit number, health and storage entry. Replacing is the fallback if the probe fails |
| Unstable roll for the elapsed time | A fixed roll every minute | The batch check runs at irregular times. A roll for the elapsed time keeps the chance per minute right |

## Proposals

The agent made these calls. "Calls for the maintainer" lists the ones
that change how the game feels.

- **The batch check runs every 10 s at most.** A new pass starts at most
  once per 600 ticks. Each tick checks up to 5 monsters. Up to 3000
  loaded monsters get one check every 10 s. With more, each check comes
  later.
- **A fighting monster is never idle.** When the batch check finds a
  native within 32 tiles, it clears the idle clock. If the monster's
  command is not an `attack_area`, the check gives it one with radius 32
  at its own position. Units always report a command, so the check
  tests the command type, not `has_command`.
- **A feral monster stays in `storage.loaded`.** Its payload still goes
  off on death, and an acid monster keeps its trail. The entry gets
  `feral = true`. The too-close scan and the idle and unstable triggers
  skip it.
- **Feral payloads and trails belong to the feral force.** The death
  effects and the acid puddles of a feral monster use `ao-feral`. So
  natives that a feral monster kills drop no nest loot, because the
  feral force is not a researched force and is not the tamed force.
- **A feral monster hunts.** `docs/design.md` says feral monsters
  attack the nearest target, including you and your buildings. The
  shell looks for a target when a monster goes feral, and again when
  its command ends with a success (`on_ai_command_completed`). The batch
  check restarts a monster that waits for it. The target is
  the nearest entity of a force at war with `ao-feral` within
  `seek_distance`, from `find_nearest_enemy_entity_with_owner`.

  The monster gets an `attack_area` command at that target. With no
  target in range, it gets a wander command with radius 32 that ends
  after `rewander_ticks`. The next batch check then searches again, so a
  base built later still draws it, and it never stands still for good.
  An attack that fails, for example at a target across water, ends in a
  wander instead of a new search at once (see "Failed commands").
- **Spoiled loaded larvae stay tamed at first.** Slice 2 already works
  this way, and the open question in `docs/design.md` stays open. A
  larva that spoils next to a player goes feral at the next too-close
  scan anyway.
- **No feral force when the force limit is full.** If 64 forces exist,
  the mod does not create `ao-feral` and writes one line to the log.
  Each trigger tests `game.forces[Names.FERAL]` and does nothing when it
  is missing, so loaded monsters stay tamed. The mod tries to create the
  force again in `on_configuration_changed` and `on_forces_merged`. The
  guard covers only `ao-feral`. The tamed force stays a known limit (see
  Risks).
- **Space platforms.** The too-close scan and the batch check skip units
  on a space platform. Loaded monsters cannot reach a platform in
  version 1, so this only guards against scripts and other mods.

## Calls for the maintainer

The build uses the default in each row. The maintainer can change any
of them later in `core/balance.lua` or in the code.

| Call | Default |
| --- | --- |
| Unstable chance | 0.2% per minute per payload. With one payload, about 1 in 500 monsters goes feral each minute |
| Idle definition | No native unit, spawner or worm within 32 tiles, for 5 minutes |
| Which players count | A connected player with a character, on a force that has a cease-fire with `ao-tamed`. A player in the map editor or without a character does not count |
| Players in vehicles | They count. The scan uses the character's position, which is the vehicle's position |
| Feral blasts | A feral monster's payload hurts players and their buildings, because the feral force is at war with them |
| Warning | The text "Feral!" above the monster for 3 s. No chat message |
| Feral hunting | A feral monster attacks the nearest enemy entity within 64 tiles (`seek_distance`). With none, it wanders |
| Loot from feral kills | Natives that a feral monster kills drop no nest loot |
| Tamed monsters near natives | A tamed loaded monster whose command is not an `attack_area`, with a native within 32 tiles, gets a fresh `attack_area` command. This is new behaviour for tamed monsters |
| Force limit full | Feral behaviour is off, with only a log line. The player is not told in the game |
| Size and radius | The feral radius grows by 1 tile per size step: 5 for a small biter, 8 for a behemoth |

## Game content

All numbers go in `core/balance.lua`, under `Balance.feral`:

| Number | Value | Notes |
| --- | --- | --- |
| `radius` | 5 | Feral radius in tiles for a small monster with one payload |
| `per_payload` | 2 | Added for each payload after the first. Kept on purpose for design version 2, when monsters carry more payloads |
| `per_size` | 1 | Added for each size step: small 0, medium 1, big 2, behemoth 3 |
| `max_payloads` | 1 | The most payloads a monster can carry. 1 in version 1 |
| `scan_ticks` | 30 | Interval of the too-close scan, from `docs/design.md` |
| `idle_ticks` | 18000 | 5 minutes |
| `pass_ticks` | 600 | A batch check pass starts at most once per 10 s |
| `batch` | 5 | Monsters checked per tick |
| `search_radius` | 32 | Same as the slice 2 `hatch_attack_radius` |
| `seek_distance` | 64 | How far a feral monster looks for a target |
| `rewander_ticks` | 600 | How long a feral wander lasts before the monster searches again |
| `retry_wanders` | 5 | Wanders before a feral monster hunts again after a failed attack, about 50 s |
| `unstable_per_minute` | 0.002 | Chance per payload per minute |
| `warning_ticks` | 180 | How long "Feral!" shows |

The size step is the unit's position in its species list in
`core/species.lua` (`Species.ALL[*].units`, from small to behemoth),
counted from 0. A unit that is in no list, for example from another
mod, gets step 0. So the feral radius is 5 for a small biter and 8 for
a behemoth biter with one payload.

The largest feral radius is
`radius + per_payload × (max_payloads − 1) + per_size × 3`, which is
8 tiles in version 1. The too-close scan searches this far.

The slice adds no item, recipe or technology. It adds one force,
`ao-feral`, and one locale key for the warning text.

## Runtime behaviour

### The feral force

`Tamed.ensure` (`shell/tamed.lua`) also creates `ao-feral`, unless the
force limit is full. Two pure rules in `core/forces.lua` own the
relations, one rule per pair:

- `Forces.cease_fire(name)`, the tamed rule, returns nil for `ao-feral`.
  So the tamed rule never touches the pair of the tamed and the feral
  force.
- `Forces.feral_cease_fire(name)`, the feral rule, returns false (war)
  for every force except `neutral` and `ao-feral`. For those two it
  returns nil, and the shell leaves the relation unchanged.

The shell applies each rule both ways. `on_force_created` relates the
new force to both mod forces. So the tamed and the feral force are at
war in every order of events.

### Too-close scan

Every `scan_ticks` ticks, the handler loops over `game.connected_players`.
It skips a player without a valid character, a player whose force has
no cease-fire with `ao-tamed`, and a character on a space platform. For
each other player:

1. It finds the units of the tamed force within the largest feral
   radius of the character's position.
2. For each unit with a `storage.loaded` entry, the core gets the
   distance, the payload count and the unit name. A distance at or below
   the monster's feral radius (`<=`) means feral.
3. Each monster that the core picks goes feral.

The number of searches grows with players, not with loaded monsters.
Each search returns only the monsters near that player.

### Batch check

The batch check walks `storage.loaded` with its own cursor,
`storage.feral_cursor`, and its own start tick,
`storage.feral_next_tick`. It reuses `Trail.batch`, `Trail.forget` and
`Trail.start` from `core/trail.lua`, which work on any table. Each tick
it checks up to `batch` entries:

1. It skips an entry whose unit is not valid or is on a space platform.
2. A feral entry that has `awaiting_check` set, or no command, gets a
   new target, as "A feral monster hunts" in Proposals says. Units
   always report a command, so the completion handler does the usual
   re-hunt and sets `awaiting_check` when it leaves the restart to the
   check. The idle and unstable work never runs for feral entries.
3. For a tamed entry, it counts entities of the natives within
   `search_radius` of the unit, with `limit = 1` and no type filter.
4. With a native in range, it sets `entry.idle_since` to nil. If the
   unit's command is not an `attack_area`, it gives it one.
5. With no native in range, it sets `entry.idle_since` to the current
   tick if it is nil.
6. The core decides if the monster goes feral now. It uses
   `idle_since`, the current tick, `entry.checked_at`, the payload count
   and a random number from the shell:
   - Idle for `idle_ticks` or more means feral.
   - Otherwise the unstable chance for the time since `checked_at`
     decides. The chance is `1 − (1 − p)^(elapsed / 3600)`, with
     `p = unstable_per_minute × payload count`. With no `checked_at`,
     the elapsed time is 0, so the first check never rolls.
7. It sets `entry.checked_at` to the current tick.

`on_object_destroyed` calls `Trail.forget` for this cursor too, before
it removes the entry, as it does for the trail cursor.

### Going feral

The shell does these steps, in this order:

1. It sets `unit.force` to `ao-feral`.
2. It sets `entry.feral = true`.
3. It gives the unit an `attack_area` command at the nearest enemy
   within `seek_distance`. With no enemy in range, it gives a wander
   command for `rewander_ticks`.
4. It draws "Feral!" above the unit for `warning_ticks` ticks.

The death effects and the acid trail take their force from the entry:
`ao-feral` for a feral entry, `ao-tamed` for a tamed one.

### Failed commands

`on_ai_command_completed` runs for every unit of every mod. The handler
looks up `storage.loaded[event.unit_number]` and ignores the event when
there is no feral entry, or when the entry's unit has another unit
number.

- With `defines.behavior_result.fail`, the shell gives the unit a wander
  command for `rewander_ticks`. It does not search for a new target at
  once, so an unreachable target can't start a loop of failed commands.
- A `fail` with `was_distracted = true` came from a distraction, not from
  the hunt. The probe checks if the original command resumes after
  such a failure. If it does, the shell ignores the event. If not, it
  gives the wander only.
- Any other `fail` of a hunt's `attack_area` marks the monster:
  `entry.failed_at` takes the current tick. The shell sets
  `entry.hunting = true` when it gives that command. So a failed wander
  never marks the monster.
- The probe-table fallback can treat a `success` as a failure. That
  marks the monster too.
- While `failed_at` is less than `retry_wanders × rewander_ticks` ago,
  every search gives a wander, whatever the search returns. So a base
  across a lake costs at most one failed attack per monster in that time.
- After that time the shell clears `failed_at`, and the monster hunts
  normally again. A bridge or landfill can make the target reachable.
- The probe-table fallback for wandering units can be in use. Then a
  marked monster gets that `attack_area` at its own position instead of
  the wander. It can't fail on an unreachable target, so it never marks
  the monster.

### Replacing a unit

This is built only if the probe shows that setting `unit.force` fails.
The shell creates the new unit on the feral force first. Then it moves
the entry to the new unit number, with `Trail.forget` for both cursors.
It registers the new unit and destroys the old one with `destroy()`,
which raises no `on_entity_died`. If the create fails, the old unit and its
entry stay as they are, and the shell writes one log line.

### Old saves

- `on_init` and `on_configuration_changed` create `ao-feral` through
  `Tamed.ensure`.
- `storage.feral_cursor` and `storage.feral_next_tick` start as nil, and
  every reader treats nil as the start. So they need no setup.
- Old entries have no `idle_since` and no `checked_at`. The first batch
  check sets both, so no old monster goes feral by chance at once.

## Architecture

The rules in `docs/architecture.md` apply. New and changed modules:

| Module | Layer | Job |
| --- | --- | --- |
| `core/feral.lua` | core | The size step from the species lists, the feral radius, the largest radius, the too-close decision, and the idle and unstable decision |
| `core/forces.lua` | core | `cease_fire` returns nil for the feral force, the new `feral_cease_fire`, `earns_loot` stays false for the feral force |
| `core/names.lua` | core | `FERAL = "ao-feral"` |
| `core/balance.lua` | core | `Balance.feral` |
| `shell/tamed.lua` | shell | Creates and relates the feral force too, and checks the force limit |
| `shell/feral.lua` | shell | `go_feral(entry)`, the target search, the too-close scan for one player and the batch check for one entry, so that the in-game tests can call them. The replacement fallback only if the probe needs it |
| `control.lua` | shell | The `on_nth_tick` too-close handler, the batch check in the `on_tick` handler, `Trail.forget` for the new cursor, and the feral force for death effects and the trail |

`core/feral.lua` takes a random number from the shell, as
`Hatching.pick` does. It never calls a generator itself.

## Testing

### Unit tests (busted)

- The size step is 0 for `small-biter`, 1 for `medium-spitter`, 2 for
  `big-biter`, 3 for `behemoth-spitter`, and 0 for a unit in no species
  list.
- The feral radius is 5 for a small monster with one payload, 8 for a
  behemoth, and 2 more for each extra payload. The largest radius is 8
  in version 1.
- Too close: a distance of 5.0 goes feral, 5.1 does not, for a small
  monster. A feral entry never goes feral again.
- Idle: `idle_since` nil, or less than `idle_ticks` in the past, does
  not trigger. Exactly `idle_ticks` triggers.
- Unstable: with no `checked_at`, the chance is 0. For 600 ticks and one
  payload, the chance is `1 − 0.998^(1/6)`. A random number below it
  triggers, one above does not.
- `cease_fire` returns nil for `ao-feral`.
- `feral_cease_fire` returns false for `enemy`, `player`, `ao-tamed` and
  an unknown force, and nil for `neutral` and `ao-feral`.
- `earns_loot` is false for `ao-feral`.

### In-game tests (factorio-test, both modes)

- The feral force exists and is at war with `enemy`, `player` and
  `ao-tamed`, both ways. After a second `Tamed.ensure`, the tamed and
  feral force are still at war.
- A force created after `on_init` is at war with the feral force.
- A character 4 tiles from a small loaded monster makes it feral within
  `scan_ticks` + 1 ticks. A character 6 tiles away does not.
- A loaded monster with `idle_since` set `idle_ticks` in the past goes
  feral at its next batch check.
- A loaded monster with a native in range has `idle_since` nil after
  its batch check.
- A feral monster keeps its `storage.loaded` entry. When it dies, its
  payload effects belong to `ao-feral`.
- A feral monster that kills a native spawner drops no nest loot.
- A feral monster whose wander ends hunts again. With a player chest
  within `seek_distance`, the command targets it.
- A feral monster that waits for the batch check gets a new command
  from it.
- A tamed monster next to a Space Age native that is not a `unit` (for
  example a Gleba spider unit) is not idle. This test runs in Space Age
  only.
- A monster that dies while the feral cursor points at it does not stop
  the batch check.
- A feral monster whose only target stands across water gets a wander
  command after its attack fails. With two or more targets across the
  water, it tries at most one attack per `retry_wanders × rewander_ticks`.
  After that time it hunts again.
- A `fail` caused by a distraction does not mark the monster.
- A feral monster that wanders with no target in range searches again
  after `rewander_ticks`. A player chest placed within `seek_distance`
  during the wander becomes its target.

## Delivery

### Probe

Before the build, a throwaway probe mod checks the facts in the table in
"Facts found during design". The plan follows the fallback for each fact
that fails.

### Pull requests

1. **Feral force and too-close scan.** Names, balance, and the size
   step and radius in `core/feral.lua`. The force rules, the feral force
   and `go_feral`. The feral force for death effects and the trail. The
   too-close handler. Tests for all of these.
2. **Batch check.** The idle and unstable decision, the batch check with
   its cursor, the feral re-command, the docs and the roadmap.

Each PR follows the workflow in `CLAUDE.md`, with a CHANGELOG entry.

## Risks

- **Feral monsters pile up.** The engine never removes a feral monster,
  because its payload must go off first. Natives and players attack it.
  A later slice can add a feral timeout if play tests show a problem.
- **Batch check cost.** Each tick checks up to 5 monsters. Each check
  makes one `count_entities_filtered` call with `limit = 1`. The cost per
  tick stays fixed. The probe does not measure it.
- **Target search cost.** A feral monster that re-hunts runs one
  `find_nearest_enemy_entity_with_owner` search with radius 64. In a
  dense base that area holds thousands of entities, and up to 5 such
  searches can run in one tick. The probe times one search. If it is
  slow, `seek_distance` drops to 48.
- **Force limit.** The mod now uses two of the 64 forces. With a full
  limit, the feral triggers are off and the log says so. The tamed
  force has no such guard: if the limit is full before the mod creates
  `ao-tamed`, setup fails, as it did in slice 2.
- **Feral entries in the batch.** Feral monsters stay in
  `storage.loaded`, so they take batch slots. At large counts, tamed
  monsters get their idle check less often. A feral entry that
  needs no restart costs only one `has_command` call, and the batch size bounds
  the cost per tick.
- **Players near a launcher.** A rocket that spoils inside a launcher
  hatches next to it. If a player stands there, the monster goes feral
  at the next too-close scan. That is the "Dangerous to handle" pillar.

## Changes to `docs/design.md` and `ROADMAP.md`

- "Feral behaviour and risks": idle means no entity of the natives
  within 32 tiles. The feral radius grows by 1 tile per size step. A
  feral monster hunts the nearest enemy within 64 tiles.
- "Technical notes", "Feral check": the too-close scan uses the
  character's position, and only players with a character count. A
  batched pass runs the idle and unstable checks.
- "Feral behaviour and risks": remove "Slice 4 decides" from the
  pheromone flare note, and point to the open question instead.
- "Open questions": add "Do feral monsters warn the player, and how?",
  and keep "Spoiled loaded larvae" open.
- `ROADMAP.md`: tick "Feral behaviour" when PR 2 merges.

## Out of scope

- The pacifier facehugger and the Pheromones research, design version 3.
- The pheromone flare. Slice 3 handed it to this slice. It needs the
  pollution and attack rules of design version 2 or later.
- Converted units and facehuggers, design version 2.
- PvP rules for feral monsters.
- The stasis ward, slice 5.
- A feral timeout, or removal of idle feral monsters.
