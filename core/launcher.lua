-- The levels of the larva launcher: names, guns and ranges. Pure data
-- and lookups.
local Balance = require("core.balance")
local Names = require("core.names")

local Launcher = {}

local MAX = Balance.launcher.max_level

local function known(level)
  return type(level) == "number" and level >= 1 and level <= MAX and level % 1 == 0
end

-- The turret of a level. Level 0, and any level the mod does not know,
-- is the launcher's own name.
function Launcher.name(level)
  if known(level) then
    return Names.LAUNCHER .. "-" .. level
  end
  return Names.LAUNCHER
end

Launcher.NAMES = { Names.LAUNCHER }
local LEVEL_OF = { [Names.LAUNCHER] = 0 }
for level = 1, MAX do
  Launcher.NAMES[#Launcher.NAMES + 1] = Launcher.name(level)
  LEVEL_OF[Launcher.name(level)] = level
end

-- The level of a turret name, or nil for any other entity.
function Launcher.level_of(name)
  return LEVEL_OF[name]
end

-- The automatic range of a level, in tiles.
function Launcher.range(level)
  local n = known(level) and level or 0
  return Balance.launcher.range + n * Balance.launcher.range_step
end

-- The hidden gun of a level.
function Launcher.gun(level)
  return Names.GUN .. (known(level) and level or 0)
end

return Launcher
