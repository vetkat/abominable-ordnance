-- The control stage. This file is the shell: it reads the game, calls the
-- pure modules in core/ and writes the result to the game.
local Balance = require("core.balance")
local Hatching = require("core.hatching")
local Loot = require("core.loot")
local Names = require("core.names")
local Payloads = require("core.payloads")
local Species = require("core.species")
local Tamed = require("shell.tamed")

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

-- Creates one of the units near a position, sized by the
-- evolution there, and sends it to attack the area. A unit with no
-- command stands still until something provokes it. Returns the unit, or
-- nil when no unit or no free spot exists.
local function spawn(surface, position, units, force)
  units = Hatching.available(units, unit_exists)
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

script.on_init(Tamed.ensure)
script.on_configuration_changed(function()
  Tamed.ensure()
end)
script.on_event(defines.events.on_force_created, function(event)
  Tamed.on_force_created(event.force)
end)

-- A loaded monster fights the natives. The engine must not destroy it
-- when a command fails, or its payload would never go off.
local function load_monster(monster, payload)
  monster.ai_settings.allow_destroy_when_commands_fail = false
  monster.ai_settings.allow_try_return_to_spawner = false
  storage.loaded[monster.unit_number] = { unit = monster, payloads = { payload.name } }
  script.register_on_object_destroyed(monster)
end

script.on_event(defines.events.on_script_trigger_effect, function(event)
  -- Other mods' triggers reach this handler too.
  local loaded, payload = Payloads.decode(event.effect_id)
  local species = loaded or Species.by_effect_id(event.effect_id)
  if not species then
    return
  end
  local surface = game.get_surface(event.surface_index)
  local position = event.source_position or event.target_position
  if not surface or not position or surface.platform then
    return
  end
  local monster = spawn(surface, position, species.units, loaded and Names.TAMED or "enemy")
  if monster and loaded then
    load_monster(monster, payload)
  end
end)

-- A dead native spawner drops eggs beside its corpse.
local function nest_loot(event)
  -- The tamed force has no research, but its kills feed the egg supply.
  local force = event.force
  local researched = force ~= nil
    and (force.name == Names.TAMED or force.technologies[Names.TECH].researched)
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
end

-- A loaded monster sets off its payload where it dies.
local function set_off(entity)
  local entry = storage.loaded[entity.unit_number]
  if not entry then
    return
  end
  for _, effect in ipairs(Payloads.on_death(entry.payloads, entity.position, unit_exists)) do
    effect.force = Names.TAMED
    effect.cause = entity
    entity.surface.create_entity(effect)
  end
end

script.on_event(defines.events.on_entity_died, function(event)
  if event.entity.type == "unit-spawner" then
    nest_loot(event)
  else
    set_off(event.entity)
  end
end, { { filter = "type", type = "unit-spawner" }, { filter = "type", type = "unit" } })

-- Runs after on_entity_died, and also when a unit leaves without dying.
script.on_event(defines.events.on_object_destroyed, function(event)
  if event.type == defines.target_type.entity then
    storage.loaded[event.useful_id] = nil
  end
end)

-- factorio-test runs the in-game tests. The hook does nothing unless the
-- factorio-test mod is active.
if script.active_mods["factorio-test"] then
  require("__factorio-test__/init")({
    "tests/ingame/smoke_test",
    "tests/ingame/content_test",
    "tests/ingame/hatching_test",
    "tests/ingame/loot_test",
    "tests/ingame/ordnance_test",
  })
end
