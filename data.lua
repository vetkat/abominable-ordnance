-- The data stage. This file is the shell: it reads the game's data and
-- passes it to the pure builders in core/.
local Lifecycle = require("core.prototypes.lifecycle")
local Ordnance = require("core.prototypes.ordnance")

local space_age = mods["space-age"] ~= nil

local function looks(name)
  local machine = data.raw["assembling-machine"][name]
  return { graphics_set = machine.graphics_set, working_sound = machine.working_sound }
end

local pod = looks(space_age and "biochamber" or "chemical-plant")

data:extend(Lifecycle.prototypes({
  space_age = space_age,
  graphics_set = pod.graphics_set,
  working_sound = pod.working_sound,
  extra_unlocks = Ordnance.husbandry_unlocks(),
}))
data:extend(Ordnance.prototypes({ incubator = looks("centrifuge") }))
