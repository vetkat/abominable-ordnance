-- The final fixes stage. This file is the shell: it reads the game's
-- data and passes it to the pure builders in core/.
--
-- The look-alikes copy vanilla effects here, after the data and
-- data-updates stages of every mod. So a mod that removes an effect, an
-- entity that the effect names or the acid damage type there does not
-- break the load. A mod that does so in its own data-final-fixes.lua and
-- loads after this one still can.
local LauncherPrototypes = require("core.prototypes.launcher")
local Ordnance = require("core.prototypes.ordnance")

local function raw(kind, name)
  return (data.raw[kind] or {})[name]
end

-- A create-smoke effect names an entity of any entity type.
local function entity_exists(name)
  for kind in pairs(defines.prototypes.entity) do
    if raw(kind, name) then
      return true
    end
  end
  return false
end

local lookalikes = Ordnance.lookalikes({
  cloud = raw("smoke-with-trigger", "poison-cloud"),
  pool = raw("fire", "acid-splash-fire-spitter-big"),
  puddle = raw("fire", "acid-splash-fire-spitter-small"),
  entity_exists = entity_exists,
  damage_exists = function(name)
    return raw("damage-type", name) ~= nil
  end,
})
if #lookalikes > 0 then
  data:extend(lookalikes)
end

-- The vanilla artillery remote must not fire the larva launcher. This
-- runs last, so it sees a category that another mod set earlier.
local vanilla_flare = raw("artillery-flare", "artillery-flare")
local category = LauncherPrototypes.vanilla_flare_category(
  vanilla_flare,
  raw("ammo-category", "artillery-shell") ~= nil
)
if category then
  vanilla_flare.shot_category = category
end
