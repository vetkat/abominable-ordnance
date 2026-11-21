-- Industrial Press Mk1-3: 3x3 item crafters built on the vanilla assembling machine 2 (its
-- optional fluid boxes stay, so the machine is rotatable). Four-direction art; the workpiece on the
-- bed is a greyscale tint layer coloured by the recipe (apply_recipe_tint = "primary", white for
-- recipes without a crafting_machine_tint), and the white glow takes the secondary colour.
local MG = require("__cma-graphics__/lib/machine_graphics")
local S = require("prototypes.showcase")
local sub = S.subgroup("crafting", "c1")
local DIRS = {"north", "east", "south", "west"}

local TIERS = {
  {name = "mk1", speed = 0.75, slots = 2, energy = "150kW", health = 300},
  {name = "mk2", speed = 1.5, slots = 3, energy = "375kW", health = 400},
  {name = "mk3", speed = 3, slots = 4, energy = "900kW", health = 500},
}

for i, t in ipairs(TIERS) do
  local G = {}
  for _, d in pairs(DIRS) do
    G[d] = MG("industrial-press", {variant = t.name, direction = d, animation_speed = 0.5})
  end
  local function four(field, extra)
    local r = {}
    for _, d in pairs(DIRS) do r[d] = extra and extra(G[d]) or G[d][field] end
    return r
  end
  local name = "cma-industrial-press-" .. t.name
  local e = table.deepcopy(data.raw["assembling-machine"]["assembling-machine-2"])
  e.name = name
  e.icon = G.north.icon
  e.icon_size = 64
  e.icons = nil
  e.minable = {mining_time = 0.3, result = name}
  e.max_health = t.health
  e.crafting_speed = t.speed
  e.module_slots = t.slots
  e.allowed_effects = {"consumption", "speed", "productivity", "pollution", "quality"}
  e.energy_usage = t.energy
  e.fast_replaceable_group = "cma-industrial-press"
  e.next_upgrade = i < #TIERS and ("cma-industrial-press-" .. TIERS[i + 1].name) or nil
  e.corpse = "assembling-machine-2-remnants"
  e.drawing_box_vertical_extension = 1.2
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
  S.item(name, G.north.icon, sub, "b[industrial-press]-" .. i)
end
