-- Sets up the tamed force. This module is shell: it reads and writes the
-- game. control.lua calls it, and so do the in-game tests.
local Forces = require("core.forces")
local Names = require("core.names")

local Tamed = {}

-- Sets the cease-fire between the tamed force and one force, both ways,
-- by the rule in core/forces.lua.
function Tamed.relate(force)
  local tamed = game.forces[Names.TAMED]
  local rule = Forces.cease_fire(force.name)
  if tamed and rule ~= nil then
    tamed.set_cease_fire(force, rule)
    force.set_cease_fire(tamed, rule)
  end
end

-- Creates the tamed force if it is missing and relates it to every
-- force. A second call changes nothing.
function Tamed.ensure()
  if not game.forces[Names.TAMED] then
    game.create_force(Names.TAMED)
  end
  for _, force in pairs(game.forces) do
    Tamed.relate(force)
  end
end

return Tamed
