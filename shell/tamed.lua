-- Sets up the tamed force. This module is shell: it reads and writes the
-- game. control.lua calls it, and so do the in-game tests.
local Forces = require("core.forces")
local Names = require("core.names")

local Tamed = {}

local function befriend(tamed, force)
  tamed.set_cease_fire(force, true)
  force.set_cease_fire(tamed, true)
end

-- Creates the tamed force and the loaded table if they are missing, and
-- sets every force relation. A second call changes nothing.
function Tamed.ensure()
  local tamed = game.forces[Names.TAMED] or game.create_force(Names.TAMED)
  for _, force in pairs(game.forces) do
    if Forces.peaceful(force.name) then
      befriend(tamed, force)
    end
  end
  tamed.set_cease_fire("enemy", false)
  game.forces["enemy"].set_cease_fire(tamed, false)
  storage.loaded = storage.loaded or {}
end

function Tamed.on_force_created(force)
  local tamed = game.forces[Names.TAMED]
  if tamed and Forces.peaceful(force.name) then
    befriend(tamed, force)
  end
end

return Tamed
