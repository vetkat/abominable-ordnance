-- Which forces the tamed force keeps peace with.
local Names = require("core.names")

local Forces = {}

local HOSTILE = { enemy = true, neutral = true, [Names.TAMED] = true }

-- True for a force that gets cease-fire with the tamed force both ways.
function Forces.peaceful(name)
  return not HOSTILE[name]
end

return Forces
