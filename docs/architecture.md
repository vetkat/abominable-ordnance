# Factorio 2.1 mods

A Factorio mod has two layers. The shell talks to the game. The core
makes decisions and never touches the game.

## The shell

Event handlers, `storage`, and the calls to `game.*` and `surface.*` are
the shell. Keep each handler short: read from the game, call the core,
then write the result to the game.

Shell code that the in-game tests must also call goes in `shell/`, for
example the setup of a force. A `shell/` module may use the game API,
because it is not core.

## The core

Pure modules make the decisions, for example feral checks, payload
stacks, recipe generation and balance numbers. A core module never names
`game`, `storage`, `script` or `defines`. So it loads under plain Lua 5.2,
and busted can test it outside the game.

```lua
-- core/effects.lua: pure
local Effects = {}
function Effects.on_death(payloads, position)
  local out = {}
  for _, p in ipairs(payloads) do
    out[#out + 1] = { name = p.explosion, position = position }
  end
  return out
end
return Effects

-- control.lua: shell
script.on_event(defines.events.on_entity_died, function(event)
  local unit = event.entity
  local payloads = storage.loaded[unit.unit_number] or {}
  for _, e in ipairs(Effects.on_death(payloads, unit.position)) do
    unit.surface.create_entity(e)
  end
end)
```

A test can enforce the boundary:

```lua
it("keeps the core free of the game API", function()
  for _, path in ipairs({ "core/effects.lua" }) do
    local src = assert(io.open(path)):read("*a")
    for _, name in ipairs({ "game%.", "storage", "script%.", "defines%." }) do
      assert.is_nil(src:find(name), path .. " uses " .. name)
    end
  end
end)
```

## The data stage

Make the data stage a pure function from settings to prototype tables. The
file that calls `data:extend` is the shell:

```lua
data:extend(Larvae.prototypes(settings.startup))
```

## Determinism

The control stage must give the same result on every computer, or
multiplayer games desync. Do not use `math.random` there. Use a generator
from `game.create_random_generator()`, and pass it into the core as a
parameter.

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

`spec/architecture_spec.lua` enforces two rules on every commit:

- A module in `core/` never names `game`, `storage`, `script` or
  `defines`.
- Neither `core/` nor `control.lua` uses `math.random`.

`spec/docs_spec.lua` checks that this file still names the same game API
as the test.
