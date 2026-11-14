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

-- True if the landing blast hurts an entity of the target force. The
-- attacker is the launcher's force name. It is nil when the rocket
-- outlived the launcher, and then only the natives count. is_enemy is
-- true when the attacker's force is at war with the target. The tamed force is
-- never hit, so a landing can't hurt the loaded monsters near it.
-- Neutral things such as trees and rocks are never hit either, and no
-- force hits itself.
function Forces.blast_hits(target, attacker, is_enemy)
  if target == Names.TAMED or target == "neutral" then
    return false
  end
  if attacker == nil then
    return target == "enemy"
  end
  return target ~= attacker and is_enemy
end

return Forces
