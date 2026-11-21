-- Rift Tap Mk1-3: 4x4 exotic mining drills built on the vanilla electric mining drill (drop
-- moved to the 4x4 edge, no fluid input). Four-direction art; the rift rim, swirl and flying chunks are
-- a tint layer coloured by the resource (apply_tint = "resource-color"), and so is the glow.
local MG = require("__cma-graphics__/lib/machine_graphics")
local S = require("prototypes.showcase")
local sub = S.subgroup("exotic", "g")
local DIRS = {"north", "east", "south", "west"}

local TIERS = {
  {name = "mk1", speed = 2, radius = 2.99, slots = 3, energy = "1MW", health = 500},
  {name = "mk2", speed = 4, radius = 4.99, slots = 4, energy = "2.5MW", health = 700},
  {name = "mk3", speed = 8, radius = 6.99, slots = 5, energy = "6MW", health = 900},
}

for i, t in ipairs(TIERS) do
  local G = {}
  for _, d in pairs(DIRS) do
    G[d] = MG("rift-tap", {variant = t.name, direction = d, animation_speed = 0.5})
  end
  local function four(field, extra)
    local r = {}
    for _, d in pairs(DIRS) do r[d] = extra and extra(G[d]) or G[d][field] end
    return r
  end
  local name = "cma-rift-tap-" .. t.name
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
  e.fast_replaceable_group = "cma-rift-tap"
  e.next_upgrade = i < #TIERS and ("cma-rift-tap-" .. TIERS[i + 1].name) or nil
  e.collision_box = {{-1.8, -1.8}, {1.8, 1.8}}
  e.selection_box = {{-2, -2}, {2, 2}}
  e.vector_to_place_result = {0, -2.35}
  e.input_fluid_box = nil
  e.circuit_connector = nil
  e.drawing_box_vertical_extension = 1.2
  e.heating_energy = mods["space-age"] and "100kW" or nil
  e.graphics_set = {
    animation = four(nil, function(g) return {layers = {g.base, g.shadow}} end),
    working_visualisations = {
      {apply_tint = "resource-color",
       north_animation = G.north.tint, east_animation = G.east.tint,
       south_animation = G.south.tint, west_animation = G.west.tint},
      {fadeout = true, apply_tint = "resource-color",
       north_animation = G.north.emission, east_animation = G.east.emission,
       south_animation = G.south.emission, west_animation = G.west.emission},
    },
    frozen_patch = four("frozen"),
    reset_animation_when_frozen = true,
  }
  e.wet_mining_graphics_set = table.deepcopy(e.graphics_set)
  data:extend({e})
  S.item(name, G.north.icon, sub, "r[rift-tap]-" .. i)
end
