-- The rules for the tamed force and the other forces.
local Names = require("core.names")

local Forces = {}

-- The cease-fire between the tamed force and a force: true for peace,
-- false for war, or nil to leave the relation alone.
function Forces.cease_fire(name)
  if name == "enemy" then
    return false
  end
  if name == "neutral" or name == Names.TAMED or name == Names.FERAL then
    return nil
  end
  return true
end

-- The cease-fire between the feral force and a force: false for war, or
-- nil to leave the relation alone. The feral force is at war with every
-- force except neutral and itself. This rule alone owns the pair of the
-- tamed and the feral force.
function Forces.feral_cease_fire(name)
  if name == "neutral" or name == Names.FERAL then
    return nil
  end
  return false
end

-- The tamed force has no research, but its kills still feed the egg
-- supply (spec Q8). The feral force never earns loot, even if a
-- script researches the technology for it.
function Forces.earns_loot(name, researched)
  return name ~= Names.FERAL and (researched or name == Names.TAMED)
end

-- The game allows 64 forces in all.
local FORCE_LIMIT = 64

-- True when one more force fits.
function Forces.can_create(count)
  return count < FORCE_LIMIT
end

-- True if the landing blast hurts an entity of the target force.
-- attacker is the launcher's force name, or nil when the launcher no
-- longer exists. Then only the natives count. is_enemy is true when the
-- attacker's force is at war with the target. The blast never hits the
-- tamed force, so it can't hurt the loaded monsters near the spot. It
-- never hits neutral things such as trees and rocks, and no force hits
-- itself.
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
