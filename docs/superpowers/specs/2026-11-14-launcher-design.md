# Abominable Ordnance: slice 3, larva launcher

Date: 2026-11-14. Status: draft for review. The maintainer and the agent
agreed on this design in a brainstorm on 2026-11-14. "Answers" lists the
maintainer's choices, and "Proposals" lists the agent's own calls. An EGM
review followed, with reports in
`docs/superpowers/reviews/2026-11-14-launcher-*.md`.

## Purpose

Design version 1 is the first playable release in `docs/design.md`:
biters and spitters, three payloads and one launcher. Slice 3 of it lets
a player fire loaded larvae at the natives.

Slice 2 (`docs/superpowers/specs/2026-11-14-ordnance-design.md`) added the
loading chamber, a machine that puts a payload into a larva. It made six
loaded larvae: biter and spitter, each with an explosive rocket, a
sulfuric acid barrel or a poison capsule. A loaded larva that spoils
becomes a loaded monster, and the payload goes off when the monster dies.
In slice 2 a player carries the larva to the natives by hand.

This slice adds the larva launcher, the larva rocket casing, the larva
targeting remote, the Larva rockets research and two upgrade researches.

Goals of this slice:

1. The loading chamber makes larva rockets: larva + payload + casing. A
   larva rocket is the launcher's ammo.
2. The larva launcher fires on its own at native nests and worms in range,
   and at any spot that a player marks with the larva targeting remote.
3. A larva rocket that lands makes a small explosion (35 damage, 3.5-tile
   radius). Then its loaded monster appears at full health and attacks the
   natives within 32 tiles, as in slice 2.
4. Research upgrades the launcher's fire rate and range.
5. Everything works the same with and without Space Age.

Feral behaviour (slice 4), the stasis ward (slice 5) and artillery shells
(design version 2) are out of scope.

## Terms

Terms are as in the slice 1 and slice 2 specs. **The natives** are the
`enemy` force. **Both modes** means with and without Space Age. **The
tamed force** is `ao-tamed` from slice 2. It has a cease-fire with every
player force and is at war with the natives (`core/forces.lua`). New
terms:

- **Larva rocket.** A loaded larva in its slice 3 form. It is an ammo
  item that only the larva launcher accepts.
- **Casing.** The larva rocket casing, one shared item that every larva
  rocket uses up.
- **Level.** The launcher's range level, 0 to 3. Each force has a level:
  the number of range researches it finished. Each level has its own
  turret prototype with a longer range.
- **Swap.** The script replaces a launcher with the prototype for its
  force's level. After every swap, each launcher's level equals its
  force's level.

## Facts found during design

The agent and the reviewers checked these in
`.factorio-api/factorio/library/`:

- An artillery flare has a `shot_category`. Only artillery whose ammo has
  that category fires at the flare. A flare without a `shot_category`
  draws every ammo category (`ArtilleryFlarePrototype.shot_category`). The
  vanilla flare has none, so without a fix the vanilla artillery remote
  also makes larva launchers fire. "Separate remotes" fixes this.
- A `gun-speed` research effect names one ammo category
  (`GunSpeedModifier.ammo_category`), so it can speed up larva rockets
  alone. The modifiers add up: three levels of +20% give +60%.
- The `artillery-range` research effect has no ammo category
  (`ArtilleryRangeModifier`). It also extends vanilla artillery.
- An artillery turret has `manual_range_modifier`, the factor between its
  own range and its range for flares.
- `on_script_trigger_effect` gives `source_position`, `target_position`
  and `source_entity`. The slice 2 handler reads `source_position` first.
  For a projectile, `source_position` is the launcher. So the landing
  needs its own effect ID that reads `target_position`.
- `LuaSurface.create_entity` takes `quality` and `raise_built`. Without
  `quality`, the new entity is normal quality.
- `kills` and `damage_dealt` exist only on turrets. An artillery turret is
  not a turret in the API (`ArtilleryTurretPrototype`), so the swap can't
  keep them.

The probe in "Delivery" must confirm the facts below. Each one has a
fallback if the probe shows otherwise:

| Fact to confirm | Fallback |
| --- | --- |
| An artillery turret fires on its own only at military buildings, such as spawners and worms | Set `disable_automatic_firing` and keep only the remote. Ask the maintainer |
| A larva rocket spoils inside the launcher, and its spoil trigger runs at the launcher | Accept that it never spoils there, and note it in the Risks |
| The projectile's blast runs before its `script` effect in the same tick | Spawn the monster one tick later, from a queue in `storage` |
| Old saves keep slice 2 loaded larvae when the prototype changes from `item` to `ammo` under the same name | Give the rockets new names and add a JSON migration that renames the old items |
| Moving a larva rocket through a script inventory with `transfer_stack` keeps its spoil progress | Copy `spoil_percent` by hand |
| The trigger force `enemy` skips forces with a cease-fire, such as the tamed force | Give the blast an explicit force list in the script instead |

## Answers

The maintainer chose these on 2026-11-14:

| Question | Answer |
| --- | --- |
| Scope | The launcher, larva rockets and their research only. Feral behaviour and the stasis ward come later |
| Targeting | Both: automatic fire at nests, and a remote for manual targets |
| Ammo | The loaded larva is the ammo. One shared casing is an ingredient of the loading recipe |
| Casing timing | The loading recipe takes a casing from the first game with this slice. The casing recipe unlocks with Ordnance loading |
| Range | 64 tiles automatic, 96 with the remote |
| Impact | A small explosion, then the monster at full health |
| Upgrades | Research for fire rate, and research for range |
| Range upgrade | The swap: 3 levels of +16 tiles, only for larva launchers |
| Remote recipe | 1 electronic circuit, 1 radar, 1 coal, 1 sulfur |
| Numbers | The agent's proposals in "Game content" are the starting values |

## Alternatives considered

| Choice | Rejected alternative | Why rejected |
| --- | --- | --- |
| Artillery turret | An ammo turret with a rocket projectile | It also shoots single biters, wasting larvae. Remote targeting would need a script |
| Artillery turret | A script that picks targets and creates projectiles | More code to test, and the script runs every few ticks |
| The loaded larva is the ammo | A separate rocket item for each loaded larva (the old `docs/design.md` text) | Doubles the ammo items: 6 more now, about 117 more later |
| The loaded larva is the ammo | One generic rocket that carries any larva | An item can only carry data as `item-with-tags`. Tagged items don't stack, and assemblers can't make them |
| Range by the swap | The `artillery-range` effect | It also extends vanilla artillery and wagons |
| Range by the swap | `artillery-range` plus a script that takes the bonus back from vanilla artillery | No API sets the range of one turret. The bonus is per force |
| Fire rate by `gun-speed` | The swap for fire rate too | `gun-speed` takes one ammo category, so it needs no script |
| Separate remotes: the vanilla flare gets `shot_category = "artillery-shell"` | Accept that the vanilla remote fires larva launchers | Marking a target for normal artillery would also spend larva rockets. The maintainer asked for separate remotes |
| Swap by destroy and create | `create_entity` with `fast_replace` | With no player, a fast replace spills the old launcher's item on the ground, and it raises no destroy event |
| A separate `ao-land-` effect ID | The slice 2 `ao-hatch-` ID, as `docs/design.md` "Launching" says | A landing reads `target_position` and needs a fallback when no spot is free |

## Proposals

The agent made these calls. The maintainer can change any of them:

- The launcher is an artillery turret, and the larva rocket is artillery
  ammo with its own ammo category, `ao-larva-rocket`.
- The slice 2 loaded larva items keep their names and become larva
  rockets. Their display name changes, for example "Biter larva rocket
  (explosive)".
- A rocket that lands where no monster fits (water, cliffs) sets off its
  payload's death effects on the spot. The search radius is the slice 2
  `hatch_search_radius` of 8 tiles.
- The blast only hurts forces at war with the launcher's force (trigger
  force `enemy`). It can't hit a loaded monster that is already near the
  spot, or the player's own buildings. In PvP, it also hurts players at
  war with the launcher's force. The design wants that.
- On a space platform a landing does nothing, as in slice 2, and the
  rocket is lost. Platforms have no natives, so a player has no reason to
  fire there.

## Game content

All numbers go in `core/balance.lua`, as in slices 1 and 2.

### Items

| Item | Type | Stack | Notes |
| --- | --- | --- | --- |
| `ao-larva-rocket-casing` | item | 50 | Shared by all larva rockets |
| `ao-<species>-larva-<payload>` | ammo | 10 | The six loaded larvae, now ammo of category `ao-larva-rocket`. Spoil time 5 min, unchanged |
| `ao-larva-launcher` | item | 10 | Places a level 0 launcher. The build handler swaps it to the force's level |
| `ao-larva-targeting-remote` | capsule | 1 | Places a larva flare (`shot_category = "ao-larva-rocket"`) |

Each larva rocket fires its own hidden projectile,
`ao-larva-projectile-<species>-<payload>`. The projectile's action lists:

1. Area damage at the target: 35 explosion damage in a 3.5-tile radius,
   only to forces at war with the launcher's force.
2. A `script` effect with the ID `ao-land-<species>-<payload>`.

### Machines

| Thing | Value |
| --- | --- |
| Launcher | 3×3 artillery turret. Graphics borrowed from the vanilla artillery turret, tinted |
| Ammo inventory | `inventory_size = 1`, `ammo_stack_limit = 5`, `automated_ammo_count = 5` |
| Fire rate | One rocket every 5 s (cooldown 300 ticks). After three speed researches, 3.1 s |
| Levels | 4 prototypes: `ao-larva-launcher` and `ao-larva-launcher-1` to `-3` |
| Range | Automatic: 64, 80, 96 and 112 tiles. Remote (`manual_range_modifier = 1.5`): 96, 120, 144 and 168 tiles |
| Launcher recipe | 20 steel, 10 iron gear wheels, 10 advanced circuits, 5 pipes, 10 s |

Each level has its own hidden gun item with the range of that level. The
menus hide levels 1 to 3. Each level 1 to 3 has
`placeable_by = { item = "ao-larva-launcher", count = 1 }` and mines back
to that item. None has a `fast_replaceable_group` or a `next_upgrade`. So
the upgrade planner does not offer the levels, and a player can't place
one level over another. Robots build a ghost of any level with the one
item.

When a player holds the item, the range preview shows level 0 (64 tiles).
The swap makes the real range larger.

### Recipes

| Recipe | Ingredients | Result | Unlocked by |
| --- | --- | --- | --- |
| `ao-larva-rocket-casing` | 2 steel, 1 explosives, 1 electronic circuit, 5 s | 1 casing | Ordnance loading |
| `ao-load-<species>-<payload>` | 1 larva, 1 payload item, 1 casing, 5 s | 1 larva rocket | Ordnance loading, as in slice 2. Only the ingredients change |
| `ao-larva-launcher` | As in "Machines" | 1 launcher | Larva rockets |
| `ao-larva-targeting-remote` | 1 electronic circuit, 1 radar, 1 coal, 1 sulfur, 2 s | 1 remote | Larva rockets |

### Research

| Tech | Needs | Cost | Effect |
| --- | --- | --- | --- |
| `ao-larva-rockets` | Ordnance loading, Rocketry | 200 × (red, green, military, blue), 30 s | Unlocks the launcher and the remote |
| `ao-larva-launcher-speed-1` to `-3` | Larva rockets, then the level before | 150, 250, 400 × the same packs | `gun-speed` +20% for `ao-larva-rocket` |
| `ao-larva-launcher-range-1` to `-3` | Larva rockets, then the level before | 150, 250, 400 × the same packs | None in the game. The script counts them |

## Runtime behaviour

### Landing

The `on_script_trigger_effect` handler decodes `ao-land-<species>-<payload>`
with a new core function, as slice 2 decodes `ao-hatch-`. For a landing it
reads `target_position`. Then it runs the slice 2 path: spawn the loaded
monster on the tamed force, record its payload in `storage.loaded`, and
order it to attack within 32 tiles.

Sometimes no free spot exists within 8 tiles. Then the handler sets off
the payload's death effects at the target position. It uses the slice 2
core function `Payloads.on_death`, with the tamed force and no cause.

A rocket that spoils, in a chest or in the launcher, runs the slice 2
`ao-hatch-` effect. Nothing changes there.

### Level

The level is not stored. `shell/launcher.lua` reads it from the force
each time: the core function returns the highest finished range
research, or 0. A
command, the editor or a research reset can change the researches, and
the level follows.

`Launcher.sync(force)` swaps every launcher of that force whose level
differs. These events call it:

- `on_research_finished` and `on_research_reversed` for a range research.
- `on_configuration_changed`, for every force.
- `on_forces_merged`, for the force that remains.
- `on_force_reset`.

The search for launchers runs once per call, over every surface, with a
name filter. It does not run every tick.

### Swap

A build event swaps one launcher if its level differs from its force's
level. The handler listens to `on_built_entity`, `on_robot_built_entity`,
`on_space_platform_built_entity`, `script_raised_built`,
`script_raised_revive` and `on_entity_cloned`, with a filter on the four
launcher names. For `on_entity_cloned` it reads `event.destination`. If
the level already matches, the handler does nothing. This also covers
the `script_raised_built` that the swap raises itself.

The swap does not use `fast_replace`, because a fast replace with no
player spills the old launcher's item on the ground. Instead, the swap:

1. Reads the old launcher's position, direction, force, quality, health,
   `artillery_auto_targeting`, last user, circuit wires and control
   behaviour settings.
2. Moves the ammo into a temporary script inventory with
   `transfer_stack`, so that the spoil timer keeps its progress.
3. Destroys the old launcher with `raise_destroy = true`, so that other
   mods can update their records. `destroy` drops no items.
4. Creates the new launcher with the same values and `raise_built = true`.
5. Moves the ammo back, reconnects the wires, copies the settings, and
   destroys the temporary inventory.

Each step can fail, and the swap never loses a launcher or a rocket:

- If `destroy` returns false, the swap moves the ammo back, destroys the
  temporary inventory and stops.
- If step 4 fails, the swap creates the old prototype again. Step 3 runs
  other mods' destroy handlers, so the spot can change in between.
- If both creates fail, the swap spills the ammo on the ground at the
  position with `spill_item_stack` and writes a log line. Only then does
  it destroy the temporary inventory.

A core function decides the next step from the result of each step, so
busted can test every branch. The swap clears the undo history for that
launcher. The design accepts that.

### Separate remotes

The vanilla artillery flare has no `shot_category`, so it would make
larva launchers fire too. In `data-final-fixes.lua`, the mod sets
`shot_category = "artillery-shell"` on the vanilla `artillery-flare`.
Then the vanilla remote fires only normal artillery, and the larva remote
fires only larva launchers.

Another mod can add artillery ammo of its own category. The vanilla flare
must still draw that ammo. So the mod first collects the ammo categories
of every artillery gun. These are the guns that the `gun` fields in
`data.raw["artillery-turret"]` and `data.raw["artillery-wagon"]` name,
except the larva launcher's own guns.

A gun names its categories in `attack_parameters.ammo_category` or
`attack_parameters.ammo_categories`, and the mod reads both. If any
category other than `artillery-shell` exists, the mod leaves the vanilla
flare alone and writes one line to the log. In that case the vanilla
remote fires larva launchers again. A core function makes this decision
from the list of categories.

### Old saves

- Slice 2 loaded larvae keep their names, so they stay in old saves as
  larva rockets. The probe checks this.
- `shell/setup.lua` already resets technology effects in
  `on_configuration_changed`. Old saves with Ordnance loading get the
  casing recipe that way.
- `on_configuration_changed` calls `Launcher.sync` for every force.
- The slice adds two `storage` fields, `storage.trails` and
  `storage.trail_cursor` (see "Acid trail batching").

### Acid trail batching

`docs/architecture.md` (Performance) asks for the acid trail to be
batched at the latest with larva rockets. Each launcher adds a monster
every few seconds, so this slice does it, in its own pull request.

- A new field, `storage.trails`, holds only the monsters with a trail,
  by unit number. `storage.loaded` keeps all loaded monsters, as now.
- The handler runs every tick and visits up to `Balance.trail_batch`
  entries (start value 5). Up to 300 trail monsters, each one leaves a
  puddle about once a second, as in slice 2. With more, the gap grows: 2 s
  at 600.
- The handler keeps its place in `storage.trail_cursor`. When a monster
  leaves, `on_object_destroyed` first moves the cursor past it, then
  removes the entry. If the cursor's entry no longer exists, the next pass
  starts at the beginning.
- A new monster can wait until the next pass. Lua does not define the
  order of `next()` after a new key, so a monster can also miss one pass
  or get two puddles in one pass. The trail only marks the ground, so the
  design accepts all three.
- `on_init` and `on_configuration_changed` create both fields. An old
  save fills `storage.trails` from the entries in `storage.loaded` that
  have a trail.

## Architecture

The rules in `docs/architecture.md` apply. New and changed modules:

| Module | Layer | Job |
| --- | --- | --- |
| `core/launcher.lua` | core | Level from a list of finished researches, turret name for a level, range for a level |
| `core/payloads.lua` | core | Decodes `ao-land-` IDs as well |
| `core/prototypes/launcher.lua` | core | Builds the casing, launcher levels, guns, projectiles, flare, remote, ammo category and research |
| `core/prototypes/ordnance.lua` | core | Loaded larvae become ammo, and loading recipes take a casing |
| `shell/launcher.lua` | shell | Reads the level, `sync` and the swap, so that the in-game tests can call them |
| `core/flare.lua` | core | Decides from a list of ammo categories whether the vanilla flare gets `artillery-shell` |
| `control.lua` | shell | Landing handler, research, force and build handlers, batched acid trail |
| `data-final-fixes.lua` | shell | Collects the artillery ammo categories and sets the vanilla flare's `shot_category` |
| `data.lua` | shell | Passes the artillery turret's graphics to the builder |

## Testing

### Unit tests (busted)

- The launcher, its levels, guns and projectiles have the numbers in
  "Game content".
- Each larva rocket's projectile lists the blast first, then
  `ao-land-<species>-<payload>`.
- The loading recipes take a casing, and the casing recipe unlocks with
  Ordnance loading.
- The remote's flare has `shot_category = "ao-larva-rocket"`.
- The levels 1 to 3 are `placeable_by` the launcher item, and no level
  has a `fast_replaceable_group` or a `next_upgrade`.
- The flare decision: the vanilla flare gets `artillery-shell` when the
  artillery guns use only that category. It stays alone when another
  category exists, also when only an artillery wagon's gun uses it, and
  when a gun lists it in `ammo_categories`.
- The swap decision for each step result: destroy failed, create failed,
  both creates failed.
- The level is the highest finished range research, or 0.
- The name and range for each level. A missing or unknown level counts
  as level 0.
- `ao-land-` decodes to the species and payload, and other IDs do not.

### In-game tests (factorio-test, both modes)

- A larva rocket that lands spawns the right loaded monster on the tamed
  force at full health, and records its payload.
- The blast damages a native unit at the spot, and not a loaded monster
  or a player building.
- A rocket that lands in water sets off its payload.
- A launcher with ammo fires at a spawner in range, and not at a single
  biter.
- A larva flare makes a larva launcher fire, and not a vanilla artillery
  turret. A vanilla flare makes a vanilla artillery turret fire, and not a
  larva launcher.
- A finished range research swaps a placed launcher to the next level.
  The new launcher keeps its quality, health, ammo freshness and wires.
  No item lies on the ground afterwards, and the player's item count is
  unchanged.
- A reversed range research swaps it back.
- A launcher built after the research is at the force's level. A robot
  builds a level 2 ghost on a level 0 force as a level 0 launcher.
- An old save with loaded larvae keeps them as larva rockets.
- With 300 acid monsters, each one leaves a puddle about once a second.
- A monster that dies while the cursor points at it does not stop the
  trail of the others.

## Delivery

### Probe

Before the build, a throwaway probe mod checks the facts in the table in
"Facts found during design". The plan follows the fallback for each fact
that fails.

### Pull requests

1. **Batched acid trail.** It does not depend on the launcher, so it goes
   first and gets its own review.
2. **Launcher and rockets.** Casing, ammo items, launcher at level 0,
   remote, flare, separate remotes, projectiles, landing, the Larva
   rockets research and the speed upgrades.
3. **Range levels.** The level prototypes, the range researches, `sync`
   and the swap.

Each PR follows the workflow in `CLAUDE.md`, with a CHANGELOG entry.

## Risks

- **Spoiling in the launcher.** A rocket that waits too long in the
  launcher hatches next to it. That is by design. The ammo inventory holds
  5 rockets, so a player loses 5 rockets at most.
- **Idle monsters pile up.** The engine never removes a loaded monster on
  its own, because the payload must go off first. Once their nests are
  dead, idle monsters stay in the world and in `storage.loaded`.
  Slice 4 turns monsters that stay idle for 5 minutes feral. Until then,
  the batched trail keeps the cost per tick fixed.
- **Mods that load later.** A mod whose `data-final-fixes.lua` runs
  after this mod can add artillery ammo or change the vanilla flare. The
  scan does not see that. Then the vanilla remote can fire larva
  launchers again.
- **Lost stats.** An artillery turret has no `kills` or `damage_dealt` in
  the API, so the swap can't keep them.
- **Wasted rockets with other artillery mods.** If another mod adds its
  own artillery ammo, the vanilla remote fires larva launchers again. The
  log says so.
- **The swap and other mods.** A mod that tracks the launcher by its unit
  number loses it after a swap. The swap raises the built and destroy
  events, so those mods can update their records.
- **Item count.** Slice 3 adds 3 visible items: the casing, the launcher and
  the remote. The levels, guns, projectiles and flare are hidden.

## Changes to `docs/design.md` and `ROADMAP.md`

- "Logistics and delivery": the larva launcher is an artillery turret that
  fires loaded larvae as ammo. A shared casing replaces a separate rocket
  per larva.
- "Technical risks": the number of ammo prototypes drops, because larva
  rockets are the loaded larvae.
- "Technical notes", "Launching": a landing uses its own `ao-land-` effect
  ID, not the spoil effect.
- "Decisions and rejected alternatives": add the ammo choice, the range
  swap and the `ao-land-` ID.
- Open question for design version 2: larva rockets are artillery-type
  ammo. Artillery shells could reuse them, with no new item per larva.
- "Feral behaviour and risks": note the pheromone flare idea for slice 4.
- `ROADMAP.md`: tick "Larva rockets and the larva launcher" when PR 3
  merges.

## Out of scope

- Feral behaviour, slice 4.
- The stasis ward, slice 5.
- Artillery shells for loaded larvae, design version 2.
- The pheromone flare.
- Facehuggers as launcher ammo, design version 2.
