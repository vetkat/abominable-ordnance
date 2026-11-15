-- The control stage. This file is the shell: it reads the game, calls the
-- pure modules in core/ and writes the result to the game.
local Balance = require("core.balance")
local Hatching = require("core.hatching")
local Forces = require("core.forces")
local Launcher = require("core.launcher")
local Loot = require("core.loot")
local Names = require("core.names")
local Payloads = require("core.payloads")
local Species = require("core.species")
local FeralShell = require("shell.feral")
local LauncherShell = require("shell.launcher")
local Setup = require("shell.setup")
local Tamed = require("shell.tamed")
local Trail = require("core.trail")

-- A deterministic random number in [0, 1). storage keeps only the seed.
local function random()
  local rng = game.create_random_generator(storage.seed or 1)
  local r = rng()
  storage.seed = rng(1, 2147483647)
  return r
end

local function entity_exists(name)
  return prototypes.entity[name] ~= nil
end

-- Creates one of the units near a position, sized by the
-- evolution there, and sends it to attack the area. A unit with no
-- command stands still until something provokes it. Returns the unit, or
-- nil when no unit or no free spot exists.
local function spawn(surface, position, units, force)
  units = Hatching.available(units, entity_exists)
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

script.on_init(Setup.on_init)
script.on_configuration_changed(Setup.on_configuration_changed)
script.on_event(defines.events.on_force_created, function(event)
  Tamed.relate(event.force)
end)
script.on_event(defines.events.on_force_reset, function(event)
  -- A reset may clear diplomacy, so relate the force again.
  Tamed.relate(event.force)
  LauncherShell.sync(event.force)
end)
script.on_event(defines.events.on_forces_merged, function(event)
  Tamed.ensure()
  LauncherShell.sync(event.destination)
end)

-- Every launcher stays at its force's level. A range research or its
-- reversal swaps the placed launchers, and the swap also catches a built
-- launcher when it arrives. The build events have a filter on the four
-- launcher names.
local function research_changed(event)
  if Launcher.is_range_tech(event.research.name) then
    LauncherShell.sync(event.research.force)
  end
end
script.on_event(defines.events.on_research_finished, research_changed)
script.on_event(defines.events.on_research_reversed, research_changed)

local LAUNCHER_FILTER = {}
for _, name in ipairs(Launcher.NAMES) do
  LAUNCHER_FILTER[#LAUNCHER_FILTER + 1] = { filter = "name", name = name }
end

local function built(event)
  LauncherShell.on_built(event.entity)
end
for _, id in ipairs({
  defines.events.on_built_entity,
  defines.events.on_robot_built_entity,
  defines.events.on_space_platform_built_entity,
  defines.events.script_raised_built,
  defines.events.script_raised_revive,
}) do
  script.on_event(id, built, LAUNCHER_FILTER)
end
script.on_event(defines.events.on_entity_cloned, function(event)
  LauncherShell.on_built(event.destination)
end, LAUNCHER_FILTER)

-- A loaded monster fights the natives. The engine must not destroy it
-- when a command fails, or its payload would never go off.
local function load_monster(monster, payload)
  monster.ai_settings.allow_destroy_when_commands_fail = false
  monster.ai_settings.allow_try_return_to_spawner = false
  local payloads = { payload.name }
  local trail = Payloads.trail(payloads)
  local entry = {
    unit = monster,
    payloads = payloads,
    trail = trail and entity_exists(trail) and trail or nil,
  }
  storage.loaded[monster.unit_number] = entry
  if entry.trail then
    storage.trails[monster.unit_number] = true
  end
  script.register_on_object_destroyed(monster)
end

-- The landing blast. The launcher's force deals the damage, so kills
-- count for it.
local function blast(surface, position, launcher)
  local attacker = launcher and launcher.valid and launcher.force or nil
  local targets = surface.find_entities_filtered({
    position = position,
    radius = Balance.blast.radius,
  })
  for _, target in pairs(targets) do
    if
      target.valid
      and target.is_entity_with_health
      and Forces.blast_hits(
        target.force.name,
        attacker and attacker.name,
        attacker ~= nil and attacker.is_enemy(target.force)
      )
    then
      local cause = attacker and launcher
      target.damage(Balance.blast.damage, attacker or "neutral", "explosion", nil, cause)
    end
  end
end

-- A larva rocket lands. The blast goes first, then the loaded monster
-- takes the nearest free spot, so the blast can't hurt it. With no free
-- spot, for example in water, the payload goes off where the rocket
-- landed. A projectile's source is the launcher, so the landing reads
-- the target position.
local function land(event, species, payload)
  local surface = game.get_surface(event.surface_index)
  local position = event.target_position
  if not surface or not position or surface.platform then
    return
  end
  blast(surface, position, event.source_entity)
  local monster = spawn(surface, position, species.units, Names.TAMED)
  if monster then
    load_monster(monster, payload)
    return
  end
  for _, effect in ipairs(Payloads.on_death({ payload.name }, position, entity_exists)) do
    effect.force = Names.TAMED
    surface.create_entity(effect)
  end
end

script.on_event(defines.events.on_script_trigger_effect, function(event)
  local landed, landed_payload = Payloads.decode_land(event.effect_id)
  if landed then
    land(event, landed, landed_payload)
    return
  end
  local loaded, payload = Payloads.decode(event.effect_id)
  local species = loaded or Species.by_effect_id(event.effect_id)
  -- Other mods' triggers reach this handler too.
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
  local force = event.force
  local researched = force ~= nil
    and Forces.earns_loot(force.name, force.technologies[Names.TECH].researched)
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
  for _, effect in ipairs(Payloads.on_death(entry.payloads, entity.position, entity_exists)) do
    effect.force = FeralShell.force_of(entry)
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
-- Every mod gets every registration, and only entities have a unit
-- number as useful_id. The trail cursor moves past the unit first,
-- because next() needs the key in the table. The feral cursor moves past
-- the unit in the same way.
script.on_event(defines.events.on_object_destroyed, function(event)
  if event.type == defines.target_type.entity then
    local id = event.useful_id
    if storage.loaded[id] then
      storage.trail_cursor = Trail.forget(storage.trails, storage.trail_cursor, id)
      storage.feral_cursor = Trail.forget(storage.loaded, storage.feral_cursor, id)
      storage.trails[id] = nil
      storage.loaded[id] = nil
    end
  end
end)

-- An acid-loaded monster leaves a small acid puddle where it walks. Each
-- tick visits at most Balance.trail_batch monsters, and a new pass starts
-- at most once per Balance.acid_trail_ticks.
local function trail_tick(tick)
  local go, next_tick =
    Trail.start(storage.trail_cursor, tick, storage.trail_next_tick, Balance.acid_trail_ticks)
  if not go then
    return
  end
  storage.trail_next_tick = next_tick
  local ids, cursor = Trail.batch(storage.trails, storage.trail_cursor, Balance.trail_batch)
  storage.trail_cursor = cursor
  for _, id in ipairs(ids) do
    local entry = storage.loaded[id]
    -- Another mod can remove the trail entity after the monster hatched.
    if entry and entry.unit.valid and entity_exists(entry.trail) then
      entry.unit.surface.create_entity({
        name = entry.trail,
        position = entry.unit.position,
        force = FeralShell.force_of(entry),
      })
    end
  end
end

-- The batch check walks storage.loaded with its own cursor. Each tick
-- checks at most Balance.feral.batch monsters, and a new pass starts at
-- most once per Balance.feral.pass_ticks.
local function feral_tick(tick)
  if not FeralShell.available() then
    return
  end
  local f = Balance.feral
  local go, next_tick =
    Trail.start(storage.feral_cursor, tick, storage.feral_next_tick, f.pass_ticks)
  if not go then
    return
  end
  storage.feral_next_tick = next_tick
  local ids, cursor = Trail.batch(storage.loaded, storage.feral_cursor, f.batch)
  storage.feral_cursor = cursor
  for _, id in ipairs(ids) do
    FeralShell.check(id, tick, random)
  end
end

script.on_event(defines.events.on_tick, function(event)
  trail_tick(event.tick)
  feral_tick(event.tick)
end)

script.on_event(defines.events.on_ai_command_completed, FeralShell.completed)

-- The too-close scan: one search around each connected player every
-- scan_ticks, so the cost grows with players, not with monsters.
script.on_nth_tick(Balance.feral.scan_ticks, function(event)
  if next(storage.loaded) == nil or not FeralShell.available() then
    return
  end
  for _, player in pairs(game.connected_players) do
    FeralShell.scan_player(player, event.tick)
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
    "tests/ingame/launcher_test",
    "tests/ingame/launcher_range_test",
    "tests/ingame/stasis_test",
    "tests/ingame/feral_test",
  })
end
