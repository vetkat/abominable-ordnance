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

-- A drop under the corpse is hard to see. This is the spot beside it.
function Loot.beside(position, half_width)
  return { x = position.x + half_width + Balance.loot_offset, y = position.y }
end

-- The floating text over a drop, as rich text.
function Loot.label(drop)
  return { "", "+" .. drop.count .. " [item=" .. drop.name .. "] ", { "item-name." .. drop.name } }
end

return Loot
