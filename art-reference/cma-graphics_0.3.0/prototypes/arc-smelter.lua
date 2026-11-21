-- Arc Smelter Mk1-3: 3x3 furnaces built on the vanilla electric furnace. Mk1 burns fuel (smoke
-- from its chimney), Mk2/Mk3 are electric. The molten metal glows orange in the emission layer.
local MG = require("__cma-graphics__/lib/machine_graphics")
local S = require("prototypes.showcase")
local sub = S.subgroup("smelting", "c0")

local TIERS = {
  {name = "mk1", speed = 2, slots = 0, energy = "180kW", health = 300, burner = true},
  {name = "mk2", speed = 3, slots = 2, energy = "360kW", health = 400},
  {name = "mk3", speed = 6, slots = 4, energy = "900kW", health = 500},
}

for i, t in ipairs(TIERS) do
  local G = MG("arc-smelter", {variant = t.name, animation_speed = 0.5})
  local name = "cma-arc-smelter-" .. t.name
  local e = table.deepcopy(data.raw.furnace["electric-furnace"])
  e.name = name
  e.icon = G.icon
  e.icon_size = 64
  e.icons = nil
  e.minable = {mining_time = 0.3, result = name}
  e.max_health = t.health
  e.crafting_speed = t.speed
  e.module_slots = t.slots
  e.energy_usage = t.energy
  e.fast_replaceable_group = "cma-arc-smelter"
  e.next_upgrade = i < #TIERS and ("cma-arc-smelter-" .. TIERS[i + 1].name) or nil
  e.drawing_box_vertical_extension = 1.5
  e.heating_energy = mods["space-age"] and "100kW" or nil
  if t.burner then
    e.energy_source = {
      type = "burner", fuel_categories = {"chemical"}, effectivity = 1, fuel_inventory_size = 1,
      emissions_per_minute = {pollution = 4},
      light_flicker = {color = {0, 0, 0}, minimum_intensity = 0.6, maximum_intensity = 0.95},
      -- chimney mouth: 3D (0.78, 0.98, 2.86) -> screen {x, -(y + z) * 0.7071 + ground offset 0.47}
      smoke = {{name = "smoke", deviation = {0.08, 0.08}, frequency = 6, position = {0.78, -2.23},
                starting_vertical_speed = 0.08, starting_frame_deviation = 60}},
    }
  end
  e.graphics_set = {
    animation = {layers = {G.base, G.shadow}},
    working_visualisations = {{fadeout = true, animation = G.emission}},
    frozen_patch = G.frozen,
    reset_animation_when_frozen = true,
  }
  data:extend({e})
  S.item(name, G.icon, sub, "c[arc-smelter]-" .. i)
end
