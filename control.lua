-- The control stage. This file is the shell: it reads the game, calls the
-- pure modules in core/ and writes the result to the game.
local Balance = require("core.balance")
local Hatching = require("core.hatching")
local Loot = require("core.loot")
local Names = require("core.names")
local Species = require("core.species")

-- A deterministic random number in [0, 1). storage keeps only the seed.
local function random()
  local rng = game.create_random_generator(storage.seed or 1)
  local r = rng()
  storage.seed = rng(1, 2147483647)
  return r
end

script.on_event(defines.events.on_script_trigger_effect, function(event)
  -- Other mods' triggers reach this handler too.
  local species = Species.by_effect_id(event.effect_id)
  if not species then
    return
  end
  local surface = game.get_surface(event.surface_index)
  local position = event.source_position or event.target_position
  if not surface or not position or surface.platform then
    return
  end
  local evolution = game.forces["enemy"].get_evolution_factor(surface)
  local unit = Hatching.pick(species.units, evolution, random())
  local spot = surface.find_non_colliding_position(unit, position, Balance.hatch_search_radius, 0.5)
  if spot then
    surface.create_entity({ name = unit, position = spot, force = "enemy" })
  end
end)

local spawner_filters = {}
for _, species in ipairs(Species.ALL) do
  spawner_filters[#spawner_filters + 1] = { filter = "name", name = species.spawner }
end

script.on_event(defines.events.on_entity_died, function(event)
  local researched = event.force ~= nil and event.force.technologies[Names.TECH].researched
  local entity = event.entity
  local drop = Loot.drop(entity.name, researched, random())
  if drop then
    entity.surface.spill_item_stack({
      position = entity.position,
      stack = drop,
      drop_full_stack = true,
      enable_looted = true,
    })
  end
end, spawner_filters)

-- factorio-test runs the in-game tests. The hook does nothing unless the
-- factorio-test mod is active.
if script.active_mods["factorio-test"] then
  require("__factorio-test__/init")({
    "tests/ingame/smoke_test",
    "tests/ingame/content_test",
    "tests/ingame/hatching_test",
    "tests/ingame/loot_test",
  })
end
