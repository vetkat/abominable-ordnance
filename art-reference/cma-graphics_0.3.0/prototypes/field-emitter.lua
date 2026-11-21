-- Field Emitter Mk1-3: 3x3 beacons built on the vanilla beacon. The emission layer is neutral
-- white, so module tint colours it (apply_tint). Rendered in four directions; beacons don't rotate,
-- so the north set is used here - the others are for rotatable machines in your own mod.
local MG = require("__cma-graphics__/lib/machine_graphics")
local S = require("prototypes.showcase")
local sub = S.subgroup("beacons", "b")

local TIERS = {
  {name = "mk1", slots = 1, supply = 3, energy = "240kW", health = 200},
  {name = "mk2", slots = 2, supply = 4, energy = "480kW", health = 300},
  {name = "mk3", slots = 3, supply = 5, energy = "960kW", health = 400},
}

for i, t in ipairs(TIERS) do
  local G = MG("field-emitter", {variant = t.name, direction = "north", animation_speed = 0.5})
  local name = "cma-field-emitter-" .. t.name
  local e = table.deepcopy(data.raw.beacon.beacon)
  e.name = name
  e.icon = G.icon
  e.icon_size = 64
  e.minable = {mining_time = 0.3, result = name}
  e.fast_replaceable_group = "cma-field-emitter"
  e.next_upgrade = i < #TIERS and ("cma-field-emitter-" .. TIERS[i + 1].name) or nil
  e.max_health = t.health
  e.module_slots = t.slots
  e.supply_area_distance = t.supply
  e.energy_usage = t.energy
  e.heating_energy = mods["space-age"] and "400kW" or nil   -- freezes on Aquilo like the vanilla beacon
  e.drawing_box_vertical_extension = 1.2
  e.graphics_set = {
    module_icons_suppressed = false,
    animation_progress = 1,
    random_animation_offset = true,
    module_tint_mode = "mix",
    no_modules_tint = {1, 1, 1},
    apply_module_tint = "secondary",
    animation_list = {
      {render_layer = "object", always_draw = true, animation = {layers = {G.base, G.shadow}}},
      {render_layer = "object", always_draw = false, apply_tint = true, animation = G.emission},
    },
    light = {intensity = 0.6, size = 6, shift = {0, -1}, color = {1, 1, 1}},
    frozen_patch = G.frozen,
    reset_animation_when_frozen = true,
  }
  data:extend({e})
  S.item(name, G.icon, sub, "a[field-emitter]-" .. i)
end
