-- Research Array Mk1-3: 3x3 labs built on the vanilla lab. Labs can't rotate and can't tint by
-- science pack, so the glow is neutral white (tint the emission layer yourself if you like).
local MG = require("__cma-graphics__/lib/machine_graphics")
local S = require("prototypes.showcase")
local sub = S.subgroup("research", "e")

local TIERS = {
  {name = "mk1", speed = 1, slots = 2, energy = "60kW", health = 150},
  {name = "mk2", speed = 2, slots = 3, energy = "180kW", health = 300},
  {name = "mk3", speed = 4, slots = 4, energy = "600kW", health = 450},
}

for i, t in ipairs(TIERS) do
  local G = MG("research-array", {variant = t.name, animation_speed = 0.5})
  local name = "cma-research-array-" .. t.name
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
  e.fast_replaceable_group = "cma-research-array"
  e.next_upgrade = i < #TIERS and ("cma-research-array-" .. TIERS[i + 1].name) or nil
  e.on_animation = G.working
  e.off_animation = G.idle
  e.frozen_patch = G.frozen
  e.drawing_box_vertical_extension = 0.8
  e.heating_energy = mods["space-age"] and "100kW" or nil
  e.water_reflection = nil
  data:extend({e})
  S.item(name, G.icon, sub, "e[research-array]-" .. i)
end
