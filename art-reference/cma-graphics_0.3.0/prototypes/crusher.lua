-- Crusher Mk1-3: 2x2 item crafters (assembling machine without fluid boxes, so not rotatable).
-- The feed in the hopper/heap is a greyscale tint layer coloured by the recipe.
local MG = require("__cma-graphics__/lib/machine_graphics")
local S = require("prototypes.showcase")
local sub = S.subgroup("crafting", "c1")

local TIERS = {
  {name = "mk1", speed = 0.5, slots = 0, energy = "75kW", health = 150},
  {name = "mk2", speed = 1, slots = 1, energy = "150kW", health = 250},
  {name = "mk3", speed = 2, slots = 2, energy = "400kW", health = 350},
}

for i, t in ipairs(TIERS) do
  local G = MG("crusher", {variant = t.name, animation_speed = 0.5})
  local name = "cma-crusher-" .. t.name
  local e = table.deepcopy(data.raw["assembling-machine"]["assembling-machine-1"])
  e.name = name
  e.icon = G.icon
  e.icon_size = 64
  e.icons = nil
  e.minable = {mining_time = 0.2, result = name}
  e.max_health = t.health
  e.collision_box = {{-0.8, -0.8}, {0.8, 0.8}}
  e.selection_box = {{-1, -1}, {1, 1}}
  e.crafting_speed = t.speed
  e.module_slots = t.slots
  e.allowed_effects = {"consumption", "speed", "productivity", "pollution", "quality"}
  e.energy_usage = t.energy
  e.fluid_boxes = nil
  e.fast_replaceable_group = "cma-crusher"
  e.next_upgrade = i < #TIERS and ("cma-crusher-" .. TIERS[i + 1].name) or nil
  e.corpse = "small-remnants"
  e.drawing_box_vertical_extension = 0.6
  e.heating_energy = mods["space-age"] and "50kW" or nil
  e.circuit_connector = nil
  e.graphics_set = {
    animation = {layers = {G.base, G.shadow}},
    working_visualisations = {
      {apply_recipe_tint = "primary", animation = G.tint},
      {fadeout = true, apply_recipe_tint = "secondary", animation = G.emission},
    },
    frozen_patch = G.frozen,
    reset_animation_when_frozen = true,
  }
  e.water_reflection = nil
  data:extend({e})
  S.item(name, G.icon, sub, "c[crusher]-" .. i)
end
