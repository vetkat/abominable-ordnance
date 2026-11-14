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
-- The range technology names, by level.
local RANGE_TECHS = {}
for level = 1, MAX do
  Launcher.NAMES[#Launcher.NAMES + 1] = Launcher.name(level)
  LEVEL_OF[Launcher.name(level)] = level
  RANGE_TECHS[level] = Names.RANGE_TECH .. level
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

-- The highest range research a force finished, or 0. researched(name)
-- says if the force finished a technology. The editor or a
-- command can finish a higher level alone, so this takes the highest
-- finished level, not a count.
function Launcher.level(researched)
  for level = MAX, 1, -1 do
    if researched(RANGE_TECHS[level]) then
      return level
    end
  end
  return 0
end

function Launcher.is_range_tech(name)
  for _, tech in ipairs(RANGE_TECHS) do
    if name == tech then
      return true
    end
  end
  return false
end

-- What a swap could not place, as a list of stacks to spill. The marker
-- "ammo" stands for the ammo left in the shell's script inventory.
-- lost_quality is the quality of a launcher that the swap lost, or nil.
function Launcher.leftovers(has_ammo, lost_quality)
  local stacks = {}
  if has_ammo then
    stacks[#stacks + 1] = "ammo"
  end
  if lost_quality then
    stacks[#stacks + 1] = { name = Names.LAUNCHER, count = 1, quality = lost_quality }
  end
  return stacks
end

-- The next step of a swap, after a step that worked (ok) or failed.
-- The shell runs the steps. This table makes sure that no failure loses
-- a launcher or its ammo.
local NEXT = {
  destroy = { [true] = "create", [false] = "give_back" },
  create = { [true] = "finish", [false] = "create_old" },
  create_old = { [true] = "finish", [false] = "spill" },
}

function Launcher.after(step, ok)
  local by_result = NEXT[step]
  return by_result and by_result[ok == true] or "stop"
end

return Launcher
