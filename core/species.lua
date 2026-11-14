-- The two species of version 1. The units and evolution points are each
-- species' own units from the vanilla spawners in Factorio 2.1.24.
local Names = require("core.names")

local Species = {}

Species.ALL = {
  {
    name = "biter",
    egg = "ao-biter-egg",
    feed = Names.MONSTER_CHOW,
    spawner = "biter-spawner",
    effect_id = "ao-hatch-biter",
    larva = "ao-biter-larva",
    tint = { r = 0.9, g = 0.75, b = 0.5, a = 1 },
    -- With Space Age, the adopt recipe turns this vanilla item into the egg.
    adopts = "biter-egg",
    units = {
      { "small-biter", { { 0.0, 0.3 }, { 0.6, 0.0 } } },
      { "medium-biter", { { 0.2, 0.0 }, { 0.6, 0.3 }, { 0.7, 0.1 } } },
      { "big-biter", { { 0.5, 0.0 }, { 1.0, 0.4 } } },
      { "behemoth-biter", { { 0.9, 0.0 }, { 1.0, 0.3 } } },
    },
  },
  {
    name = "spitter",
    egg = "ao-spitter-egg",
    feed = Names.SPITTER_CHOW,
    spawner = "spitter-spawner",
    effect_id = "ao-hatch-spitter",
    larva = "ao-spitter-larva",
    tint = { r = 0.6, g = 0.9, b = 0.5, a = 1 },
    units = {
      { "small-spitter", { { 0.25, 0.0 }, { 0.5, 0.3 }, { 0.7, 0.0 } } },
      { "medium-spitter", { { 0.4, 0.0 }, { 0.7, 0.3 }, { 0.9, 0.1 } } },
      { "big-spitter", { { 0.5, 0.0 }, { 1.0, 0.4 } } },
      { "behemoth-spitter", { { 0.9, 0.0 }, { 1.0, 0.3 } } },
    },
  },
}

local function find(field, value)
  for _, species in ipairs(Species.ALL) do
    if species[field] == value then
      return species
    end
  end
  return nil
end

-- Eggs and larvae of a species share its hatch effect.
function Species.by_effect_id(id)
  return find("effect_id", id)
end

function Species.by_spawner(name)
  return find("spawner", name)
end

return Species
