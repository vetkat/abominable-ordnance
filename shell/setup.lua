-- Sets up storage and the tamed force, for a new game and for a save
-- that gains or updates the mod. This module is shell, so the in-game
-- tests can call it.
local Tamed = require("shell.tamed")

local Setup = {}

function Setup.on_init()
  storage.loaded = storage.loaded or {}
  Tamed.ensure()
end

-- A new mod version can add unlocks to a research that a force has
-- already finished. The reset applies them.
function Setup.on_configuration_changed()
  Setup.on_init()
  for _, force in pairs(game.forces) do
    force.reset_technology_effects()
  end
end

return Setup
