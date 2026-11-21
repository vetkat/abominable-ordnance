-- Coal Kiln Mk1-3: 2x2 burner furnaces for coal-age / early-game overhauls (an "Mk0" for the Arc
-- Smelter). Smoke comes out of each tier's chimney.
local MG = require("__cma-graphics__/lib/machine_graphics")
local S = require("prototypes.showcase")
local sub = S.subgroup("smelting", "c0")

-- smoke positions: chimney mouths, 3D (x, y, z) -> screen {x, -(y + z) * 0.7071 + ground offset 0.3}
local TIERS = {
  {name = "mk1", speed = 1, health = 200, smoke = {0, -1.09}},
  {name = "mk2", speed = 1.5, health = 250, smoke = {0.55, -1.72}},
  {name = "mk3", speed = 2.25, health = 300, smoke = {-0.45, -1.63}},
}

for i, t in ipairs(TIERS) do
  local G = MG("coal-kiln", {variant = t.name, animation_speed = 0.5})
  local name = "cma-coal-kiln-" .. t.name
  local e = table.deepcopy(data.raw.furnace["stone-furnace"])
  e.name = name
  e.icon = G.icon
  e.icon_size = 64
  e.icons = nil
  e.minable = {mining_time = 0.2, result = name}
  e.max_health = t.health
  e.crafting_speed = t.speed
  e.energy_usage = "90kW"
  e.energy_source.smoke = {{name = "smoke", deviation = {0.08, 0.08}, frequency = 6, position = t.smoke,
                            starting_vertical_speed = 0.08, starting_frame_deviation = 60}}
  e.fast_replaceable_group = "cma-coal-kiln"
  e.next_upgrade = i < #TIERS and ("cma-coal-kiln-" .. TIERS[i + 1].name) or nil
  e.drawing_box_vertical_extension = 1.0
  e.graphics_set = {
    animation = {layers = {G.base, G.shadow}},
    working_visualisations = {{fadeout = true, effect = "flicker", animation = G.emission}},
    frozen_patch = G.frozen,
    reset_animation_when_frozen = true,
  }
  e.water_reflection = nil
  data:extend({e})
  S.item(name, G.icon, sub, "b[coal-kiln]-" .. i)
end
