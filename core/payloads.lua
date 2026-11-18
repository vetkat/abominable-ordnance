-- The payloads a larva can carry, and the names of the loaded larvae.
-- Pure data and lookups.
local Balance = require("core.balance")
local Names = require("core.names")
local Species = require("core.species")

local Payloads = {}

-- The target classes of a payload. shell/damage.lua reads the class of
-- an entity from its prototype.
Payloads.CLASSES = { "organic", "rock", "building" }

Payloads.ALL = {
  {
    name = "explosive",
    item = "explosive-rocket",
    icon = "__base__/graphics/icons/explosive-rocket.png",
    targets = { organic = true, rock = true, building = true },
    damage_type = "explosion",
    -- The explosion shows a picture. The script deals one hit.
    death = { entity = "big-explosion", hit = true },
  },
  {
    name = "acid",
    item = "sulfuric-acid-barrel",
    icon = "__base__/graphics/icons/fluid/sulfuric-acid.png",
    targets = { organic = true, building = true },
    damage_type = "acid",
    -- One pool hurts only what stands in it, so the death spreads five
    -- look-alikes. One hazard covers them.
    death = { entity = Names.POOL, spread = true, hazard = true },
    -- Under a live acid monster: a puddle look-alike and a small hit.
    live = { lookalike = Names.PUDDLE, balance_key = "trail" },
    -- The hazard slows the units and characters it hits.
    sticker = "acid-sticker-big",
  },
  {
    name = "poison",
    item = "poison-capsule",
    icon = "__base__/graphics/icons/poison-capsule.png",
    targets = { organic = true },
    damage_type = "poison",
    death = { entity = Names.CLOUD, hazard = true },
    -- Around a live poison monster: a puff look-alike and a hit.
    live = { lookalike = Names.PUFF, balance_key = "aura" },
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

-- The effect that a larva rocket runs where it lands.
function Payloads.land_id(species, payload)
  return "ao-land-" .. species.name .. "-" .. payload.name
end

-- The hidden projectile that carries a larva rocket.
function Payloads.projectile_name(species, payload)
  return "ao-larva-projectile-" .. species.name .. "-" .. payload.name
end

-- Every landing effect ID, built once, to its species and payload.
local BY_LAND = {}
for _, species in ipairs(Species.ALL) do
  for _, payload in ipairs(Payloads.ALL) do
    BY_LAND[Payloads.land_id(species, payload)] = { species = species, payload = payload }
  end
end

-- The species and payload of a landing effect, or nil.
function Payloads.decode_land(effect_id)
  local entry = BY_LAND[effect_id]
  if not entry then
    return nil
  end
  return entry.species, entry.payload
end

local BY_NAME = {}
for _, payload in ipairs(Payloads.ALL) do
  BY_NAME[payload.name] = payload
end

-- True when the payload hurts a target of this class. An unknown
-- payload or class hurts nothing.
function Payloads.hits(name, class)
  local payload = BY_NAME[name]
  return payload ~= nil and payload.targets[class] == true
end

-- The damage type of a payload, or nil for an unknown one.
function Payloads.damage_type(name)
  local payload = BY_NAME[name]
  return payload and payload.damage_type or nil
end

-- The numbers of a payload in Balance.payload_damage, or nil for an
-- unknown one.
function Payloads.numbers(name)
  return BY_NAME[name] and Balance.payload_damage[name] or nil
end

-- The death spot and, for a spread effect, four spots around it.
local SPREAD = { { 0, 0 }, { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }

-- The create_entity tables of one death effect, without force or cause.
-- An entity whose prototype fails exists(name) stays out.
local function entities(death, position, exists)
  local out = {}
  if not exists(death.entity) then
    return out
  end
  for _, o in ipairs(death.spread and SPREAD or { { 0, 0 } }) do
    local d = Balance.acid_spread
    out[#out + 1] = {
      name = death.entity,
      position = { x = position.x + o[1] * d, y = position.y + o[2] * d },
    }
  end
  return out
end

-- True when a monster's payloads hold the payload name.
function Payloads.carries(payloads, name)
  for _, payload in ipairs(payloads or {}) do
    if payload == name then
      return true
    end
  end
  return false
end

-- One plan per payload of a monster that dies at a position. A plan
-- names the payload, lists the entities to create, and carries the
-- script hit (hit) or the hazard (hazard) when the payload has one. A
-- missing prototype takes the entities out, never the damage. An
-- unknown payload gives no plan.
function Payloads.on_death(names, position, exists)
  local out = {}
  for _, name in ipairs(names) do
    local payload = BY_NAME[name]
    if payload then
      local plan = { payload = name, entities = entities(payload.death, position, exists) }
      if payload.death.hit then
        local n = Balance.payload_damage[name]
        plan.hit = { damage = n.damage, radius = n.radius }
      end
      if payload.death.hazard then
        plan.hazard = { ticks = Balance.payload_damage[name].ticks }
      end
      out[#out + 1] = plan
    end
  end
  return out
end

-- The live effect of the first payload that has one, and that
-- payload's name. Nil when no payload acts while its monster lives.
function Payloads.live(names)
  for _, name in ipairs(names) do
    local payload = BY_NAME[name]
    if payload and payload.live then
      return payload.live, name
    end
  end
  return nil
end

-- The sticker that a payload's hazard puts on mobile targets, or nil.
function Payloads.sticker(name)
  local payload = BY_NAME[name]
  return payload and payload.sticker or nil
end

return Payloads
