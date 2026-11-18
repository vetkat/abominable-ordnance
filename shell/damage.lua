-- Deals the payload damage in the game: the class of a target, the
-- targets of a payload in an area, one hit, the detonation queue and
-- the hazards.
-- This module is shell: it reads and writes the game. control.lua calls
-- it, and so do the in-game tests. The rules live in core/payloads.lua.
local Balance = require("core.balance")
local Forces = require("core.forces")
local Hazards = require("core.hazards")
local Payloads = require("core.payloads")
local Trail = require("core.trail")

local Damage = {}

-- True when a prototype with this name exists. Another mod can remove
-- one.
function Damage.entity_exists(name)
  return prototypes.entity[name] ~= nil
end

-- The class sets, built once per load from the prototypes. Every client
-- builds the same sets from the same prototypes. The only later change
-- adds a payload's search types, which come from the same sets. So this
-- cache never differs between clients.
local classes

-- The organic names, the rock names and the sorted types of the
-- organic prototypes. A rock is a simple-entity with the rock flag of
-- the deconstruction filter. An organic breathes air.
local function build_classes()
  local organic, rock, types, seen = {}, {}, {}, {}
  for name, proto in pairs(prototypes.entity) do
    if proto.type == "simple-entity" and proto.count_as_rock_for_filtered_deconstruction then
      rock[name] = true
    elseif proto.has_flag("breaths-air") then
      organic[name] = true
      if not seen[proto.type] then
        seen[proto.type] = true
        types[#types + 1] = proto.type
      end
    end
  end
  table.sort(types)
  return { organic = organic, rock = rock, organic_types = types, search = {} }
end

local function class_sets()
  classes = classes or build_classes()
  return classes
end

-- The target class of an entity: organic, rock or building.
---@param entity LuaEntity
function Damage.class_of(entity)
  local c = class_sets()
  if c.rock[entity.name] then
    return "rock"
  end
  if c.organic[entity.name] then
    return "organic"
  end
  return "building"
end

-- The type filter of a payload's search, or false to search everything.
-- A payload that hurts buildings searches everything, because a
-- building is any other entity. The others search their classes' types.
local function build_search(payload, c)
  if Payloads.hits(payload, "building") then
    return false
  end
  local types = {}
  if Payloads.hits(payload, "organic") then
    for _, t in ipairs(c.organic_types) do
      types[#types + 1] = t
    end
  end
  if Payloads.hits(payload, "rock") then
    types[#types + 1] = "simple-entity"
  end
  return types
end

-- The type filter of a payload's search, or nil to search everything.
-- Each payload's filter is built once. The search only reads it.
local function search_types(payload)
  local c = class_sets()
  if c.search[payload] == nil then
    c.search[payload] = build_search(payload, c)
  end
  return c.search[payload] or nil
end

-- Every force but spare, in the game's own order, or nil when there is
-- no force to spare.
local function forces_but(spare)
  if not spare then
    return nil
  end
  local out = {}
  for name in pairs(game.forces) do
    if name ~= spare then
      out[#out + 1] = name
    end
  end
  return out
end

-- The entities with health within radius of a position that the
-- payload hurts. The search leaves out the entities of spare_force.
-- With a limit, it finds at most that many entities, so the spared
-- force never uses up the limit. The payload's rule filters them after.
function Damage.targets(surface, position, radius, payload, limit, spare_force)
  local types = search_types(payload)
  if types and #types == 0 then
    return {}
  end
  local out = {}
  local found = surface.find_entities_filtered({
    position = position,
    radius = radius,
    type = types,
    force = forces_but(spare_force),
    limit = limit,
  })
  for _, entity in pairs(found) do
    if entity.is_entity_with_health and Payloads.hits(payload, Damage.class_of(entity)) then
      out[#out + 1] = entity
    end
  end
  return out
end

-- The damage type of a payload, or nil when the payload is unknown or
-- another mod removed its damage type from damage_prototypes.
function Damage.damage_type(payload, damage_prototypes)
  local kind = Payloads.damage_type(payload)
  if kind and damage_prototypes[kind] then
    return kind
  end
  return nil
end

-- The spec gives the slowdown to units and characters only. Vehicles
-- and the spider-units of Space Age get no slowdown.
local MOBILE = { unit = true, character = true }

-- The sticker of a payload, or nil when it has none or entity_prototypes
-- lacks it as a sticker. Another mod can remove it or reuse its name.
function Damage.sticker(payload, entity_prototypes)
  local name = Payloads.sticker(payload)
  local proto = name and entity_prototypes[name]
  return proto and proto.type == "sticker" and name or nil
end

-- One hit of a payload. hit has surface, position, radius, payload,
-- damage and force (a force name). It may have cause (the entity that
-- set it off), skip (an entity the hit spares), spare_force (a force
-- name whose entities the hit spares), limit (the most entities its
-- search finds) and sticker (a sticker name for each mobile survivor).
-- A sticker takes the force that dealt the hit. The hit checks each
-- target first, because an earlier target's death can take a later one
-- with it, and another mod's death handler can destroy the cause. It
-- returns the targets that still exist, and the number of targets it
-- damaged plus the stickers it created, for the target budget. When
-- another mod removed the damage type, the hit deals no damage.
--
-- The natives may deal the hit for a force with friendly fire off. Then
-- the hit has no cause, because a cause from another force would
-- mislead.
function Damage.hit(hit)
  local kind = Damage.damage_type(hit.payload, prototypes.damage)
  if not kind then
    return {}, 0
  end
  local survivors, dealt = {}, 0
  -- The attacker for each target force, read once per hit.
  local attackers = {}
  local targets =
    Damage.targets(hit.surface, hit.position, hit.radius, hit.payload, hit.limit, hit.spare_force)
  for _, target in ipairs(targets) do
    if target.valid and target ~= hit.skip then
      local force = target.force
      local name = force.name
      local attacker = attackers[name]
      if not attacker then
        attacker = Forces.attacker(hit.force, name, force.friendly_fire)
        attackers[name] = attacker
      end
      local cause = hit.cause and hit.cause.valid and attacker == hit.force and hit.cause or nil
      target.damage(hit.damage, attacker, kind, nil, cause)
      dealt = dealt + 1
      if target.valid then
        survivors[#survivors + 1] = target
        if hit.sticker and MOBILE[target.type] then
          local sticker = hit.surface.create_entity({
            name = hit.sticker,
            position = target.position,
            target = target,
            force = attacker,
          })
          dealt = dealt + (sticker and 1 or 0)
        end
      end
    end
  end
  return survivors, dealt
end

-- Creates the fields of the queue and the hazards that are missing.
-- Setup.on_init calls it. A save from before the queue or the hazards
-- lacks them, and a mod update with the same version never runs
-- on_configuration_changed. So the queue and the hazard pass call it
-- too.
function Damage.ensure_storage()
  storage.detonations = storage.detonations or {}
  storage.detonation_counter = storage.detonation_counter or 0
  storage.hazards = storage.hazards or {}
  storage.hazard_counter = storage.hazard_counter or 0
end

-- Adds one detonation per payload to the queue. force is a force name.
function Damage.queue(surface, position, payloads, force)
  Damage.ensure_storage()
  for _, payload in ipairs(payloads) do
    storage.detonation_counter = storage.detonation_counter + 1
    storage.detonations[storage.detonation_counter] = {
      surface = surface.index,
      position = { x = position.x, y = position.y },
      payload = payload,
      force = force,
    }
  end
end

-- Stores the hazard of a plan. Its first hit is due at once, so the
-- hazard pass deals it within its budget.
local function start_hazard(d, plan)
  Damage.ensure_storage()
  storage.hazard_counter = storage.hazard_counter + 1
  storage.hazards[storage.hazard_counter] = Hazards.new(
    d.surface,
    d.position,
    plan.payload,
    d.force,
    game.tick,
    plan.hazard.ticks,
    Balance.payload_damage.hazard_interval
  )
end

-- Runs one detonation: the death effect of one payload. A detonation
-- does nothing when its surface or force no longer exists. A hit has no
-- cause, because the monster no longer exists.
function Damage.detonate(d)
  local surface = game.get_surface(d.surface)
  -- When its force no longer exists, the queue drops the detonation.
  if not (surface and game.forces[d.force]) then
    return
  end
  for _, plan in ipairs(Payloads.on_death({ d.payload }, d.position, Damage.entity_exists)) do
    for _, entity in ipairs(plan.entities) do
      entity.force = d.force
      surface.create_entity(entity)
    end
    if plan.hit then
      Damage.hit({
        surface = surface,
        position = d.position,
        radius = plan.hit.radius,
        payload = plan.payload,
        damage = plan.hit.damage,
        force = d.force,
      })
    end
    if plan.hazard then
      start_hazard(d, plan)
    end
  end
end

-- Runs up to detonation_batch detonations. Each one leaves the queue
-- before it runs, so a detonation that kills more loaded monsters only
-- adds to the queue and never recurses. The order within a tick follows
-- next(), not the counter. An empty queue costs one lookup. A drained
-- queue starts again as a fresh table. Then the next() of an idle tick
-- does not scan the empty slots of a large backlog.
function Damage.run_detonations()
  Damage.ensure_storage()
  if next(storage.detonations) == nil then
    return
  end
  local ids = Trail.batch(storage.detonations, nil, Balance.payload_damage.detonation_batch)
  for _, id in ipairs(ids) do
    local d = storage.detonations[id]
    storage.detonations[id] = nil
    Damage.detonate(d)
  end
  if next(storage.detonations) == nil then
    storage.detonations = {}
  end
end

-- Deals the summed hits of one hazard visit. Returns false when the
-- hazard's surface, force or payload no longer exists. Then the hazard
-- must leave. Also returns the number of targets it damaged plus the
-- stickers it created.
local function hazard_hit(hazard, count)
  local surface = game.get_surface(hazard.surface)
  local n = Payloads.numbers(hazard.payload)
  if not (surface and game.forces[hazard.force] and n) then
    return false, 0
  end
  local _, dealt = Damage.hit({
    surface = surface,
    position = hazard.position,
    radius = n.radius,
    payload = hazard.payload,
    damage = n.damage * count,
    force = hazard.force,
    sticker = Damage.sticker(hazard.payload, prototypes.entity),
  })
  return true, dealt
end

local function remove_hazard(id)
  if storage.hazards[id] then
    storage.hazard_cursor = Trail.forget(storage.hazards, storage.hazard_cursor, id)
    storage.hazards[id] = nil
  end
end

-- One tick of the hazard pass. core/hazards.lua picks the visits and
-- the hits within the budget. This function deals the hits until the
-- targets it damaged reach hazard_targets, then removes the hazards that
-- end. It checks the target budget before each hit, so one tick can go
-- over it by the targets of one hit. A hit that does not run keeps its
-- last hit, so the hazard catches up later. A drained table starts
-- again as a fresh table, like the queue. A hit only adds to the queue,
-- so the table gains no key while the pass walks it.
function Damage.run_hazards(tick)
  Damage.ensure_storage()
  if next(storage.hazards) == nil then
    return
  end
  local numbers = Balance.payload_damage
  local plan = Hazards.plan(storage.hazards, storage.hazard_cursor, tick, numbers)
  local ran, dealt, gone = 0, 0, {}
  for _, h in ipairs(plan.hits) do
    if dealt >= numbers.hazard_targets then
      break
    end
    local hazard = storage.hazards[h.id]
    hazard.last_hit = h.last_hit
    local ok, targets = hazard_hit(hazard, h.count)
    if not ok then
      gone[#gone + 1] = h.id
    end
    ran, dealt = ran + 1, dealt + targets
  end
  local rest = Hazards.cut(plan, ran)
  storage.hazard_cursor = rest.cursor
  for _, list in ipairs({ gone, rest.done }) do
    for _, id in ipairs(list) do
      remove_hazard(id)
    end
  end
  if next(storage.hazards) == nil then
    storage.hazards = {}
    storage.hazard_cursor = nil
  end
end

-- One step of a monster's live effect: its look-alike at the monster
-- and one hit around it. The hit always spares the monster. With spare
-- "force", it spares the monster's whole force too, read from the unit.
-- The hit applies even when another mod removed the look-alike's
-- vanilla source.
function Damage.live(entry, force)
  local live, payload = Payloads.live(entry.payloads)
  if not live then
    return
  end
  local unit = entry.unit
  local surface, position = unit.surface, unit.position
  if Damage.entity_exists(live.lookalike) then
    surface.create_entity({ name = live.lookalike, position = position, force = force })
  end
  local n = Balance.payload_damage[live.balance_key]
  Damage.hit({
    surface = surface,
    position = position,
    radius = n.radius,
    payload = payload,
    damage = n.damage,
    force = force,
    cause = unit,
    skip = unit,
    limit = n.max_targets,
    spare_force = live.spare == "force" and unit.force.name or nil,
  })
end

return Damage
