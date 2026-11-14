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

local function unit_exists(name)
  return prototypes.entity[name] ~= nil
end

-- Creates a monster of the species near a position, sized by the
-- evolution there, and sends it to attack the area. A unit with no
-- command stands still until something provokes it. Returns the unit, or
-- nil when no unit or no free spot exists.
local function spawn(surface, position, species, force)
  local units = Hatching.available(species.units, unit_exists)
  if #units == 0 then
    return nil
  end
  local evolution = game.forces["enemy"].get_evolution_factor(surface)
  local unit = Hatching.pick(units, evolution, random())
  local spot = surface.find_non_colliding_position(unit, position, Balance.hatch_search_radius, 0.5)
  if not spot then
    return nil
  end
  local monster = surface.create_entity({ name = unit, position = spot, force = force })
  if monster and monster.commandable then
    monster.commandable.set_command({
      type = defines.command.attack_area,
      destination = spot,
      radius = Balance.hatch_attack_radius,
    })
  end
  return monster
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
  spawn(surface, position, species, "enemy")
end)

script.on_event(defines.events.on_entity_died, function(event)
  local researched = event.force ~= nil and event.force.technologies[Names.TECH].researched
  local entity = event.entity
  local drop = Loot.drop(entity.name, researched, random())
  if not drop then
    return
  end
  local box = entity.selection_box
  local spot = Loot.beside(entity.position, (box.right_bottom.x - box.left_top.x) / 2)
  entity.surface.spill_item_stack({
    position = spot,
    stack = drop,
    drop_full_stack = true,
    enable_looted = true,
  })
  rendering.draw_text({
    text = Loot.label(drop),
    surface = entity.surface,
    target = spot,
    color = { r = 1, g = 1, b = 1 },
    scale = 1.5,
    alignment = "center",
    use_rich_text = true,
    time_to_live = Balance.loot_label_ticks,
  })
end, { { filter = "type", type = "unit-spawner" } })

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
