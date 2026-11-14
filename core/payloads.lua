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

function Payloads.load_recipe(species, payload)
  return "ao-load-" .. species.name .. "-" .. payload.name
end

-- The spoil effect of a loaded larva. Like the egg's ao-hatch-<species>,
-- it names what hatches.
function Payloads.effect_id(species, payload)
  return "ao-hatch-" .. species.name .. "-" .. payload.name
end

-- Every loaded effect ID, built once, to its species and payload.
local BY_EFFECT = {}
for _, species in ipairs(Species.ALL) do
  for _, payload in ipairs(Payloads.ALL) do
    BY_EFFECT[Payloads.effect_id(species, payload)] = { species = species, payload = payload }
  end
end

-- The species and payload of a loaded larva's spoil effect, or nil.
function Payloads.decode(effect_id)
  local entry = BY_EFFECT[effect_id]
  if not entry then
    return nil
  end
  return entry.species, entry.payload
end

return Payloads
