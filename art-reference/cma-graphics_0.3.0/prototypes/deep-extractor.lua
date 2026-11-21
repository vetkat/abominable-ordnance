-- Deep Extractor Mk1-3: 3x3 mining drills built on the vanilla electric mining drill (same drop
-- position and fluid inputs). Four-direction art; the ore in the auger trough and the spoil heap is
-- a greyscale tint layer coloured by the resource being mined (apply_tint = "resource-color").
local MG = require("__cma-graphics__/lib/machine_graphics")
local S = require("prototypes.showcase")
local sub = S.subgroup("mining", "a5")
local DIRS = {"north", "east", "south", "west"}

local TIERS = {
  {name = "mk1", speed = 0.5, radius = 2.49, slots = 2, energy = "120kW", health = 300},
  {name = "mk2", speed = 1, radius = 3.49, slots = 3, energy = "300kW", health = 400},
  {name = "mk3", speed = 2.5, radius = 4.49, slots = 4, energy = "800kW", health = 500},
}

for i, t in ipairs(TIERS) do
  local G = {}
  for _, d in pairs(DIRS) do
    G[d] = MG("deep-extractor", {variant = t.name, direction = d, animation_speed = 0.5})
  end
  local function four(field, extra)
    local r = {}
    for _, d in pairs(DIRS) do r[d] = extra and extra(G[d]) or G[d][field] end
    return r
  end
  local name = "cma-deep-extractor-" .. t.name
  local e = table.deepcopy(data.raw["mining-drill"]["electric-mining-drill"])
  e.name = name
  e.icon = G.north.icon
  e.icon_size = 64
  e.icons = nil
  e.minable = {mining_time = 0.3, result = name}
  e.max_health = t.health
  e.mining_speed = t.speed
  e.resource_searching_radius = t.radius
  e.module_slots = t.slots
  e.energy_usage = t.energy
  e.fast_replaceable_group = "cma-deep-extractor"
  e.next_upgrade = i < #TIERS and ("cma-deep-extractor-" .. TIERS[i + 1].name) or nil
  e.drawing_box_vertical_extension = 1.5
  e.heating_energy = mods["space-age"] and "100kW" or nil
  e.graphics_set = {
    animation = four(nil, function(g) return {layers = {g.base, g.shadow}} end),
    working_visualisations = {
      {apply_tint = "resource-color",
       north_animation = G.north.tint, east_animation = G.east.tint,
       south_animation = G.south.tint, west_animation = G.west.tint},
      {fadeout = true,
       north_animation = G.north.emission, east_animation = G.east.emission,
       south_animation = G.south.emission, west_animation = G.west.emission},
    },
    frozen_patch = four("frozen"),
    reset_animation_when_frozen = true,
  }
  e.wet_mining_graphics_set = table.deepcopy(e.graphics_set)
  data:extend({e})
  S.item(name, G.north.icon, sub, "a[deep-extractor]-" .. i)
end
