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
-- builds the same sets from the same prototypes, and nothing changes
-- them after the build, so this cache never differs between clients.
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
  return { organic = organic, rock = rock, organic_types = types }
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

-- The type filter of a payload's search, or nil to search everything.
-- A payload that hurts buildings searches everything, because a
-- building is any other entity. The others search their classes' types.
local function search_types(payload)
  if Payloads.hits(payload, "building") then
    return nil
  end
  local types = {}
  if Payloads.hits(payload, "organic") then
    for _, t in ipairs(class_sets().organic_types) do
      types[#types + 1] = t
    end
  end
  if Payloads.hits(payload, "rock") then
    types[#types + 1] = "simple-entity"
  end
  return types
end

-- The entities with health within radius of a position that the
-- payload hurts.
function Damage.targets(surface, position, radius, payload)
  local types = search_types(payload)
  if types and #types == 0 then
    return {}
  end
  local out = {}
  local found = surface.find_entities_filtered({
    position = position,
    radius = radius,
    type = types,
  })
  for _, entity in pairs(found) do
    if
      entity.valid
      and entity.is_entity_with_health
      and Payloads.hits(payload, Damage.class_of(entity))
    then
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

-- One hit of a payload. hit has surface, position, radius, payload,
-- damage and force (a force name). It may have cause (the entity that
-- set it off) and skip (an entity the hit spares). No caller uses skip
-- before the acid trail of PR 3. The hit checks each target first,
-- because an earlier target's death can take a later one with it, and
-- another mod's death handler can destroy the cause. It returns the
-- targets that still exist. When another mod removed the damage type,
-- the hit deals no damage.
--
-- The natives may deal the hit for a force with friendly fire off. Then
-- the hit has no cause, because a cause from another force would
-- mislead.
function Damage.hit(hit)
  local kind = Damage.damage_type(hit.payload, prototypes.damage)
  if not kind then
    return {}
  end
  local survivors = {}
  -- The attacker for each target force, read once per hit.
  local attackers = {}
  for _, target in ipairs(Damage.targets(hit.surface, hit.position, hit.radius, hit.payload)) do
    if target.valid and target ~= hit.skip then
      local force = target.force
      local attacker = attackers[force.name]
      if not attacker then
        attacker = Forces.attacker(hit.force, force.name, force.friendly_fire)
        attackers[force.name] = attacker
      end
      local cause = hit.cause and hit.cause.valid and attacker == hit.force and hit.cause or nil
      target.damage(hit.damage, attacker, kind, nil, cause)
      if target.valid then
        survivors[#survivors + 1] = target
      end
    end
  end
  return survivors
end

-- A save from before the queue has neither field, and a mod update
-- with the same version never runs on_configuration_changed. So the
-- queue creates its fields when it finds them missing.
local function ensure_queue()
  storage.detonations = storage.detonations or {}
  storage.detonation_counter = storage.detonation_counter or 0
end

-- Adds one detonation per payload to the queue. force is a force name.
function Damage.queue(surface, position, payloads, force)
  ensure_queue()
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

-- A save from before the hazards has neither field. Like the queue, the
-- hazard pass creates them when it finds them missing.
local function ensure_hazards()
  storage.hazards = storage.hazards or {}
  storage.hazard_counter = storage.hazard_counter or 0
end

-- Stores the hazard of a plan. Its first hit is due at once, so the
-- hazard pass deals it within its budget.
local function start_hazard(d, plan)
  ensure_hazards()
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
  ensure_queue()
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
-- must leave.
local function hazard_hit(hazard, count)
  local surface = game.get_surface(hazard.surface)
  local n = Payloads.numbers(hazard.payload)
  if not (surface and game.forces[hazard.force] and n) then
    return false
  end
  Damage.hit({
    surface = surface,
    position = hazard.position,
    radius = n.radius,
    payload = hazard.payload,
    damage = n.damage * count,
    force = hazard.force,
  })
  return true
end

local function remove_hazard(id)
  if storage.hazards[id] then
    storage.hazard_cursor = Trail.forget(storage.hazards, storage.hazard_cursor, id)
    storage.hazards[id] = nil
  end
end

-- One tick of the hazard pass. core/hazards.lua picks the visits and
-- the hits within the budget. This function deals the hits and removes
-- the hazards that end. A drained table starts again as a fresh table,
-- like the queue. A hit only adds to the queue, so the table gains no
-- key while the pass walks it.
function Damage.run_hazards(tick)
  ensure_hazards()
  if next(storage.hazards) == nil then
    return
  end
  local plan = Hazards.plan(storage.hazards, storage.hazard_cursor, tick, Balance.payload_damage)
  storage.hazard_cursor = plan.cursor
  for _, h in ipairs(plan.hits) do
    local hazard = storage.hazards[h.id]
    hazard.last_hit = h.last_hit
    if not hazard_hit(hazard, h.count) then
      remove_hazard(h.id)
    end
  end
  for _, id in ipairs(plan.done) do
    remove_hazard(id)
  end
  if next(storage.hazards) == nil then
    storage.hazards = {}
    storage.hazard_cursor = nil
  end
end

return Damage
