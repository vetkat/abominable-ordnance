-- Containment Torus Mk1-3: 5x5 reactors built on the vanilla nuclear reactor (same 12 heat
-- connections). A reactor's `picture` is a static Sprite and only `working_light_picture` animates,
-- so the picture is frame 0 of the main sheet and the plasma knots racing round the window slots are
-- the emission sheet. (The full animated main sheet is there for modders using another type.)
local MG = require("__cma-graphics__/lib/machine_graphics")
local S = require("prototypes.showcase")
local sub = S.subgroup("exotic", "g")

local TIERS = {
  {name = "mk1", power = "40MW", temp = 1000, health = 500},
  {name = "mk2", power = "100MW", temp = 1500, health = 800},
  {name = "mk3", power = "250MW", temp = 2000, health = 1200},
}

local function sprite(layer)
  local s = table.deepcopy(layer)
  s.frame_count, s.line_length, s.animation_speed, s.repeat_count = nil, nil, nil, nil
  return s
end

for i, t in ipairs(TIERS) do
  local G = MG("containment-torus", {variant = t.name, animation_speed = 0.5})
  local name = "cma-containment-torus-" .. t.name
  local e = table.deepcopy(data.raw.reactor["nuclear-reactor"])
  e.name = name
  e.icon = G.icon
  e.icon_size = 64
  e.icons = nil
  e.minable = {mining_time = 0.5, result = name}
  e.max_health = t.health
  e.consumption = t.power
  e.fast_replaceable_group = "cma-containment-torus"
  e.next_upgrade = i < #TIERS and ("cma-containment-torus-" .. TIERS[i + 1].name) or nil
  e.picture = {layers = {sprite(G.idle_base), sprite(G.shadow)}}
  e.working_light_picture = G.emission
  e.lower_layer_picture = nil
  e.heat_lower_layer_picture = nil
  e.connection_patches_connected = nil
  e.connection_patches_disconnected = nil
  e.heat_connection_patches_connected = nil
  e.heat_connection_patches_disconnected = nil
  e.heat_buffer.heat_picture = nil
  e.heat_buffer.max_temperature = t.temp
  e.frozen_patch = nil
  e.drawing_box_vertical_extension = 0.6
  e.water_reflection = nil
  e.corpse = "big-remnants"
  data:extend({e})
  S.item(name, G.icon, sub, "c[containment-torus]-" .. i)
end
