# Architecture: shell and core

These are the rules for the code of Abominable Ordnance, a Factorio 2.1
mod. Follow them when you change mod code. The mod has two layers. The
shell talks to the game. The core makes decisions and never touches the
game.

## The shell

Event handlers, `storage` and the game API calls are the shell. Keep each
handler short: read from the game, call the core, then write the result to
the game.

`control.lua` holds the event handlers. The folder `shell/` holds game API
code that `control.lua` and the in-game tests both call, for example the
force setup in `shell/tamed.lua`. All other shell code stays in
`control.lua`. The in-game tests live in `tests/ingame/`. `make ingame`
runs them in a real Factorio with the factorio-test mod.

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
`Payloads.on_death` in `core/payloads.lua` and `set_off` in
`control.lua`. The core returns the effects as data:

```lua
-- core: a pure function
function Payloads.on_death(names, position, exists)
  -- returns a list of create_entity tables, one per effect
end
```

The shell reads `storage`, calls the core, adds the force and the cause,
and creates the entities:

```lua
-- shell: control.lua
local entry = storage.loaded[entity.unit_number]
for _, effect in ipairs(Payloads.on_death(entry.payloads, entity.position, entity_exists)) do
  effect.force = Names.TAMED
  entity.surface.create_entity(effect)
end
```

## The data stage

`data.lua` is the shell of the data stage. It reads `mods` and
`data.raw`, passes plain values to the pure builders in
`core/prototypes/`, and calls `data:extend` with the result. For example,
it passes the centrifuge's graphics to `Ordnance.prototypes`, which
returns the incubator.

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
- `on_load` must not write to `storage` or the game.
- Register the same events after `on_init` and after `on_load`. A handler
  that only some clients register breaks the sync.

## Old saves

A player can add the mod to an old save, or update it. The code must keep
that save working:

- Create each `storage` field in `on_init` and in
  `on_configuration_changed`, as `storage.x = storage.x or default`. A
  second run then does no harm (`shell/setup.lua`). The code may create a
  field later when every reader reads it as `storage.x or default`, as
  with `storage.seed`.
- After a change to techs or recipes, call `reset_technology_effects()` on
  each force in `on_configuration_changed`. Old saves then get the new
  unlocks.
- A stored entity can disappear. Check `.valid` before you use it.
- A change to the shape of a `storage` field needs a migration file in
  `migrations/`.

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
  unit. One known exception: the acid trail loops over all loaded
  monsters once a second. Batch it before loaded monsters come in the
  hundreds, at the latest with larva rockets.

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
