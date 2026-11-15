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
  return entry.feral and Names.FERAL or Names.TAMED
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
  if not tamed or not tamed.get_cease_fire(player.force) then
    return
  end
  local surface = character.surface
  if surface.platform then
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

return FeralShell
