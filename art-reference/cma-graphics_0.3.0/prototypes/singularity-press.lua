-- Singularity Press Mk1-3: 5x5 exotic item crafters (no fluid boxes, so not rotatable).
-- The accretion disc is the recipe-tint layer; the glow (emission layer) takes the secondary tint.
local MG = require("__cma-graphics__/lib/machine_graphics")
local S = require("prototypes.showcase")
local sub = S.subgroup("exotic", "g")

local TIERS = {
  {name = "mk1", speed = 2, slots = 4, energy = "5MW", health = 800},
  {name = "mk2", speed = 4, slots = 5, energy = "12MW", health = 1200},
  {name = "mk3", speed = 8, slots = 6, energy = "30MW", health = 1600},
}

for i, t in ipairs(TIERS) do
  local G = MG("singularity-press", {variant = t.name, animation_speed = 0.5})
  local name = "cma-singularity-press-" .. t.name
  local e = table.deepcopy(data.raw["assembling-machine"]["assembling-machine-1"])
  e.name = name
  e.icon = G.icon
  e.icon_size = 64
  e.icons = nil
  e.minable = {mining_time = 0.2, result = name}
  e.max_health = t.health
  e.collision_box = {{-2.3, -2.3}, {2.3, 2.3}}
  e.selection_box = {{-2.5, -2.5}, {2.5, 2.5}}
  e.crafting_speed = t.speed
  e.module_slots = t.slots
  e.allowed_effects = {"consumption", "speed", "productivity", "pollution", "quality"}
  e.energy_usage = t.energy
  e.fluid_boxes = nil
  e.fast_replaceable_group = "cma-singularity-press"
  e.next_upgrade = i < #TIERS and ("cma-singularity-press-" .. TIERS[i + 1].name) or nil
  e.corpse = "big-remnants"
  e.drawing_box_vertical_extension = 1
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
  S.item(name, G.icon, sub, "s[singularity-press]-" .. i)
end
