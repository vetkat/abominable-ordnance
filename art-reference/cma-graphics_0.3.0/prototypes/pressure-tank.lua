-- Pressure Tank Mk1-3: 3x3 storage tanks built on the vanilla storage tank (same pipe connections,
-- two_direction_only). Static art: the base + glow + shadow are one Sprite4Way. The fluid level is
-- drawn by the game into window_bounding_box, which sits on the tank's sight glass in both
-- orientations.
local MG = require("__cma-graphics__/lib/machine_graphics")
local S = require("prototypes.showcase")
local sub = S.subgroup("fluids", "d")

local TIERS = {
  {name = "mk1", volume = 25000, health = 500},
  {name = "mk2", volume = 50000, health = 750},
  {name = "mk3", volume = 100000, health = 1000},
}

-- Animation layers -> Sprite layers (a storage tank picture is a Sprite4Way)
local function sprite(layer)
  local s = table.deepcopy(layer)
  s.frame_count, s.line_length, s.animation_speed, s.repeat_count = nil, nil, nil, nil
  return s
end

for i, t in ipairs(TIERS) do
  local Gn = MG("pressure-tank", {variant = t.name, direction = "north"})
  local Ge = MG("pressure-tank", {variant = t.name, direction = "east"})
  local function pic(g) return {layers = {sprite(g.base), sprite(g.emission), sprite(g.shadow)}} end
  local name = "cma-pressure-tank-" .. t.name
  local e = table.deepcopy(data.raw["storage-tank"]["storage-tank"])
  e.name = name
  e.icon = Gn.icon
  e.icon_size = 64
  e.icons = nil
  e.minable = {mining_time = 0.3, result = name}
  e.max_health = t.health
  e.fluid_box.volume = t.volume
  e.fast_replaceable_group = "cma-pressure-tank"
  e.next_upgrade = i < #TIERS and ("cma-pressure-tank-" .. TIERS[i + 1].name) or nil
  e.drawing_box_vertical_extension = 1.2
  -- sight glass: 3D x +-0.11, front y -1.2, z 0.3..0.95 -> screen y = -(y + z) * 0.7071 + ground offset
  e.window_bounding_box = {{-0.109375, 0.609375}, {0.109375, 1.09375}}
  e.pictures.picture = {north = pic(Gn), east = pic(Ge), south = pic(Gn), west = pic(Ge)}
  e.pictures.window_background = {filename = "__cma-graphics__/graphics/entity/pressure-tank/pressure-tank-window-background.png",
                                  width = 16, height = 34, scale = 0.5}
  e.water_reflection = nil
  data:extend({e})
  S.item(name, Gn.icon, sub, "d[pressure-tank]-" .. i)
end
