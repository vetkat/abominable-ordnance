-- Orbital Receiver Mk1-3: 4x4 power sources (electric-energy-interface showcase; a solar panel
-- can't animate). A beam comes down from above into the dish; the sprite is tall (the beam fades
-- out about three tiles up), so drawing_box_vertical_extension is generous.
local MG = require("__cma-graphics__/lib/machine_graphics")
local S = require("prototypes.showcase")
local sub = S.subgroup("exotic", "g")

local TIERS = {
  {name = "mk1", power = "5MW", health = 300},
  {name = "mk2", power = "15MW", health = 450},
  {name = "mk3", power = "40MW", health = 600},
}

for i, t in ipairs(TIERS) do
  local G = MG("orbital-receiver", {variant = t.name, animation_speed = 0.5})
  local name = "cma-orbital-receiver-" .. t.name
  local e = table.deepcopy(data.raw["electric-energy-interface"]["electric-energy-interface"])
  e.name = name
  e.icon = G.icon
  e.icon_size = 64
  e.icons = nil
  e.hidden = nil
  e.flags = {"placeable-neutral", "player-creation"}
  e.minable = {mining_time = 0.3, result = name}
  e.max_health = t.health
  e.collision_box = {{-1.8, -1.8}, {1.8, 1.8}}
  e.selection_box = {{-2, -2}, {2, 2}}
  e.gui_mode = "none"
  e.energy_source = {type = "electric", usage_priority = "primary-output", buffer_capacity = t.power:gsub("MW", "MJ"),
                     input_flow_limit = "0kW", output_flow_limit = t.power}
  e.energy_production = t.power
  e.energy_usage = "0kW"
  e.picture = nil
  e.pictures = nil
  e.animations = nil
  e.animation = G.working
  e.continuous_animation = true
  e.fast_replaceable_group = "cma-orbital-receiver"
  e.next_upgrade = i < #TIERS and ("cma-orbital-receiver-" .. TIERS[i + 1].name) or nil
  e.drawing_box_vertical_extension = 3.5
  e.corpse = "big-remnants"
  e.water_reflection = nil
  data:extend({e})
  S.item(name, G.icon, sub, "o[orbital-receiver]-" .. i)
end
