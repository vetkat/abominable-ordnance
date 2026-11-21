-- Process Reactor Mk1-3: 3x3 crafting machines built on the vanilla chemical plant (same fluid
-- connections: inputs north, outputs south). Four-direction art; the liquid is a separate
-- greyscale tint layer coloured by the recipe (apply_recipe_tint = "primary"), and the white glow
-- takes the recipe's secondary colour.
local MG = require("__cma-graphics__/lib/machine_graphics")
local S = require("prototypes.showcase")
local sub = S.subgroup("production", "c")
local DIRS = {"north", "east", "south", "west"}

local TIERS = {
  {name = "mk1", speed = 1, slots = 3, energy = "210kW", health = 300},
  {name = "mk2", speed = 2, slots = 4, energy = "450kW", health = 450},
  {name = "mk3", speed = 4, slots = 5, energy = "1MW", health = 600},
}

for i, t in ipairs(TIERS) do
  local G = {}
  for _, d in pairs(DIRS) do
    G[d] = MG("process-reactor", {variant = t.name, direction = d, animation_speed = 0.5})
  end
  local function four(field, extra)
    local r = {}
    for _, d in pairs(DIRS) do r[d] = extra and extra(G[d]) or G[d][field] end
    return r
  end
  local name = "cma-process-reactor-" .. t.name
  local e = table.deepcopy(data.raw["assembling-machine"]["chemical-plant"])
  e.name = name
  e.icon = G.north.icon
  e.icon_size = 64
  e.minable = {mining_time = 0.3, result = name}
  e.max_health = t.health
  e.crafting_speed = t.speed
  e.module_slots = t.slots
  e.energy_usage = t.energy
  e.fast_replaceable_group = "cma-process-reactor"
  e.next_upgrade = i < #TIERS and ("cma-process-reactor-" .. TIERS[i + 1].name) or nil
  e.drawing_box_vertical_extension = 1.0
  e.heating_energy = mods["space-age"] and "100kW" or nil
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
  data:extend({e})
  S.item(name, G.north.icon, sub, "c[process-reactor]-" .. i)
end
