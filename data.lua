-- The data stage. This file is the shell: it reads the game's data and
-- passes it to the pure builders in core/.
local Lifecycle = require("core.prototypes.lifecycle")
local Ordnance = require("core.prototypes.ordnance")

local space_age = mods["space-age"] ~= nil

local Common = require("core.prototypes.common")

-- Every machine borrows the looks of a vanilla machine. Another mod can
-- remove it, so the assembler is the fallback.
local function looks(name)
  return assert(
    Common.looks(data.raw["assembling-machine"], name, "assembling-machine-2"),
    "Abominable Ordnance needs the " .. name .. " or the assembling machine 2"
  )
end

local ordnance, husbandry = Ordnance.prototypes({
  incubator = looks("centrifuge"),
  chamber = looks("assembling-machine-3"),
})

data:extend(Lifecycle.prototypes({
  space_age = space_age,
  pod = looks(space_age and "biochamber" or "chemical-plant"),
  extra_unlocks = husbandry,
}))
data:extend(ordnance)
