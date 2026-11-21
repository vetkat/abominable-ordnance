-- Inline Processor Mk1-3: 3x5 directional item crafters (intake at the north end, output at the
-- south end, fluid flanges at both ends). Non-square, so it rotates before placement. The parts on
-- the line are a greyscale tint layer coloured by the recipe.
local MG = require("__cma-graphics__/lib/machine_graphics")
local S = require("prototypes.showcase")
local sub = S.subgroup("crafting", "c1")
local DIRS = {"north", "east", "south", "west"}

local TIERS = {
  {name = "mk1", speed = 1, slots = 2, energy = "250kW", health = 400},
  {name = "mk2", speed = 2, slots = 4, energy = "600kW", health = 550},
  {name = "mk3", speed = 4, slots = 6, energy = "1.5MW", health = 700},
}

for i, t in ipairs(TIERS) do
  local G = {}
  for _, d in pairs(DIRS) do
    G[d] = MG("inline-processor", {variant = t.name, direction = d, animation_speed = 0.5})
  end
  local function four(field, extra)
    local r = {}
    for _, d in pairs(DIRS) do r[d] = extra and extra(G[d]) or G[d][field] end
    return r
  end
  local name = "cma-inline-processor-" .. t.name
  local e = table.deepcopy(data.raw["assembling-machine"]["assembling-machine-2"])
  e.name = name
  e.icon = G.north.icon
  e.icon_size = 64
  e.icons = nil
  e.minable = {mining_time = 0.3, result = name}
  e.max_health = t.health
  e.collision_box = {{-1.3, -2.3}, {1.3, 2.3}}
  e.selection_box = {{-1.5, -2.5}, {1.5, 2.5}}
  e.crafting_speed = t.speed
  e.module_slots = t.slots
  e.allowed_effects = {"consumption", "speed", "productivity", "pollution", "quality"}
  e.energy_usage = t.energy
  e.fluid_boxes[1].pipe_connections[1].position = {0, -2}
  e.fluid_boxes[2].pipe_connections[1].position = {0, 2}
  e.fast_replaceable_group = "cma-inline-processor"
  e.next_upgrade = i < #TIERS and ("cma-inline-processor-" .. TIERS[i + 1].name) or nil
  e.corpse = "big-remnants"
  e.circuit_connector = nil
  e.drawing_box_vertical_extension = 1.0
  e.heating_energy = mods["space-age"] and "150kW" or nil
  e.graphics_set = {
    animation = four(nil, function(g) return {layers = {g.base, g.shadow}} end),
    working_visualisations = {
      {apply_recipe_tint = "primary",
       north_animation = G.north.tint, east_animation = G.east.tint,
       south_animation = G.south.tint, west_animation = G.west.tint},
      {fadeout = true, apply_recipe_tint = "secondary",
       north_animation = G.north.emission, east_animation = G.east.emission,
       south_animation = G.south.emission, west_animation = G.west.emission},
    },
    frozen_patch = four("frozen"),
    reset_animation_when_frozen = true,
  }
  e.water_reflection = nil
  data:extend({e})
  S.item(name, G.north.icon, sub, "d[inline-processor]-" .. i)
end
