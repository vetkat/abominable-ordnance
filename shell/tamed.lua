-- Sets up the tamed and feral forces. This module is shell: it reads and writes the
-- game. control.lua calls it, and so do the in-game tests.
local Forces = require("core.forces")
local Names = require("core.names")

local Tamed = {}

-- The game allows 64 forces in all.
local FORCE_LIMIT = 64

-- True when one more force fits.
function Tamed.can_create(count)
  return count < FORCE_LIMIT
end

-- Counts the forces. The game's force table has no length operator that
-- works, so this walks it.
local function count_forces()
  local count = 0
  for _ in pairs(game.forces) do
    count = count + 1
  end
  return count
end

-- Sets one relation both ways, when the rule gives one.
local function set(a, b, rule)
  if a and rule ~= nil then
    a.set_cease_fire(b, rule)
    b.set_cease_fire(a, rule)
  end
end

-- Relates one force to the tamed and the feral force, by the rules in
-- core/forces.lua.
function Tamed.relate(force)
  set(game.forces[Names.TAMED], force, Forces.cease_fire(force.name))
  set(game.forces[Names.FERAL], force, Forces.feral_cease_fire(force.name))
end

-- Creates the tamed force and the feral force if they are missing, and
-- relates them to every force. A second call changes nothing. With a
-- full force limit the feral force is left out, and feral behaviour
-- stays off.
function Tamed.ensure()
  if not game.forces[Names.TAMED] then
    game.create_force(Names.TAMED)
  end
  if not game.forces[Names.FERAL] then
    if Tamed.can_create(count_forces()) then
      game.create_force(Names.FERAL)
    else
      log("Abominable Ordnance: the force limit is full, so loaded monsters never go feral")
    end
  end
  for _, force in pairs(game.forces) do
    Tamed.relate(force)
  end
end

return Tamed
