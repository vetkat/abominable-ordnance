-- Picks the unit that hatches from a spoiled egg, by the vanilla spawner
-- rule. A weight is linear between two points. Before the first point it
-- is the first value, and after the last point the last value. The chance
-- of a unit is its weight over the sum of weights.
local Hatching = {}

function Hatching.weight(points, evolution)
  if evolution <= points[1][1] then
    return points[1][2]
  end
  for i = 2, #points do
    local a, b = points[i - 1], points[i]
    if evolution <= b[1] then
      return a[2] + (b[2] - a[2]) * (evolution - a[1]) / (b[1] - a[1])
    end
  end
  return points[#points][2]
end

function Hatching.pick(units, evolution, r)
  local weights, total = {}, 0
  for i, unit in ipairs(units) do
    weights[i] = Hatching.weight(unit[2], evolution)
    total = total + weights[i]
  end
  -- Below a species' first spawn point every weight is 0.
  if total <= 0 then
    return units[1][1]
  end
  local target, sum = r * total, 0
  for i, unit in ipairs(units) do
    sum = sum + weights[i]
    if target < sum then
      return unit[1]
    end
  end
  return units[#units][1]
end

return Hatching
