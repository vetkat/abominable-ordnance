-- Steam Boiler Mk1-3: 3x2 boilers built on the vanilla boiler (same water/steam connections),
-- four-direction art. structure = base + shadow, fire_glow = the glow sheet. Mk1/Mk2 burn fuel
-- (smoke from their stacks, per direction); Mk3 is electric and makes 500 degree steam. Pairs with the Kinetic Turbine.
local MG = require("__cma-graphics__/lib/machine_graphics")
local S = require("prototypes.showcase")
local sub = S.subgroup("power-turbines", "a2")
local DIRS = {"north", "east", "south", "west"}

-- stack mouths: 3D point turned per direction -> {x, -(y + z) * 0.7071 + ground offset}
local TIERS = {
  {name = "mk1", temp = 165, power = "3.6MW", health = 250,
   smoke = {north = {-1.0, -1.58}, east = {0.25, -1.97}, south = {1.0, -1.23}, west = {-0.25, -0.56}}},
  {name = "mk2", temp = 315, power = "9MW", health = 350,
   smoke = {north = {-0.95, -1.5}, east = {0.4, -1.74}, south = {0.95, -0.93}, west = {-0.4, -0.4}}},
  {name = "mk3", temp = 500, power = "20MW", health = 450, electric = true},
}

for i, t in ipairs(TIERS) do
  local G = {}
  for _, d in pairs(DIRS) do
    G[d] = MG("steam-boiler", {variant = t.name, direction = d, animation_speed = 0.5})
  end
  local pics = {}
  for _, d in pairs(DIRS) do
    pics[d] = {structure = {layers = {G[d].base, G[d].shadow}}, fire_glow = G[d].emission}
  end
  local name = "cma-steam-boiler-" .. t.name
  local e = table.deepcopy(data.raw.boiler.boiler)
  e.name = name
  e.icon = G.north.icon
  e.icon_size = 64
  e.icons = nil
  e.minable = {mining_time = 0.3, result = name}
  e.max_health = t.health
  e.energy_consumption = t.power
  e.target_temperature = t.temp
  e.output_fluid_box.maximum_temperature = nil
  e.pictures = pics
  e.fire_glow_flicker_enabled = true
  e.fast_replaceable_group = "cma-steam-boiler"
  e.next_upgrade = i < #TIERS and ("cma-steam-boiler-" .. TIERS[i + 1].name) or nil
  if t.electric then
    e.energy_source = {type = "electric", usage_priority = "secondary-input", emissions_per_minute = {pollution = 0}}
  else
    e.energy_source.smoke = {{name = "smoke", deviation = {0.1, 0.1}, frequency = 6,
      north_position = t.smoke.north, east_position = t.smoke.east, south_position = t.smoke.south,
      west_position = t.smoke.west, starting_vertical_speed = 0.08, starting_frame_deviation = 60}}
  end
  e.water_reflection = nil
  e.drawing_box_vertical_extension = 1.2
  data:extend({e})
  S.item(name, G.north.icon, sub, "b[steam-boiler]-" .. i)
end
