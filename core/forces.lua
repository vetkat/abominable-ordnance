-- The rules for the tamed force and the other forces.
local Names = require("core.names")

local Forces = {}

-- The cease-fire between the tamed force and a force: true for peace,
-- false for war, or nil to leave the relation alone.
function Forces.cease_fire(name)
  if name == "enemy" then
    return false
  end
  if name == "neutral" or name == Names.TAMED then
    return nil
  end
  return true
end

-- The tamed force has no research, but its kills still feed the egg
-- supply (spec Q8).
function Forces.earns_loot(name, researched)
  return researched or name == Names.TAMED
end

return Forces
