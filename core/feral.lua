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
local LARGEST_RADIUS = Balance.feral.radius
  + Balance.feral.per_payload * (Balance.feral.max_payloads - 1)
  + Balance.feral.per_size * MAX_STEP

function Feral.largest_radius()
  return LARGEST_RADIUS
end

-- The straight-line distance between two positions, each a table with
-- x and y.
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
  return distance <= Feral.radius(name, #(entry.payloads or {}))
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
  return failed == true and not was_distracted and hunting == true
end

-- True if the too-close scan counts a player: one with a character, on a
-- force at peace with the tamed force, off a space platform.
function Feral.player_counts(has_character, at_peace, on_platform)
  return has_character == true and at_peace == true and not on_platform
end

-- The chance that a monster goes feral by the unstable rule over
-- elapsed ticks. It grows with each payload.
function Feral.unstable_chance(payload_count, elapsed)
  if elapsed <= 0 or payload_count <= 0 then
    return 0
  end
  local p = Balance.feral.unstable_per_minute * payload_count
  return 1 - (1 - p) ^ (elapsed / 3600)
end

-- True if a tamed monster goes feral at this check. It does when it has
-- idled for idle_ticks or more. Otherwise the unstable roll for the time
-- since its last check decides. The roll is a random number in [0, 1)
-- from the shell. A monster with no
-- checked_at has no elapsed time, so it does not roll.
function Feral.decide(entry, tick, roll)
  if entry.feral then
    return false
  end
  if entry.idle_since ~= nil and tick - entry.idle_since >= Balance.feral.idle_ticks then
    return true
  end
  local elapsed = entry.checked_at and tick - entry.checked_at or 0
  return roll < Feral.unstable_chance(#(entry.payloads or {}), elapsed)
end

return Feral
