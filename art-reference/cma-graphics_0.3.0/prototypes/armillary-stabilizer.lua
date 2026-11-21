-- Armillary Stabilizer Mk1-3: 3x3 exotic labs built on the vanilla lab (the graphics suit a beacon or crafter too). Labs can't rotate and can't tint by
-- science pack, so the glow is neutral white (tint the emission layer yourself if you like).
local MG = require("__cma-graphics__/lib/machine_graphics")
local S = require("prototypes.showcase")
local sub = S.subgroup("exotic", "g")

local TIERS = {
  {name = "mk1", speed = 3, slots = 2, energy = "500kW", health = 300},
  {name = "mk2", speed = 6, slots = 3, energy = "1.5MW", health = 450},
  {name = "mk3", speed = 12, slots = 4, energy = "4MW", health = 600},
}

for i, t in ipairs(TIERS) do
  local G = MG("armillary-stabilizer", {variant = t.name, animation_speed = 0.5})
  local name = "cma-armillary-stabilizer-" .. t.name
  local e = table.deepcopy(data.raw.lab.lab)
  e.name = name
  e.icon = G.icon
  e.icon_size = 64
  e.icons = nil
  e.minable = {mining_time = 0.3, result = name}
  e.max_health = t.health
  e.researching_speed = t.speed
  e.module_slots = t.slots
  e.energy_usage = t.energy
  e.fast_replaceable_group = "cma-armillary-stabilizer"
  e.next_upgrade = i < #TIERS and ("cma-armillary-stabilizer-" .. TIERS[i + 1].name) or nil
  e.on_animation = G.working
  e.off_animation = G.idle
  e.frozen_patch = G.frozen
  e.drawing_box_vertical_extension = 1
  e.heating_energy = mods["space-age"] and "100kW" or nil
  e.water_reflection = nil
  data:extend({e})
  S.item(name, G.icon, sub, "a[armillary-stabilizer]-" .. i)
end
