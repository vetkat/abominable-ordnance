-- The data stage. This file is the shell: it reads the game's data and
-- passes it to the pure builders in core/.
local Launcher = require("core.launcher")
local LauncherPrototypes = require("core.prototypes.launcher")
local Lifecycle = require("core.prototypes.lifecycle")
local Ordnance = require("core.prototypes.ordnance")
local Stasis = require("core.prototypes.stasis")

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

-- The larva launcher copies vanilla artillery. Another mod can remove
-- it, and the mod can't work without it.
local function vanilla(kind, name)
  return assert(
    (data.raw[kind] or {})[name],
    "Abominable Ordnance needs the vanilla " .. kind .. " " .. name
  )
end

local ordnance, husbandry = Ordnance.prototypes({
  incubator = looks("centrifuge"),
  chamber = looks("assembling-machine-3"),
  projectile = vanilla("artillery-projectile", "artillery-projectile"),
})

local lifecycle = Lifecycle.prototypes({
  space_age = space_age,
  pod = looks(space_age and "biochamber" or "chemical-plant"),
  extra_unlocks = husbandry,
})
data:extend(lifecycle)
data:extend(ordnance)

-- The stasis ward needs these vanilla items. An overhaul mod can remove
-- them.
for _, name in ipairs({ "plastic-bar", "steel-plate", "electronic-circuit" }) do
  vanilla("item", name)
end
local sources = {}
Common.append(sources, lifecycle)
Common.append(sources, ordnance)
data:extend(Stasis.prototypes(sources))

data:extend(LauncherPrototypes.prototypes({
  turret = vanilla("artillery-turret", "artillery-turret"),
  flare = vanilla("artillery-flare", "artillery-flare"),
  remote = vanilla("capsule", "artillery-targeting-remote"),
  cannon = vanilla("gun", "artillery-wagon-cannon").attack_parameters,
  space_age = space_age,
  levels = Launcher.levels(),
}))
