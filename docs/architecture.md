# Architecture: shell and core

These are the rules for the code of Abominable Ordnance, a Factorio 2.1
mod. Follow them when you change mod code. The mod has two layers. The
shell talks to the game. The core makes decisions and never touches the
game.

## The shell

Event handlers, `storage` and the game API calls are the shell. Keep each
handler short: read from the game, call the core, then write the result to
the game.

`control.lua` holds the event handlers. The folder `shell/` holds game API code
that `control.lua` and the in-game tests both call:

- `shell/tamed.lua` sets up the forces.
- `shell/damage.lua` deals the payload damage.
- `shell/feral.lua` runs the feral behaviour.
- `shell/launcher.lua` runs the launcher.
- `shell/setup.lua` holds `on_init` and `on_configuration_changed`.

All other shell code stays in `control.lua`. The in-game tests live in
`tests/ingame/`. `make ingame` runs them in a real Factorio with the
factorio-test mod.

## The core

Pure modules in `core/` make the decisions, for example hatch picks,
payload effects, nest loot, recipe generation and balance numbers. A core
module never names `game`, `storage`, `script`, `defines`, `prototypes`,
`rendering`, `helpers`, `remote`, `commands`, `rcon`, `settings`, `mods`
or `data`.

These are Factorio globals. Plain Lua 5.2 lacks them, so a core module
that avoids them loads outside the game, and busted can test it. When the
core needs a fact from the game, the shell passes it in: a plain value, or
a function such as `entity_exists`.

A simplified pair from the mod shows the split. The full code is
`Payloads.on_death` in `core/payloads.lua` and `Damage.detonate` in
`shell/damage.lua`. The core returns one plan per payload as data:

```lua
-- core: a pure function
function Payloads.on_death(names, position, exists)
  -- Returns one plan per payload: the entities to create, and the hit
  -- for the shell to deal.
end
```

The shell reads the detonation from `storage`, calls the core, adds the
force, creates the entities and deals the hit:

```lua
-- shell: shell/damage.lua
for _, plan in ipairs(Payloads.on_death({ d.payload }, d.position, entity_exists)) do
  for _, entity in ipairs(plan.entities) do
    entity.force = d.force
    surface.create_entity(entity)
  end
  if plan.hit then
    Damage.hit({ surface = surface, position = d.position, payload = plan.payload, ... })
  end
end
```

## The data stage

`data.lua` is the shell of the data stage. It reads `mods` and
`data.raw`, passes plain values to the pure builders in
`core/prototypes/`, and calls `data:extend` with the result. For example,
it passes the centrifuge's graphics to `Ordnance.prototypes`, which
returns the incubator.

`data-final-fixes.lua` is a second shell. It builds the look-alikes with
`Ordnance.lookalikes` from the vanilla effects as they stand after every
mod's data and data-updates stages. A mod that loads after this one sees
`ao-poison-cloud` and `ao-acid-pool` in its own data-final-fixes stage.

The builders then need no game, so busted tests them like any core module.

## Determinism

Every computer in a multiplayer game runs the same script and must get
the same result. A difference breaks the sync, and the game stops. So:

- Never use `math.random` in the control stage. Factorio makes it
  deterministic, but it draws from the map's generator, which the game and
  every other mod share, and it fails outside events. Make a generator
  with `game.create_random_generator()` from a seed in `storage`. The
  shell passes the core a number from it, or the generator itself.
- Keep all state that changes during play in `storage`. A module-level
  variable that changes after load is not saved, and it differs between a
  player who joined late and one who did not.
  One exception: a re-entry guard that one call sets and clears again
  before it returns. It is false between events, so every player has
  the same value. `shell/launcher.lua` uses one around the step that
  builds the old level again, so that a swap does not swap the launcher
  it builds.
- `on_load` must not write to `storage` or the game.
- Register the same events after `on_init` and after `on_load`. A handler
  that only some clients register breaks the sync.

## Old saves

A player can add the mod to an old save, or update it. The code must keep
that save working:

- Create each `storage` field in `on_init` and in `on_configuration_changed`,
  as `storage.x = storage.x or default`. A second run then does no harm
  (`shell/setup.lua`). The code may create a field later when every reader
  reads it as `storage.x or default`. `storage.seed` does this, and so do the
  cursors and next-tick fields of the trail and feral passes.
- After a change to techs or recipes, call `reset_technology_effects()` on
  each force in `on_configuration_changed`. Old saves then get the new
  unlocks.
- A stored entity can disappear. Check `.valid` before you use it.
- A change to the shape of a `storage` field needs a rebuild in
  `on_configuration_changed`, for example the rebuild of `storage.trails`
  in `shell/setup.lua`. Use a migration file in `migrations/` only when the
  rebuild cannot run there.
- `storage.trails` keeps its old name. It lists every loaded monster with a
  live effect (the acid trail and the poison aura), and the trail pass runs
  them all.

## Other mods

Other mods share the game with this mod:

- Every mod gets every `on_object_destroyed` event and every `script`
  trigger effect. A handler decodes the event and ignores anything that is
  not this mod's.
- Another mod can remove a prototype. Before `create_entity`, check that
  the prototype exists (`entity_exists`). In the data stage, check a
  `data.raw` lookup for nil.
- Another mod can add forces. The force rules in `core/forces.lua` must
  give a result for a force they do not know.

## Performance

Factorio runs 60 updates per second, and every handler costs time in each
one:

- Use an event filter whenever the API offers one, as the
  `on_entity_died` handler does.
- Keep `on_tick` and `on_nth_tick` work small. Its cost must grow with the
  number of players or with a fixed batch size, not with every tracked
  unit. `core/trail.lua` is the pattern to reuse for per-tick work over
  tracked units. It visits a fixed batch of units each tick and keeps a
  cursor in `storage`.

## Type annotations

LuaLS checks the mod against the Factorio API, but only values whose type
it knows. Give the shell code types:

- A named event handler gets `---@param event EventData.<event name>`.
  An inline handler needs no annotation.
- A prototype table for `data:extend` gets `---@type <Prototype class>`,
  for example `---@type ItemPrototype`.

LuaLS does not check values from `storage`, `data.raw` lookups with keys
that the code builds, or values of type `any`. The busted tests and the
in-game tests check those.

## Tests for these rules

`spec/architecture_spec.lua` enforces two rules on every commit, with the
checks in `spec/support/architecture.lua`:

- A module in `core/` never names a global from the list in
  [The core](#the-core). A name in a comment or a string does not count.
- No file in `core/`, `shell/` or `control.lua` uses `math.random`.

`spec/docs_spec.lua` checks that the list in [The core](#the-core) is the
same as the list in `spec/support/architecture.lua`, and that this file
still forbids `math.random`. Code review checks the other rules, through
the review angles in `CLAUDE.md`.
