-- The data stage. This file is the shell: it reads the game's data and
-- passes it to the pure builder in core/.
local Lifecycle = require("core.prototypes.lifecycle")

local space_age = mods["space-age"] ~= nil
local source = data.raw["assembling-machine"][space_age and "biochamber" or "chemical-plant"]

data:extend(Lifecycle.prototypes({
  space_age = space_age,
  graphics_set = source.graphics_set,
  working_sound = source.working_sound,
}))
