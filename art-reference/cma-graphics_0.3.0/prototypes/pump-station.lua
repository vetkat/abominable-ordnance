-- Pump Station Mk1-3: 1x2 pumps built on the vanilla pump (same connections: output north end,
-- input south end). Four-direction art with the impeller spinning on top; no separate fluid window.
local MG = require("__cma-graphics__/lib/machine_graphics")
local S = require("prototypes.showcase")
local sub = S.subgroup("fluids", "d")
local DIRS = {"north", "east", "south", "west"}

local TIERS = {
  {name = "mk1", speed = 20, energy = "30kW", health = 180},
  {name = "mk2", speed = 40, energy = "60kW", health = 250},
  {name = "mk3", speed = 80, energy = "120kW", health = 350},
}

for i, t in ipairs(TIERS) do
  local G = {}
  for _, d in pairs(DIRS) do
    G[d] = MG("pump-station", {variant = t.name, direction = d, animation_speed = 0.5})
  end
  local function four(field, extra)
    local r = {}
    for _, d in pairs(DIRS) do r[d] = extra and extra(G[d]) or G[d][field] end
    return r
  end
  local name = "cma-pump-station-" .. t.name
  local e = table.deepcopy(data.raw.pump.pump)
  e.name = name
  e.icon = G.north.icon
  e.icon_size = 64
  e.icons = nil
  e.minable = {mining_time = 0.2, result = name}
  e.max_health = t.health
  e.pumping_speed = t.speed
  e.energy_usage = t.energy
  e.fast_replaceable_group = "pipe"
  e.next_upgrade = i < #TIERS and ("cma-pump-station-" .. TIERS[i + 1].name) or nil
  e.animations = four(nil, function(g) return g.working end)
  e.glass_pictures = nil
  e.fluid_animation = nil
  e.frozen_patch = four("frozen")
  e.water_reflection = nil
  data:extend({e})
  S.item(name, G.north.icon, sub, "d[pump-station]-" .. i)
end
