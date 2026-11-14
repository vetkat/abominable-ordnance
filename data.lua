-- The data stage. This file is the shell: it reads the game's data and
-- passes it to the pure builders in core/.
local Lifecycle = require("core.prototypes.lifecycle")
local Ordnance = require("core.prototypes.ordnance")

local space_age = mods["space-age"] ~= nil

local function looks(name)
  local machine = data.raw["assembling-machine"][name]
  return { graphics_set = machine.graphics_set, working_sound = machine.working_sound }
end

local ordnance, husbandry = Ordnance.prototypes({ incubator = looks("centrifuge") })

data:extend(Lifecycle.prototypes({
  space_age = space_age,
  pod = looks(space_age and "biochamber" or "chemical-plant"),
  extra_unlocks = husbandry,
}))
data:extend(ordnance)
