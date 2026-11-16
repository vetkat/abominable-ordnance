-- The rules of the hazard pass: a new hazard, the hits that are due, and
-- the visits and hits of one tick within the budget. Pure: it reads only
-- its parameters. shell/damage.lua deals the hits.
local Trail = require("core.trail")

local Hazards = {}

-- A hazard of a payload at a position. Its first hit is due at tick,
-- and it ends ticks later. force is a force name.
function Hazards.new(surface, position, payload, force, tick, ticks, interval)
  return {
    surface = surface,
    position = { x = position.x, y = position.y },
    payload = payload,
    force = force,
    last_hit = tick - interval,
    end_tick = tick + ticks,
  }
end

-- The whole intervals since the hazard's last hit, up to its end tick.
function Hazards.due(hazard, tick, interval)
  local now = math.min(tick, hazard.end_tick)
  return math.max(math.floor((now - hazard.last_hit) / interval), 0)
end

-- One tick of the pass. It visits at most hazard_visits hazards from the
-- cursor on and deals at most hazard_hits hits. A visit with a due hit
-- sums the due intervals into one hit. Returns the hits, the hazards
-- that end, and the cursor for the next tick. When the hits run out,
-- the cursor is the first hazard that did not get its hit.
function Hazards.plan(hazards, cursor, tick, numbers)
  local interval = numbers.hazard_interval
  local ids, next_cursor = Trail.batch(hazards, cursor, numbers.hazard_visits)
  local out = { hits = {}, done = {}, cursor = next_cursor }
  for _, id in ipairs(ids) do
    local hazard = hazards[id]
    local count = Hazards.due(hazard, tick, interval)
    if count > 0 then
      if #out.hits == numbers.hazard_hits then
        out.cursor = id
        return out
      end
      out.hits[#out.hits + 1] = {
        id = id,
        count = count,
        last_hit = hazard.last_hit + count * interval,
      }
    end
    if tick >= hazard.end_tick then
      out.done[#out.done + 1] = id
    end
  end
  return out
end

-- The rest of a plan when only its first ran hits ran, because the
-- shell's target budget ran out. A hazard whose hit did not run stays,
-- and keeps its last hit. The cursor is the first of them, so the
-- hazards take turns. Returns the hazards that end and the cursor.
function Hazards.cut(plan, ran)
  local skipped = plan.hits[ran + 1]
  if not skipped then
    return { done = plan.done, cursor = plan.cursor }
  end
  local kept = {}
  for i = ran + 1, #plan.hits do
    kept[plan.hits[i].id] = true
  end
  local done = {}
  for _, id in ipairs(plan.done) do
    if not kept[id] then
      done[#done + 1] = id
    end
  end
  return { done = done, cursor = skipped.id }
end

return Hazards
