-- Feral behaviour in the game. This module is shell: it reads and
-- writes the game. control.lua calls it, and so do the in-game tests.
-- The decisions live in core/feral.lua.
local Balance = require("core.balance")
local Feral = require("core.feral")
local Names = require("core.names")

local FeralShell = {}

-- Feral behaviour is off when the force limit kept the feral force out.
function FeralShell.available()
  return game.forces[Names.FERAL] ~= nil
end

-- The force of a loaded monster's payload and trail.
function FeralShell.force_of(entry)
  if entry.feral and FeralShell.available() then
    return Names.FERAL
  end
  return Names.TAMED
end

-- A wander with a time limit, so that the next batch check searches
-- again.
function FeralShell.wander(entry)
  local f = Balance.feral
  entry.hunting = false
  entry.unit.commandable.set_command({
    type = defines.command.wander,
    radius = f.search_radius,
    ticks_to_wait = f.rewander_ticks,
  })
end

-- A feral monster attacks the nearest enemy within seek_distance. A
-- marked monster wanders instead, and so does one with no target.
function FeralShell.hunt(entry, tick)
  local f = Balance.feral
  local unit = entry.unit
  if Feral.marked(entry, tick) then
    FeralShell.wander(entry)
    return
  end
  entry.failed_at = nil
  local target = unit.surface.find_nearest_enemy_entity_with_owner({
    position = unit.position,
    max_distance = f.seek_distance,
    force = unit.force,
  })
  if not target then
    FeralShell.wander(entry)
    return
  end
  entry.hunting = true
  unit.commandable.set_command({
    type = defines.command.attack_area,
    destination = target.position,
    radius = f.search_radius,
  })
end

-- Moves a loaded monster to the feral force, sends it hunting and shows
-- a warning above it.
function FeralShell.go_feral(entry, tick)
  local unit = entry.unit
  if not unit.valid or entry.feral or not FeralShell.available() then
    return
  end
  unit.force = Names.FERAL
  entry.feral = true
  FeralShell.hunt(entry, tick)
  rendering.draw_text({
    text = { "ao-feral.warning" },
    surface = unit.surface,
    target = { entity = unit, offset = { 0, -2 } },
    color = { r = 1, g = 0.2, b = 0.2 },
    scale = 1.5,
    alignment = "center",
    time_to_live = Balance.feral.warning_ticks,
  })
end

-- The too-close scan for one player. A player counts with a character,
-- on a force at peace with the tamed force, off a space platform. The
-- character's position is the vehicle's position when the player
-- drives.
function FeralShell.scan_player(player, tick)
  local character = player.character
  if not (character and character.valid) then
    return
  end
  local tamed = game.forces[Names.TAMED]
  local surface = character.surface
  local at_peace = tamed ~= nil and tamed.get_cease_fire(player.force)
  if not Feral.player_counts(true, at_peace, surface.platform ~= nil) then
    return
  end
  local position = character.position
  local units = surface.find_entities_filtered({
    position = position,
    radius = Feral.largest_radius(),
    force = Names.TAMED,
    type = "unit",
  })
  for _, unit in pairs(units) do
    local entry = storage.loaded[unit.unit_number]
    if entry and entry.unit == unit then
      local distance = Feral.distance(position, unit.position)
      if Feral.too_close(entry, distance, unit.name) then
        FeralShell.go_feral(entry, tick)
      end
    end
  end
end

-- The batch check for one loaded monster. A feral monster without a
-- command hunts again. A tamed monster updates its idle clock and may
-- go feral. roll is a random number in [0, 1) from control.lua.
function FeralShell.check(id, tick, roll)
  local f = Balance.feral
  local entry = storage.loaded[id]
  if not entry or not entry.unit.valid then
    return
  end
  local unit = entry.unit
  if unit.surface.platform then
    return
  end
  if entry.feral then
    if not unit.commandable.has_command then
      FeralShell.hunt(entry, tick)
    end
    return
  end
  local natives = unit.surface.count_entities_filtered({
    position = unit.position,
    radius = f.search_radius,
    force = "enemy",
    limit = 1,
  })
  if natives > 0 then
    entry.idle_since = nil
    if not unit.commandable.has_command then
      unit.commandable.set_command({
        type = defines.command.attack_area,
        destination = unit.position,
        radius = f.search_radius,
      })
    end
  elseif entry.idle_since == nil then
    entry.idle_since = tick
  end
  local goes = Feral.decide(entry, tick, roll)
  entry.checked_at = tick
  if goes then
    FeralShell.go_feral(entry, tick)
  end
end

-- A feral monster's command ended. The event also comes for unit
-- groups, so the unit number must match the entry's unit. After a
-- distraction the original command resumes, so the handler ignores that
-- failure. Any other failure ends in a wander, so an unreachable target can't
-- start a loop of failed commands. A failed hunt also marks the monster.
function FeralShell.completed(event)
  local entry = storage.loaded[event.unit_number]
  if not entry or not entry.feral or not entry.unit.valid then
    return
  end
  if entry.unit.unit_number ~= event.unit_number then
    return
  end
  if event.result ~= defines.behavior_result.fail or event.was_distracted then
    return
  end
  if Feral.marks(true, event.was_distracted, entry.hunting) then
    entry.failed_at = event.tick
  end
  FeralShell.wander(entry)
end

return FeralShell
