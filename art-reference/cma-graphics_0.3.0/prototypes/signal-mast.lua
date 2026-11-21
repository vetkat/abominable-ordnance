-- Signal Mast Mk1-3: 3x3 radars. A radar picture is a 64-direction RotatedSprite, so the 64-frame
-- sheets (one clockwise antenna revolution) are used as directions. The shadow is static; it is
-- tiled 64 times (signal-mast-<tier>-hr-shadow64.png) to match.
local MG = require("__cma-graphics__/lib/machine_graphics")
local S = require("prototypes.showcase")
local sub = S.subgroup("logistics", "f")

local TIERS = {
  {name = "mk1", scan = 7, near = 2, energy = "300kW", health = 250},
  {name = "mk2", scan = 10, near = 3, energy = "600kW", health = 350},
  {name = "mk3", scan = 14, near = 4, energy = "1.2MW", health = 450},
}

local function rotated(layer, extra)
  local s = table.deepcopy(layer)
  s.direction_count = s.frame_count
  s.frame_count, s.animation_speed, s.repeat_count = nil, nil, nil
  for k, v in pairs(extra or {}) do s[k] = v end
  return s
end

for i, t in ipairs(TIERS) do
  local G = MG("signal-mast", {variant = t.name})
  local shadow = rotated(G.shadow, {direction_count = 64, line_length = 8,
    filename = "__cma-graphics__/graphics/entity/signal-mast/signal-mast-" .. t.name .. "-hr-shadow64.png"})
  local name = "cma-signal-mast-" .. t.name
  local e = table.deepcopy(data.raw.radar.radar)
  e.name = name
  e.icon = G.icon
  e.icon_size = 64
  e.icons = nil
  e.minable = {mining_time = 0.2, result = name}
  e.max_health = t.health
  e.max_distance_of_sector_revealed = t.scan
  e.max_distance_of_nearby_sector_revealed = t.near
  e.energy_usage = t.energy
  e.fast_replaceable_group = "cma-signal-mast"
  e.next_upgrade = i < #TIERS and ("cma-signal-mast-" .. TIERS[i + 1].name) or nil
  e.pictures = {layers = {rotated(G.base), rotated(G.emission), shadow}}
  e.integration_patch = nil
  e.water_reflection = nil
  e.drawing_box_vertical_extension = 1.4
  data:extend({e})
  S.item(name, G.icon, sub, "g[signal-mast]-" .. i)
end
