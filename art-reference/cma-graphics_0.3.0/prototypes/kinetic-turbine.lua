-- Kinetic Turbine Mk1-3: 3x5 generators built on the vanilla steam turbine (same fluid box and pipe
-- connections, so they drop into existing turbine builds; the upgrade planner swaps tiers in place).
-- Art: "north" set = vertical_animation, "east" set = horizontal_animation (+ frozen patches).
-- Power from 500 C steam: fluid_usage_per_tick x 60 x 485 C x 0.2 kJ/C (vanilla: 1/tick = 5.8 MW).
local MG = require("__cma-graphics__/lib/machine_graphics")
local S = require("prototypes.showcase")
local sub = S.subgroup("power-turbines", "a2")

local TIERS = {
  {name = "mk1", usage = 1.72, volume = 200, health = 400},    -- ~10 MW, mid-game
  {name = "mk2", usage = 4.3, volume = 400, health = 600},     -- ~25 MW, late game
  {name = "mk3", usage = 10.3, volume = 800, health = 900},    -- ~60 MW, post-game
}

for i, t in ipairs(TIERS) do
  local V = MG("kinetic-turbine", {variant = t.name, direction = "north", animation_speed = 0.5})
  local H = MG("kinetic-turbine", {variant = t.name, direction = "east", animation_speed = 0.5})
  local name = "cma-kinetic-turbine-" .. t.name
  local e = table.deepcopy(data.raw.generator["steam-turbine"])
  e.name = name
  e.icon = V.icon
  e.icon_size = 64
  e.minable = {mining_time = 0.4, result = name}
  e.max_health = t.health
  e.fluid_usage_per_tick = t.usage
  e.fluid_box.volume = t.volume
  e.next_upgrade = i < #TIERS and ("cma-kinetic-turbine-" .. TIERS[i + 1].name) or nil
  e.vertical_animation = V.working
  e.horizontal_animation = H.working
  e.vertical_frozen_patch = V.frozen
  e.horizontal_frozen_patch = H.frozen
  e.smoke = nil                       -- vanilla smoke positions belong to the vanilla art
  e.drawing_box_vertical_extension = 0.8
  e.heating_energy = mods["space-age"] and "50kW" or nil
  data:extend({e})
  S.item(name, V.icon, sub, "b[kinetic-turbine]-" .. i)
end
