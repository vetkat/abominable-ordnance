-- The rules for loaded monsters that go feral. Pure: it reads only its
-- parameters and other core modules. The shell passes plain values,
-- never game objects or defines.
local Balance = require("core.balance")
local Species = require("core.species")

local Feral = {}

-- A unit's position in its species list, from small (0) to behemoth.
local STEP = {}
local MAX_STEP = 0
for _, species in ipairs(Species.ALL) do
  for i, unit in ipairs(species.units) do
    STEP[unit[1]] = i - 1
    MAX_STEP = math.max(MAX_STEP, i - 1)
  end
end

-- The size step of a unit. A unit from another mod gets 0.
function Feral.size_step(name)
  return STEP[name] or 0
end

-- The feral radius of a monster with this many payloads.
function Feral.radius(name, payload_count)
  local f = Balance.feral
  local extra = math.max((payload_count or 1) - 1, 0)
  return f.radius + f.per_payload * extra + f.per_size * Feral.size_step(name)
end

-- The largest feral radius in the mod. The too-close scan searches this
-- far around each player.
function Feral.largest_radius()
  local f = Balance.feral
  return f.radius + f.per_payload * (f.max_payloads - 1) + f.per_size * MAX_STEP
end

function Feral.distance(a, b)
  local dx, dy = a.x - b.x, a.y - b.y
  return math.sqrt(dx * dx + dy * dy)
end

-- True if a player at this distance makes the monster go feral. A
-- feral monster never goes feral again.
function Feral.too_close(entry, distance, name)
  if entry.feral then
    return false
  end
  return distance <= Feral.radius(name, #entry.payloads)
end

-- True while the monster's last failed hunt is recent. A marked monster
-- wanders instead of hunting.
function Feral.marked(entry, tick)
  local f = Balance.feral
  return entry.failed_at ~= nil and tick - entry.failed_at < f.retry_wanders * f.rewander_ticks
end

-- True if a completed command marks the monster: a failed hunt that a
-- distraction did not cause.
function Feral.marks(failed, was_distracted, hunting)
  return failed and not was_distracted and hunting == true
end

return Feral
