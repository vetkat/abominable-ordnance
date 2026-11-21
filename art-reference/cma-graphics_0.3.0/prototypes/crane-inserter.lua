-- Crane Inserter Mk1-3: inserters with a rendered platform (per direction) and top-down arm
-- sprites laid out like the vanilla fast inserter's (hand-base / hand-open / hand-closed at
-- scale 0.25, with shadows). Speeds roughly burner-fast / fast / bulk.
local MG = require("__cma-graphics__/lib/machine_graphics")
local S = require("prototypes.showcase")
local sub = S.subgroup("logistics", "f")
local DIRS = {"north", "east", "south", "west"}
local ENT = "__cma-graphics__/graphics/entity/crane-inserter/crane-inserter-"

local TIERS = {
  {name = "mk1", rot = 0.02, ext = 0.04, stack = 1, energy = "13kW", health = 150},
  {name = "mk2", rot = 0.04, ext = 0.1, stack = 2, energy = "46kW", health = 200},
  {name = "mk3", rot = 0.06, ext = 0.15, stack = 4, energy = "100kW", health = 250},
}

local function sprite(layer)
  local s = table.deepcopy(layer)
  s.frame_count, s.line_length, s.animation_speed, s.repeat_count = nil, nil, nil, nil
  return s
end

local function hand(tier, part, w, h, shadow)
  return {filename = ENT .. tier .. "-hand-" .. part .. (shadow and "-shadow" or "") .. ".png",
          priority = "extra-high", width = w, height = h, scale = 0.25, draw_as_shadow = shadow or nil}
end

for i, t in ipairs(TIERS) do
  local platform = {}
  for _, d in pairs(DIRS) do
    local g = MG("crane-inserter", {variant = t.name, direction = d})
    platform[d] = {layers = {sprite(g.base), sprite(g.emission), sprite(g.shadow)}}
  end
  local icon = MG("crane-inserter", {variant = t.name, direction = "north"}).icon
  local name = "cma-crane-inserter-" .. t.name
  local e = table.deepcopy(data.raw.inserter["fast-inserter"])
  e.name = name
  e.icon = icon
  e.icon_size = 64
  e.icons = nil
  e.minable = {mining_time = 0.1, result = name}
  e.max_health = t.health
  e.rotation_speed = t.rot
  e.extension_speed = t.ext
  e.stack_size_bonus = t.stack - 1
  e.energy_per_movement = "6kJ"
  e.energy_per_rotation = "6kJ"
  e.energy_source = {type = "electric", usage_priority = "secondary-input", drain = "0.5kW"}
  e.fast_replaceable_group = "inserter"
  e.next_upgrade = i < #TIERS and ("cma-crane-inserter-" .. TIERS[i + 1].name) or nil
  e.platform_picture = platform
  e.platform_frozen = nil
  e.hand_base_picture = hand(t.name, "base", 32, 136)
  e.hand_open_picture = hand(t.name, "open", 72, 164)
  e.hand_closed_picture = hand(t.name, "closed", 72, 164)
  e.hand_base_shadow = hand(t.name, "base", 32, 136, true)
  e.hand_open_shadow = hand(t.name, "open", 72, 164, true)
  e.hand_closed_shadow = hand(t.name, "closed", 72, 164, true)
  e.hand_base_frozen, e.hand_open_frozen, e.hand_closed_frozen = nil, nil, nil
  data:extend({e})
  S.item(name, icon, sub, "h[crane-inserter]-" .. i)
end
