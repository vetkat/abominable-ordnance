-- Decides what a dead native spawner drops.
local Balance = require("core.balance")
local Species = require("core.species")

local Loot = {}

function Loot.drop(spawner_name, researched, r)
  local species = researched and Species.by_spawner(spawner_name)
  if not species then
    return nil
  end
  local span = Balance.loot_max - Balance.loot_min + 1
  return { name = species.egg, count = Balance.loot_min + math.floor(r * span) }
end

return Loot
