-- The payloads a larva can carry, and the names of the loaded larvae.
-- Pure data and lookups.
local Balance = require("core.balance")
local Species = require("core.species")

local Payloads = {}

Payloads.ALL = {
  {
    name = "explosive",
    item = "explosive-rocket",
    icon = "__base__/graphics/icons/explosive-rocket.png",
    -- A rocket made at its own target explodes at once.
    death = function(p)
      return { { name = "explosive-rocket", position = p, target = p, speed = 1 } }
    end,
  },
  {
    name = "acid",
    item = "sulfuric-acid-barrel",
    icon = "__base__/graphics/icons/fluid/sulfuric-acid.png",
    -- One puddle hurts only what stands in it, so the death spreads five.
    death = function(p)
      local d, name = Balance.acid_spread, "acid-splash-fire-spitter-big"
      return {
        { name = name, position = { x = p.x, y = p.y } },
        { name = name, position = { x = p.x + d, y = p.y } },
        { name = name, position = { x = p.x - d, y = p.y } },
        { name = name, position = { x = p.x, y = p.y + d } },
        { name = name, position = { x = p.x, y = p.y - d } },
      }
    end,
    trail = "acid-splash-fire-spitter-small",
  },
  {
    name = "poison",
    item = "poison-capsule",
    icon = "__base__/graphics/icons/poison-capsule.png",
    death = function(p)
      return { { name = "poison-cloud", position = p } }
    end,
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

local BY_NAME = {}
for _, payload in ipairs(Payloads.ALL) do
  BY_NAME[payload.name] = payload
end

-- The entities to create where a monster with these payloads dies, as
-- create_entity tables without force or cause. It leaves out every
-- entity whose name fails exists(name), for example one another mod
-- removed.
function Payloads.on_death(names, position, exists)
  local out = {}
  for _, name in ipairs(names) do
    local payload = BY_NAME[name]
    for _, effect in ipairs(payload and payload.death(position) or {}) do
      if exists(effect.name) then
        out[#out + 1] = effect
      end
    end
  end
  return out
end

-- The entity that a live monster with these payloads leaves behind, or
-- nil.
function Payloads.trail(names)
  for _, name in ipairs(names) do
    local payload = BY_NAME[name]
    if payload and payload.trail then
      return payload.trail
    end
  end
  return nil
end

return Payloads
