-- Diesel Generator: 4x4 burner-generator (burns chemical fuel, 3 MW).
local MG = require("__cma-graphics__/lib/machine_graphics")
local S = require("prototypes.showcase")
local G = MG("diesel-generator", {animation_speed = 0.75})

-- smoke leaves the two stack mouths (positions = screen-space tiles relative to entity centre)
local function stack_smoke(x, y)
  return {
    name = "smoke",
    north_position = {x, y}, east_position = {x, y}, south_position = {x, y}, west_position = {x, y},
    deviation = {0.08, 0.08},
    frequency = 6,
    starting_vertical_speed = 0.06,
    starting_frame_deviation = 60,
  }
end

data:extend({
  {
    type = "burner-generator",
    name = "cma-diesel-generator",
    icon = G.icon,
    icon_size = 64,
    flags = {"placeable-neutral", "player-creation"},
    minable = {mining_time = 0.5, result = "cma-diesel-generator"},
    max_health = 600,
    corpse = "big-remnants",
    dying_explosion = "big-explosion",
    collision_box = {{-1.8, -1.8}, {1.8, 1.8}},
    selection_box = {{-2, -2}, {2, 2}},
    max_power_output = "3MW",
    perceived_performance = {minimum = 0.3, performance_to_activity_rate = 1.5},
    animation = G.working,
    idle_animation = G.idle,
    burner = {
      type = "burner",
      fuel_categories = {"chemical"},
      effectivity = 0.85,
      fuel_inventory_size = 2,
      burnt_inventory_size = 0,
      emissions_per_minute = {pollution = 20},
      light_flicker = {color = {1, 0.6, 0.2}, minimum_intensity = 0.4, maximum_intensity = 0.7},
      smoke = {stack_smoke(1.55, -2.41), stack_smoke(1.05, -2.25)},
    },
    energy_source = {type = "electric", usage_priority = "secondary-output"},
    working_sound = table.deepcopy(data.raw.generator["steam-engine"].working_sound),
    impact_category = "metal-large",
    open_sound = {filename = "__base__/sound/machine-open.ogg", volume = 0.5},
    close_sound = {filename = "__base__/sound/machine-close.ogg", volume = 0.5},
  },
})
S.item("cma-diesel-generator", G.icon, S.subgroup("power", "a"), "a[diesel-generator]")
