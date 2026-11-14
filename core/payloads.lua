-- The payloads a larva can carry, and the names of the loaded larvae.
-- Pure data and lookups.
local Species = require("core.species")

local Payloads = {}

Payloads.ALL = {
  {
    name = "explosive",
    item = "explosive-rocket",
    icon = "__base__/graphics/icons/explosive-rocket.png",
  },
  {
    name = "acid",
    item = "sulfuric-acid-barrel",
    icon = "__base__/graphics/icons/fluid/sulfuric-acid.png",
  },
  {
    name = "poison",
    item = "poison-capsule",
    icon = "__base__/graphics/icons/poison-capsule.png",
  },
}

function Payloads.loaded_name(species, payload)
  return "ao-" .. species.name .. "-larva-" .. payload.name
end

function Payloads.effect_id(species, payload)
  return "ao-load-" .. species.name .. "-" .. payload.name
end

-- The species and payload of a loaded larva's spoil effect, or nil.
function Payloads.decode(effect_id)
  for _, species in ipairs(Species.ALL) do
    for _, payload in ipairs(Payloads.ALL) do
      if Payloads.effect_id(species, payload) == effect_id then
        return species, payload
      end
    end
  end
  return nil
end

return Payloads
