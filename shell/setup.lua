-- Sets up storage and the tamed force, for a new game and for a save
-- that gains or updates the mod. This module is shell, so the in-game
-- tests can call it.
local LauncherShell = require("shell.launcher")
local Tamed = require("shell.tamed")

local Setup = {}

function Setup.on_init()
  storage.loaded = storage.loaded or {}
  storage.trails = storage.trails or {}
  Tamed.ensure()
end

-- A save from slice 2 has acid monsters in storage.loaded but no trail
-- list. The rebuild adds them, and a second run changes nothing.
local function rebuild_trails()
  for id, entry in pairs(storage.loaded) do
    if entry.trail then
      storage.trails[id] = true
    end
  end
end

-- A new mod version can add unlocks to a research that a force has
-- already finished. The reset applies them. The sync then puts every
-- placed launcher at its force's range level.
function Setup.on_configuration_changed()
  Setup.on_init()
  rebuild_trails()
  for _, force in pairs(game.forces) do
    force.reset_technology_effects()
    LauncherShell.sync(force)
  end
end

return Setup
