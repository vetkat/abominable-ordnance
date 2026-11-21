-- Logistics Hub Mk1-3: 4x4 roboports. The base picture is the idle frame (roof hatch open); the
-- door leaves are the machine's "tint" layer (leaves only, 16 frames open -> closed), played
-- backwards as the door animation; the glow sheet is the looping base animation. Charging pylons
-- stand at the vanilla charging offsets.
local MG = require("__cma-graphics__/lib/machine_graphics")
local S = require("prototypes.showcase")
local sub = S.subgroup("logistics", "f")

local TIERS = {
  {name = "mk1", robots = 7, logistic = 25, construction = 55, charge = "1MW", health = 500},
  {name = "mk2", robots = 10, logistic = 35, construction = 70, charge = "2MW", health = 750},
  {name = "mk3", robots = 14, logistic = 50, construction = 90, charge = "4MW", health = 1000},
}

local function sprite(layer)
  local s = table.deepcopy(layer)
  s.frame_count, s.line_length, s.animation_speed, s.repeat_count = nil, nil, nil, nil
  return s
end

for i, t in ipairs(TIERS) do
  local G = MG("logistics-hub", {variant = t.name, animation_speed = 0.5})
  local door = table.deepcopy(G.tint)
  door.run_mode = "backward"
  local name = "cma-logistics-hub-" .. t.name
  local e = table.deepcopy(data.raw.roboport.roboport)
  e.name = name
  e.icon = G.icon
  e.icon_size = 64
  e.icons = nil
  e.minable = {mining_time = 0.3, result = name}
  e.max_health = t.health
  e.robot_slots_count = t.robots
  e.material_slots_count = t.robots
  e.logistics_radius = t.logistic
  e.construction_radius = t.construction
  e.charging_energy = t.charge
  e.fast_replaceable_group = "cma-logistics-hub"
  e.next_upgrade = i < #TIERS and ("cma-logistics-hub-" .. TIERS[i + 1].name) or nil
  e.base = {layers = {sprite(G.idle_base), sprite(G.shadow)}}
  e.base_patch = nil
  e.base_animation = G.emission
  e.door_animation_up = door
  e.door_animation_down = door
  e.frozen_patch = nil
  e.water_reflection = nil
  e.drawing_box_vertical_extension = 0.8
  data:extend({e})
  S.item(name, G.icon, sub, "f[logistics-hub]-" .. i)
end
