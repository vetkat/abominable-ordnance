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

-- True if the handler starts a new wander after a failed command. A
-- hunt that failed, or a wander that failed with no recent failure, does.
-- A wander that failed again inside the mark window waits for the next
-- batch check, so a stuck monster can't fail-wander every few ticks.
function Feral.wanders_after_failure(entry, tick)
  return entry.hunting == true or not Feral.marked(entry, tick)
end

-- True if the too-close scan counts a player: one with a character, on a
-- force at peace with the tamed force, off a space platform.
function Feral.player_counts(has_character, at_peace, on_platform)
  return has_character == true and at_peace == true and not on_platform
end

-- Game ticks in one minute. Balance.feral.unstable_per_minute is a
-- chance for each of these.
Feral.TICKS_PER_MINUTE = 60 * 60

-- The chance that a monster goes feral by the unstable rule over
-- elapsed ticks. It grows with each payload and never passes 1. A
-- monster with no payloads has chance 0.
function Feral.unstable_chance(payload_count, elapsed)
  if elapsed <= 0 then
    return 0
  end
  local p = math.min(1, Balance.feral.unstable_per_minute * payload_count)
  return 1 - (1 - p) ^ (elapsed / Feral.TICKS_PER_MINUTE)
end

-- The idle clock after a check: it stops when a native is near, and
-- otherwise keeps its start, or starts now.
function Feral.idle_since(previous, native_near, tick)
  if native_near then
    return nil
  end
  return previous or tick
end

-- True if a tamed monster goes feral at this check. It does when it has
-- idled for idle_ticks or more. Otherwise the unstable roll for the time
-- since its last check decides. random is a function from the shell that
-- gives a number in [0, 1). It runs only when the roll decides. A
-- monster with no checked_at has no elapsed time, so it does not roll.
function Feral.decide(entry, tick, random)
  if entry.feral then
    return false
  end
  if entry.idle_since ~= nil and tick - entry.idle_since >= Balance.feral.idle_ticks then
    return true
  end
  if entry.checked_at == nil then
    return false
  end
  local chance = Feral.unstable_chance(#(entry.payloads or {}), tick - entry.checked_at)
  return chance > 0 and random() < chance
end

return Feral
