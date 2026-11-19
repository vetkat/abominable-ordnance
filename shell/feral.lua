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
  entry.awaiting_check = nil
  entry.last_target = nil
  entry.unit.commandable.set_command({
    type = defines.command.wander,
    radius = f.search_radius,
    ticks_to_wait = f.rewander_ticks,
  })
end

-- A feral monster attacks the nearest enemy within seek_distance. A
-- marked monster wanders instead, and so does one with no target. After
-- a success, the same target as last time also gives a wander. This
-- stops a loop of attacks on a target that the monster can't harm.
function FeralShell.hunt(entry, tick, after_success)
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
  local last = entry.last_target
  if after_success and last and last.valid and last == target then
    FeralShell.wander(entry)
    return
  end
  entry.awaiting_check = nil
  entry.last_target = target
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
-- command, or one that awaits the check, hunts again. In Factorio 2.1
-- has_command stays true after a command ends, so FeralShell.completed
-- does the usual re-hunt and sets awaiting_check when it leaves the
-- restart to this check.
-- A tamed monster updates its idle clock and may go feral. random is a
-- function from control.lua that gives a number in [0, 1). The core
-- calls it only when the unstable roll needs it.
function FeralShell.check(id, tick, random)
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
    if entry.awaiting_check or not unit.commandable.has_command then
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
  entry.idle_since = Feral.idle_since(entry.idle_since, natives > 0, tick)
  if natives > 0 then
    local command = unit.commandable.command
    if not (command and command.type == defines.command.attack_area) then
      unit.commandable.set_command({
        type = defines.command.attack_area,
        destination = unit.position,
        radius = f.search_radius,
      })
    end
  end
  local goes = Feral.decide(entry, tick, random)
  entry.checked_at = tick
  if goes then
    FeralShell.go_feral(entry, tick)
  end
end

-- A feral monster's command ended. The event also comes for unit
-- groups, and a group number can equal a unit number, so the entry's
-- unit must carry the event's number. After a distraction the original
-- command resumes, so the handler ignores it.
--
-- A success sends the monster hunting again. Hunt wanders while a
-- failure mark holds, so this makes no loop. A failure sets the mark.
-- The monster wanders at once unless it already failed a wander in the
-- mark window. Then it waits for the batch check, so a stuck unit
-- can't fail-wander every few ticks.
---@param event EventData.on_ai_command_completed
function FeralShell.completed(event)
  local entry = storage.loaded[event.unit_number]
  if not entry or not entry.feral or not entry.unit.valid then
    return
  end
  if entry.unit.unit_number ~= event.unit_number or event.was_distracted then
    return
  end
  if event.result == defines.behavior_result.success then
    FeralShell.hunt(entry, event.tick, true)
    return
  end
  if event.result ~= defines.behavior_result.fail then
    return
  end
  local rewander = Feral.wanders_after_failure(entry, event.tick)
  entry.failed_at = event.tick
  if rewander then
    FeralShell.wander(entry)
  else
    entry.awaiting_check = true
  end
end

return FeralShell
