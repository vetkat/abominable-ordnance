-- Capacitor Bank Mk1-3: 2x2 accumulators. One rendered loop serves both states: energy rises
-- through the level tubes while charging; discharging plays the same sheets backwards.
local MG = require("__cma-graphics__/lib/machine_graphics")
local S = require("prototypes.showcase")
local sub = S.subgroup("power-storage", "a3")

local TIERS = {
  {name = "mk1", buffer = "5MJ", flow = "300kW", health = 150},
  {name = "mk2", buffer = "20MJ", flow = "1MW", health = 250},
  {name = "mk3", buffer = "80MJ", flow = "4MW", health = 400},
}

local function sprite(layer)
  local s = table.deepcopy(layer)
  s.frame_count, s.line_length, s.animation_speed, s.repeat_count = nil, nil, nil, nil
  return s
end

for i, t in ipairs(TIERS) do
  local G = MG("capacitor-bank", {variant = t.name, animation_speed = 0.4})
  local back = MG("capacitor-bank", {variant = t.name, animation_speed = 0.4})
  for _, l in pairs({back.base, back.emission}) do l.run_mode = "backward" end
  local name = "cma-capacitor-bank-" .. t.name
  local e = table.deepcopy(data.raw.accumulator.accumulator)
  e.name = name
  e.icon = G.icon
  e.icon_size = 64
  e.icons = nil
  e.minable = {mining_time = 0.2, result = name}
  e.max_health = t.health
  e.energy_source = {type = "electric", buffer_capacity = t.buffer, usage_priority = "tertiary",
                     input_flow_limit = t.flow, output_flow_limit = t.flow}
  e.fast_replaceable_group = "cma-capacitor-bank"
  e.next_upgrade = i < #TIERS and ("cma-capacitor-bank-" .. TIERS[i + 1].name) or nil
  e.drawing_box_vertical_extension = 0.8
  e.chargable_graphics = {
    picture = {layers = {sprite(G.idle_base), sprite(G.shadow)}},
    charge_animation = {layers = {G.base, G.emission, G.shadow}},
    discharge_animation = {layers = {back.base, back.emission, back.shadow}},
    charge_cooldown = 30,
    discharge_cooldown = 60,
  }
  e.water_reflection = nil
  data:extend({e})
  S.item(name, G.icon, sub, "a[capacitor-bank]-" .. i)
end
