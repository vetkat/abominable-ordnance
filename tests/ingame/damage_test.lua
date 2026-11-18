local Balance = require("core.balance")
local Damage = require("shell.damage")
local FeralShell = require("shell.feral")
local Hazards = require("core.hazards")
local Names = require("core.names")
local Setup = require("shell.setup")
local Helpers = require("__abominable-ordnance__/tests/ingame/helpers")

local surface = function()
  return game.surfaces[1]
end

test("the class of a biter, a tree, a rock and a chest", function()
  local position = { 4000, 4000 }
  Helpers.arena(surface(), position)
  local things = {
    { "small-biter", "organic", "enemy" },
    { "tree-01", "organic" },
    { "big-rock", "rock" },
    { "wooden-chest", "building", "player" },
  }
  for i, thing in ipairs(things) do
    local entity = surface().create_entity({
      name = thing[1],
      position = { position[1] + 4 * i, position[2] },
      force = thing[3],
    })
    local class = Damage.class_of(entity)
    entity.destroy()
    assert(class == thing[2], thing[1] .. " is " .. tostring(class))
  end
end)

test("a poison hit hurts a biter and not a chest beside it", function()
  local position = { 4020, 4000 }
  Helpers.arena(surface(), position)
  local native = surface().create_entity({
    name = "medium-biter",
    position = { position[1] + 1, position[2] },
    force = "enemy",
  })
  native.disabled_by_script = true
  local chest = Helpers.chest(surface(), { position[1] - 1, position[2] })
  local survivors = Damage.hit({
    surface = surface(),
    position = { x = position[1], y = position[2] },
    radius = 3,
    payload = "poison",
    damage = 10,
    force = "ao-tamed",
  })
  local native_hurt = native.health < native.max_health
  local chest_whole = chest.health == chest.max_health
  native.destroy()
  chest.destroy()
  assert(native_hurt, "the native is untouched")
  assert(chest_whole, "the chest is hurt")
  assert(#survivors == 1, #survivors .. " survivors")
end)

test("a hit spares the entity it is told to skip and hurts the one beside it", function()
  local position = { 4040, 4000 }
  Helpers.arena(surface(), position)
  local function biter(dx)
    local native = surface().create_entity({
      name = "medium-biter",
      position = { position[1] + dx, position[2] },
      force = "enemy",
    })
    native.disabled_by_script = true
    return native
  end
  local spared, other = biter(0), biter(1)
  Damage.hit({
    surface = surface(),
    position = spared.position,
    radius = 3,
    payload = "acid",
    damage = 10,
    force = "ao-tamed",
    skip = spared,
  })
  local spared_whole = spared.health == spared.max_health
  local other_hurt = other.health < other.max_health
  spared.destroy()
  other.destroy()
  assert(spared_whole, "the skipped native is hurt")
  assert(other_hurt, "the native that is not skipped is untouched")
end)

test("a hit still hurts a force's own chest when that force has friendly fire off", function()
  local position = { 4060, 3960 }
  Helpers.arena(surface(), position)
  local player = game.forces["player"]
  local plain = Helpers.chest(surface(), { position[1] + 5, position[2] })
  local chest = Helpers.chest(surface(), { position[1] + 1, position[2] })
  local old = player.friendly_fire
  player.friendly_fire = false
  -- A plain hit is the control: the engine swallows it. The flag goes
  -- back before any assert, even when the hit itself fails.
  local ok, err = pcall(function()
    plain.damage(10, "player", "explosion")
    Damage.hit({
      surface = surface(),
      position = { x = position[1], y = position[2] },
      radius = 3,
      payload = "explosive",
      damage = 10,
      force = "player",
    })
  end)
  player.friendly_fire = old
  local plain_whole = plain.health == plain.max_health
  local was_hurt = chest.health < chest.max_health
  plain.destroy()
  chest.destroy()
  assert(ok, err)
  assert(plain_whole, "control: a plain hit hurt the chest, so the engine does not swallow it")
  assert(was_hurt, "the chest is untouched")
end)

local function hurt(entity)
  return not entity.valid or entity.health < entity.max_health
end

local function distance(a, b)
  local dx, dy = a.x - b.x, a.y - b.y
  return math.sqrt(dx * dx + dy * dy)
end

local function destroy_all(things)
  for _, entity in pairs(things) do
    if entity.valid then
      entity.destroy()
    end
  end
end

local function with_entry(position, item, after)
  Helpers.loaded_entry(surface(), position, item, after)
end

test("an explosive death hurts the same targets as its landing, once", function()
  with_entry({ 4060, 4000 }, "ao-biter-larva-explosive", function(entry)
    local p = entry.unit.position
    local targets = {
      native = surface().create_entity({
        name = "medium-biter",
        position = { p.x + 2, p.y },
        force = "enemy",
      }),
      chest = surface().create_entity({
        name = "steel-chest",
        position = { p.x, p.y + 2 },
        force = "player",
      }),
      tamed = surface().create_entity({
        name = "medium-biter",
        position = { p.x - 2, p.y },
        force = Names.TAMED,
      }),
      tree = surface().create_entity({ name = "tree-01", position = { p.x - 2, p.y + 2 } }),
      rock = surface().create_entity({ name = "big-rock", position = { p.x, p.y - 2.5 } }),
    }
    targets.native.disabled_by_script = true
    targets.tamed.disabled_by_script = true
    -- The control chest takes one hit of the death's size, so the loss
    -- of one hit is known after resistances.
    local control = surface().create_entity({
      name = "steel-chest",
      position = { p.x + 12, p.y },
      force = "player",
    })
    local control_before = control.health
    control.damage(Balance.payload_damage.explosive.damage, Names.TAMED, "explosion")
    local one_hit = control_before - control.health
    control.destroy()
    local before = targets.chest.health
    entry.unit.die()
    after_ticks(2, function()
      local first = {}
      for name, entity in pairs(targets) do
        first[name] = hurt(entity)
      end
      local loss = targets.chest.valid and before - targets.chest.health
      after_ticks(60, function()
        local later = targets.chest.valid and before - targets.chest.health
        destroy_all(targets)
        for name in pairs(targets) do
          assert(first[name], name .. " is untouched")
        end
        assert(one_hit > 0, "control: the control chest took no damage")
        assert(loss == one_hit, "the chest lost " .. tostring(loss) .. ", one hit is " .. one_hit)
        assert(later == one_hit, "the chest took a second hit")
      end)
    end)
  end)
end)

-- An explosive death spares the pack's other explosive monsters, so the
-- second monster carries acid.
test("an explosive monster's death kills an acid packmate through the queue", function()
  local position = { 4100, 4000 }
  Helpers.arena(surface(), position, 40)
  game.forces["enemy"].set_evolution_factor(0, surface())
  Helpers.spoil(Helpers.spill(surface(), position, "ao-biter-larva-explosive", 1))
  Helpers.spoil(
    Helpers.spill(surface(), { position[1] + 2.5, position[2] }, "ao-biter-larva-acid", 1)
  )
  after_ticks(1, function()
    local units = Helpers.find_units(surface(), position, { force = Names.TAMED })
    assert(#units == 2, #units .. " tamed units")
    -- The explosive monster goes first.
    table.sort(units, function(a, b)
      return storage.loaded[a.unit_number].payloads[1] == "explosive"
        and storage.loaded[b.unit_number].payloads[1] ~= "explosive"
    end)
    local first, second = units[1], units[2]
    first.disabled_by_script = true
    second.disabled_by_script = true
    local radius = Balance.payload_damage.explosive.radius
    local in_reach = distance(first.position, second.position) <= radius
    if not in_reach then
      destroy_all({ first, second })
      assert(in_reach, "precondition: the second is beyond reach of the first")
    end
    local ids = { first.unit_number, second.unit_number }
    local counter = storage.detonation_counter
    first.die()
    -- The death only queued its detonation, and no tick passed.
    local second_alive = second.valid
    local queued = storage.detonation_counter > counter
    local second_spot = second.position
    after_ticks(3, function()
      local second_gone = not second.valid
      -- The second death ran when its acid pool started.
      local pool_started = false
      for _, h in pairs(storage.hazards) do
        if h.payload == "acid" and distance(h.position, second_spot) < 1 then
          pool_started = true
        end
      end
      local queue_empty = next(storage.detonations) == nil
      local entries_left = storage.loaded[ids[1]] ~= nil or storage.loaded[ids[2]] ~= nil
      destroy_all({ second })
      -- End the acid hazard, so it does not reach later tests.
      for _, h in pairs(storage.hazards) do
        if h.payload == "acid" and distance(h.position, second_spot) < 10 then
          h.end_tick, h.last_hit = game.tick, game.tick
        end
      end
      assert(second_alive, "the first death killed the second inside its own event")
      assert(queued, "the first death left nothing in the queue")
      assert(second_gone, "the first death did not kill the second monster")
      assert(pool_started, "the second death did not run")
      assert(queue_empty, "the queue still holds a detonation")
      assert(not entries_left, "a loaded entry is still there")
    end)
  end)
end)

test(
  "a detonation for a force that a merge removed leaves the queue and deals no damage",
  function()
    local position = { 4140, 4000 }
    Helpers.arena(surface(), position)
    local gone = game.forces["ao-damage-gone"] or game.create_force("ao-damage-gone")
    local chest = Helpers.chest(surface(), { position[1] + 1, position[2] })
    local counter = storage.detonation_counter
    Damage.queue(surface(), { x = position[1], y = position[2] }, { "explosive" }, gone.name)
    local queued = storage.detonation_counter > counter
    game.merge_forces(gone, "player")
    after_ticks(3, function()
      local whole = chest.valid and chest.health == chest.max_health
      local empty = next(storage.detonations) == nil
      destroy_all({ chest })
      assert(queued, "precondition: the detonation did not reach the queue")
      assert(whole, "the chest took damage from a gone force")
      assert(empty, "the detonation is still in the queue")
    end)
  end
)

-- Kills a nest (10 health) by the explosive death of a loaded monster
-- beside it, and passes finish(nest_dead, eggs). A feral monster is on
-- the feral force, which never earns loot.
local function nest_death(position, feral, finish)
  with_entry(position, "ao-biter-larva-explosive", function(entry)
    if feral then
      FeralShell.go_feral(entry, game.tick)
    end
    local p = entry.unit.position
    local spawner = surface().create_entity({
      name = "biter-spawner",
      position = { p.x + 3, p.y },
      force = "enemy",
    })
    spawner.disabled_by_script = true
    spawner.health = 10
    local spot = { spawner.position.x, spawner.position.y }
    entry.unit.die()
    after_ticks(3, function()
      local dead = not spawner.valid
      local eggs = Helpers.count_items(surface(), spot, "ao-biter-egg")
      destroy_all({ spawner })
      finish(dead, eggs)
    end)
  end)
end

test("a feral monster's explosive death kills a nest and drops no eggs", function()
  nest_death({ 4180, 4000 }, true, function(dead, eggs)
    assert(dead, "the nest survived")
    assert(eggs == 0, eggs .. " eggs dropped")
  end)
end)

test("a tamed monster's explosive death kills a nest and drops eggs", function()
  nest_death({ 4220, 4000 }, false, function(dead, eggs)
    assert(dead, "the nest survived")
    assert(eggs >= 1, "control: the tamed kill dropped no eggs")
  end)
end)

-- Runs body with these storage fields taken out, and puts them back
-- before it re-raises an error of body.
local function without(fields, body)
  local saved = {}
  for _, field in ipairs(fields) do
    saved[field] = storage[field]
    storage[field] = nil
  end
  local ok, result = pcall(body)
  for _, field in ipairs(fields) do
    storage[field] = saved[field]
  end
  if not ok then
    error(result)
  end
  return result
end

test("a configuration change creates the queue", function()
  local created = without({ "detonations", "detonation_counter" }, function()
    Setup.on_configuration_changed()
    return storage.detonations ~= nil and storage.detonation_counter == 0
  end)
  assert(created, "the queue is missing after a configuration change")
end)

test(
  "a save without the queue gets it from the first tick and from a call to Damage.queue",
  function()
    local detonations, counter = storage.detonations, storage.detonation_counter
    storage.detonations = nil
    storage.detonation_counter = nil
    after_ticks(2, function()
      local after_tick = storage.detonations ~= nil and storage.detonation_counter ~= nil
      storage.detonations = nil
      storage.detonation_counter = nil
      local ok, result = pcall(function()
        local position = { x = 4260, y = 4000 }
        Damage.queue(surface(), position, { "explosive" }, Names.TAMED)
        return {
          after_queue = storage.detonations ~= nil and storage.detonation_counter == 1,
          queued = next(storage.detonations) ~= nil,
        }
      end)
      storage.detonations, storage.detonation_counter = detonations or {}, counter or 0
      if not ok then
        error(result)
      end
      assert(after_tick, "a tick did not create the queue")
      assert(result.after_queue, "a death did not create the queue")
      assert(result.queued, "the death is not in the queue")
    end)
  end
)

-- Wraps the death event: handler(event) runs first, then the mod's own
-- handler for the types that control.lua filters. Returns a function
-- that puts the original handler back. Its filters must match the
-- on_entity_died filters in control.lua.
local function wrap_deaths(handler)
  local event_id = defines.events.on_entity_died
  local original = script.get_event_handler(event_id)
  script.on_event(event_id, function(event)
    handler(event)
    if original and (event.entity.type == "unit-spawner" or event.entity.type == "unit") then
      original(event)
    end
  end)
  return function()
    script.on_event(event_id, original, {
      { filter = "type", type = "unit-spawner" },
      { filter = "type", type = "unit" },
    })
  end
end

-- Kills a chest with 1 health by a hit of a player force. A player
-- entity is the cause. Then finish(force, cause) gets the names that the
-- death event reports. The test wraps the death event. The original
-- handler goes back before the asserts, even when the hit fails.
local function kill_by_hit(position, friendly_fire, finish)
  Helpers.arena(surface(), position)
  local player = game.forces["player"]
  local old = player.friendly_fire
  local chest, cause, seen
  local unwrap = wrap_deaths(function(event)
    if chest and event.entity == chest then
      seen = { force = event.force, cause = event.cause }
    end
  end)
  -- Puts back the flag and the original handler.
  local function restore()
    player.friendly_fire = old
    unwrap()
  end
  after_ticks(1, function()
    local ok, err = pcall(function()
      chest = Helpers.chest(surface(), { position[1] + 1, position[2] })
      cause = Helpers.character(surface(), { position[1] - 3, position[2] })
      chest.health = 1
      player.friendly_fire = friendly_fire
      Damage.hit({
        surface = surface(),
        position = { x = position[1], y = position[2] },
        radius = 3,
        payload = "explosive",
        damage = 10,
        force = "player",
        cause = cause,
      })
    end)
    player.friendly_fire = old
    if not ok then
      restore()
      destroy_all({ chest, cause })
      error(err)
    end
    after_ticks(2, function()
      restore()
      local dead = not chest.valid
      local force_name = seen and seen.force and seen.force.name
      local cause_name = seen and seen.cause and seen.cause.name
      destroy_all({ chest, cause })
      assert(dead, "the chest survived")
      assert(seen, "the death event did not arrive")
      finish(force_name, cause_name)
    end)
  end)
end

test("a hit that the natives deal for a force with friendly fire off has no cause", function()
  kill_by_hit({ 4300, 4000 }, false, function(force_name, cause_name)
    assert(force_name == "enemy", "the kill counts for " .. tostring(force_name))
    assert(cause_name == nil, "the kill names the cause " .. tostring(cause_name))
  end)
end)

test("a hit of a force with friendly fire on keeps its force and its cause", function()
  kill_by_hit({ 4340, 4000 }, true, function(force_name, cause_name)
    assert(force_name == "player", "the kill counts for " .. tostring(force_name))
    assert(cause_name == "character", "the kill names the cause " .. tostring(cause_name))
  end)
end)

test("a payload whose damage type another mod removed has no damage type", function()
  local known = Damage.damage_type("poison", prototypes.damage)
  local removed = Damage.damage_type("poison", {})
  local unknown = Damage.damage_type("glitter", prototypes.damage)
  assert(known == "poison", "poison has the damage type " .. tostring(known))
  assert(removed == nil, "a removed damage type gives " .. tostring(removed))
  assert(unknown == nil, "an unknown payload gives " .. tostring(unknown))
end)

test("a hit goes on without its cause when a death handler destroys the cause", function()
  local position = { 4380, 4000 }
  Helpers.arena(surface(), position)
  local cause = Helpers.character(surface(), { position[1] - 8, position[2] })
  local chests = {
    Helpers.chest(surface(), { position[1] + 1, position[2] }),
    Helpers.chest(surface(), { position[1] - 1, position[2] }),
  }
  for _, chest in ipairs(chests) do
    chest.health = 1
  end
  -- Another mod's handler: the first death destroys the cause.
  local unwrap = wrap_deaths(function()
    if cause.valid then
      cause.destroy()
    end
  end)
  local ok, err = pcall(Damage.hit, {
    surface = surface(),
    position = { x = position[1], y = position[2] },
    radius = 3,
    payload = "explosive",
    damage = 10,
    force = "player",
    cause = cause,
  })
  unwrap()
  local left = 0
  for _, chest in ipairs(chests) do
    left = left + (chest.valid and 1 or 0)
  end
  destroy_all(chests)
  destroy_all({ cause })
  assert(ok, err)
  assert(left == 0, left .. " chests survived")
end)

test("a drained queue starts again as a fresh table", function()
  local position = { x = 4420, y = 4000 }
  Helpers.arena(surface(), { position.x, position.y })
  Damage.queue(surface(), position, { "explosive" }, Names.TAMED)
  local queue = storage.detonations
  after_ticks(2, function()
    local empty = next(storage.detonations) == nil
    local fresh = storage.detonations ~= queue
    assert(empty, "the queue still holds a detonation")
    assert(fresh, "the drained queue is the old table")
  end)
end)

local HAZARD_FIELDS = { "hazards", "hazard_counter", "hazard_cursor" }

-- The ids of the stored hazards of a payload within 1 tile of a spot.
local function hazards_at(p, payload)
  local ids = {}
  for id, h in pairs(storage.hazards) do
    if h.payload == payload and distance(h.position, p) <= 1 then
      ids[#ids + 1] = id
    end
  end
  return ids
end

-- Adds a hazard to storage as a detonation would, and returns its id.
local function add_hazard(spot, payload, ticks)
  local d = Balance.payload_damage
  storage.hazard_counter = storage.hazard_counter + 1
  local id = storage.hazard_counter
  storage.hazards[id] =
    Hazards.new(surface().index, spot, payload, Names.TAMED, game.tick, ticks, d.hazard_interval)
  return id
end

test("a poison death leaves a cloud that hurts a native for its time, then stops", function()
  with_entry({ 4460, 4000 }, "ao-biter-larva-poison", function(entry)
    local p = entry.unit.position
    local native = surface().create_entity({
      name = "big-biter",
      position = { p.x + 3, p.y },
      force = "enemy",
    })
    native.disabled_by_script = true
    local max = native.max_health
    entry.unit.die()
    after_ticks(2, function()
      local ids = hazards_at(p, "poison")
      local clouds =
        surface().find_entities_filtered({ name = Names.CLOUD, position = p, radius = 2 })
      local first = native.health
      -- Shorten the cloud: its last hit falls within 60 ticks.
      if ids[1] then
        storage.hazards[ids[1]].end_tick = game.tick + 60
      end
      after_ticks(90, function()
        local second = native.health
        local gone = ids[1] ~= nil and storage.hazards[ids[1]] == nil
        after_ticks(60, function()
          local third = native.health
          destroy_all(clouds)
          native.destroy()
          assert(#ids == 1, #ids .. " poison hazards")
          assert(#clouds >= 1, "no cloud look-alike")
          assert(first < max, "the first hit did not land")
          assert(second < first, "the cloud stopped too early")
          assert(gone, "the hazard outlived its end tick")
          -- A biter heals, so its health can only rise without a hit.
          assert(third >= second, "the cloud hurt after its end")
        end)
      end)
    end)
  end)
end)

test("an acid death leaves five pool look-alikes and one hazard that hurts a chest", function()
  with_entry({ 4500, 4000 }, "ao-biter-larva-acid", function(entry)
    local p = entry.unit.position
    local chest = Helpers.chest(surface(), { p.x + 2, p.y + 1 })
    entry.unit.die()
    after_ticks(2, function()
      local pools =
        surface().find_entities_filtered({ name = Names.POOL, position = p, radius = 3 })
      local ids = hazards_at(p, "acid")
      local chest_hurt = hurt(chest)
      destroy_all(pools)
      destroy_all({ chest })
      -- End the hazards now. The pass removes them and keeps its cursor
      -- valid.
      for _, id in ipairs(ids) do
        storage.hazards[id].end_tick = game.tick
        storage.hazards[id].last_hit = game.tick
      end
      assert(#pools == 5, #pools .. " pool look-alikes")
      assert(#ids == 1, #ids .. " acid hazards")
      assert(chest_hurt, "the pool did not hurt the chest")
    end)
  end)
end)

test("with more hazards than hazard_hits, each hazard still deals its full damage", function()
  local position = { 4600, 4000 }
  Helpers.arena(surface(), position, 64)
  local d = Balance.payload_damage
  -- Three hits each: the first at once, then one per interval.
  local ticks = 2 * d.hazard_interval
  local reference = Helpers.chest(surface(), { position[1], position[2] + 12 })
  for _ = 1, 3 do
    reference.damage(d.acid.damage, Names.TAMED, "acid")
  end
  local full = reference.max_health - reference.health
  reference.destroy()
  local chests, ids = {}, {}
  for i = 1, d.hazard_hits + 2 do
    local spot = { x = position[1] - 56 + 8 * i, y = position[2] }
    chests[i] = Helpers.chest(surface(), spot)
    ids[i] = add_hazard(spot, "acid", ticks)
  end
  after_ticks(ticks + 30, function()
    local losses, left = {}, 0
    for i, chest in ipairs(chests) do
      losses[i] = chest.max_health - chest.health
      left = left + (storage.hazards[ids[i]] and 1 or 0)
    end
    destroy_all(chests)
    assert(left == 0, left .. " hazards outlived their end")
    for i, loss in ipairs(losses) do
      local exact = math.abs(loss - full) < 0.01
      assert(exact, "chest " .. i .. " lost " .. loss .. ", expected " .. full)
    end
  end)
end)

test("the hazard pass stops at hazard_targets, and the hazard it skips hits next", function()
  local position = { 4900, 4000 }
  Helpers.arena(surface(), position)
  for _, tree in
    pairs(surface().find_entities_filtered({ position = position, radius = 24, type = "tree" }))
  do
    tree.destroy()
  end
  local d = Balance.payload_damage
  local budget = d.hazard_targets
  d.hazard_targets = 2
  -- Outside the protected call, so an error still destroys the chests.
  local chests = {}
  local ok, r = pcall(without, HAZARD_FIELDS, function()
    storage.hazards, storage.hazard_counter = {}, 0
    local ids, before = {}, {}
    for i = 1, 3 do
      local spot = { x = position[1] - 16 + 8 * i, y = position[2] }
      chests[i] = {
        Helpers.chest(surface(), { spot.x, spot.y }),
        Helpers.chest(surface(), { spot.x + 1, spot.y }),
      }
      ids[i] = add_hazard(spot, "acid", 600)
      before[i] = storage.hazards[ids[i]].last_hit
    end
    -- Two chests per hazard, so the first hazard's hit spends the budget.
    Damage.run_hazards(game.tick)
    local out = {
      first = { hurt(chests[1][1]), hurt(chests[2][1]), hurt(chests[3][1]) },
      cursor = storage.hazard_cursor,
      kept = storage.hazards[ids[2]] and storage.hazards[ids[2]].last_hit == before[2],
    }
    Damage.run_hazards(game.tick)
    out.second = { hurt(chests[2][1]), hurt(chests[3][1]) }
    out.next_cursor = storage.hazard_cursor
    out.ids = ids
    return out
  end)
  d.hazard_targets = budget
  for _, pair in ipairs(chests) do
    destroy_all(pair)
  end
  assert(ok, r)
  assert(r.first[1], "the first hazard did not hit")
  assert(not r.first[2] and not r.first[3], "the pass hit past the target budget")
  assert(r.cursor == r.ids[2], "the cursor is " .. tostring(r.cursor) .. ", not the skipped hazard")
  assert(r.kept, "the skipped hazard lost its due hit")
  assert(r.second[1] and not r.second[2], "the next pass did not start at the skipped hazard")
  assert(r.next_cursor == r.ids[3], "the cursor did not move on to the third hazard")
end)

test("a hazard whose payload the mod no longer knows leaves without damage", function()
  local position = { 4700, 4000 }
  Helpers.arena(surface(), position)
  local chest = Helpers.chest(surface(), { position[1] + 1, position[2] })
  local id = add_hazard({ x = position[1], y = position[2] }, "glitter", 600)
  -- The pass visits hazard_visits (50) hazards per tick. The hazards of
  -- earlier tests stay below 150, so 3 ticks reach this one.
  after_ticks(3, function()
    local whole = chest.health == chest.max_health
    local gone = storage.hazards[id] == nil
    chest.destroy()
    assert(whole, "the unknown hazard hurt the chest")
    assert(gone, "the unknown hazard is still stored")
  end)
end)

-- Other tests leave hazards behind, so this test runs the pass by hand
-- on a table of its own.
test("a drained hazard table starts again as a fresh table", function()
  local position = { 4740, 4000 }
  Helpers.arena(surface(), position)
  local interval = Balance.payload_damage.hazard_interval
  local result = without(HAZARD_FIELDS, function()
    storage.hazards, storage.hazard_counter = {}, 0
    add_hazard({ x = position[1], y = position[2] }, "acid", interval)
    local before = storage.hazards
    Damage.run_hazards(game.tick + interval)
    return {
      empty = next(storage.hazards) == nil,
      fresh = storage.hazards ~= before,
      cursor = storage.hazard_cursor,
    }
  end)
  assert(result.empty, "the hazard table still holds a hazard")
  assert(result.fresh, "the drained hazard table is the old table")
  assert(result.cursor == nil, "the cursor points at " .. tostring(result.cursor))
end)

test("a configuration change creates the hazard table", function()
  local created = without(HAZARD_FIELDS, function()
    Setup.on_configuration_changed()
    return storage.hazards ~= nil and storage.hazard_counter == 0
  end)
  assert(created, "the hazard table is missing after a configuration change")
end)

test("a save without the hazard table gets it from the hazard pass", function()
  local created = without(HAZARD_FIELDS, function()
    Damage.run_hazards(game.tick)
    return storage.hazards ~= nil and storage.hazard_counter == 0
  end)
  assert(created, "the hazard pass did not create the hazard table")
end)

tags("space-age")
test("poison hurts a Gleba plant and a demolisher", function()
  local position = { 4800, 4000 }
  Helpers.arena(surface(), position, 48)
  local plant = surface().create_entity({
    name = "yumako-tree",
    position = { position[1], position[2] },
  })
  local worm = surface().create_entity({
    name = "small-demolisher",
    position = { position[1] + 24, position[2] },
    force = "enemy",
  })
  local function poison(entity)
    Damage.hit({
      surface = surface(),
      position = entity.position,
      radius = 3,
      payload = "poison",
      damage = 100,
      force = Names.TAMED,
    })
  end
  poison(plant)
  local plant_hurt = hurt(plant)
  local worm_hurt = false
  if worm then
    poison(worm)
    worm_hurt = hurt(worm)
  end
  destroy_all({ plant, worm })
  assert(worm, "no demolisher on Nauvis: see decision 17")
  assert(plant_hurt, "poison spared the Gleba plant")
  assert(worm_hurt, "poison spared the demolisher")
end)

-- Runs body with module[key] replaced, and puts the original back
-- before it re-raises an error of body. replace gets the original.
local function wrapped(module, key, replace, body)
  local original = module[key]
  module[key] = replace(original)
  local ok, result = pcall(body)
  module[key] = original
  if not ok then
    error(result)
  end
  return result
end

-- A big biter of the natives that stands still.
local function still_native(position)
  local native =
    surface().create_entity({ name = "big-biter", position = position, force = "enemy" })
  native.disabled_by_script = true
  return native
end

-- Runs a fresh acid hazard at a position by hand, on a table of its
-- own, for the given number of hits. Other tests leave hazards behind.
local function run_acid_hazard(position, hits)
  local interval = Balance.payload_damage.hazard_interval
  without(HAZARD_FIELDS, function()
    storage.hazards, storage.hazard_counter = {}, 0
    add_hazard({ x = position[1], y = position[2] }, "acid", 4 * interval)
    for i = 1, hits do
      Damage.run_hazards(game.tick + (i - 1) * interval)
    end
  end)
end

test("an acid pool slows a native unit once per sticker and does not slow a car", function()
  local position = { 4960, 4000 }
  Helpers.arena(surface(), position)
  local native = still_native({ position[1] + 1.5, position[2] })
  local car = surface().create_entity({
    name = "car",
    position = { position[1] - 1.5, position[2] },
    force = "player",
  })
  local ok, err = pcall(run_acid_hazard, position, 2)
  local native_stickers = native.valid and #(native.stickers or {}) or -1
  local car_hurt = hurt(car)
  local car_stickers = car.valid and #(car.stickers or {}) or -1
  destroy_all({ native, car })
  assert(ok, err)
  assert(native_stickers == 1, native_stickers .. " stickers on the native")
  assert(car_hurt, "the pool spared the car")
  assert(car_stickers == 0, car_stickers .. " stickers on the car")
end)

test("an acid pool still hurts when another mod removed its sticker", function()
  local position = { 5120, 4000 }
  Helpers.arena(surface(), position)
  local native = still_native({ position[1] + 1.5, position[2] })
  local ok, err = pcall(wrapped, Damage, "sticker", function(original)
    return function(payload)
      return original(payload, {})
    end
  end, function()
    run_acid_hazard(position, 1)
  end)
  local native_hurt = hurt(native)
  local stickers = native.valid and #(native.stickers or {}) or -1
  destroy_all({ native })
  assert(ok, err)
  assert(native_hurt, "the pool spared the native")
  assert(stickers == 0, stickers .. " stickers on the native")
end)

test("a payload's sticker must exist and be a sticker", function()
  local real = Damage.sticker("acid", prototypes.entity)
  local missing = Damage.sticker("acid", {})
  local wrong = Damage.sticker("acid", { ["acid-sticker-big"] = { type = "fire" } })
  local none = Damage.sticker("poison", prototypes.entity)
  assert(real == "acid-sticker-big", tostring(real))
  assert(missing == nil, "a missing sticker: " .. tostring(missing))
  assert(wrong == nil, "a sticker of another type: " .. tostring(wrong))
  assert(none == nil, "poison has a sticker: " .. tostring(none))
end)

test("a sticker counts as one more target of its hit", function()
  local position = { 5160, 4000 }
  Helpers.arena(surface(), position)
  local native = still_native({ position[1] + 1, position[2] })
  local function hit(sticker)
    local _, dealt = Damage.hit({
      surface = surface(),
      position = { x = position[1], y = position[2] },
      radius = 3,
      payload = "acid",
      damage = 1,
      force = Names.TAMED,
      sticker = sticker,
    })
    return dealt
  end
  local ok, plain, slowed = pcall(function()
    return hit(nil), hit("acid-sticker-big")
  end)
  destroy_all({ native })
  assert(ok, plain)
  assert(plain == 1, plain .. " targets without a sticker")
  assert(slowed == 2, slowed .. " targets with a sticker")
end)

test("a sticker takes the force that dealt the hit", function()
  local position = { 5200, 4000 }
  Helpers.arena(surface(), position)
  local player = game.forces["player"]
  local character = Helpers.character(surface(), { position[1] + 1, position[2] })
  local old = player.friendly_fire
  player.friendly_fire = false
  local ok, err = pcall(Damage.hit, {
    surface = surface(),
    position = { x = position[1], y = position[2] },
    radius = 3,
    payload = "acid",
    damage = 1,
    force = "player",
    sticker = "acid-sticker-big",
  })
  player.friendly_fire = old
  local sticker = character.valid and (character.stickers or {})[1]
  local force = sticker and sticker.force.name
  destroy_all({ character })
  assert(ok, err)
  assert(force == "enemy", "the sticker's force is " .. tostring(force))
end)

-- The trail pass reaches every monster within 2 * acid_trail_ticks only
-- while fewer than about 300 monsters leave a trail.
local function few_trails()
  local n = table_size(storage.trails)
  assert(n < 300, n .. " trail monsters left by earlier tests: the pass is too slow for the wait")
end

test("an acid trail still hits when another mod removed its puddle", function()
  with_entry({ 5080, 4000 }, "ao-biter-larva-acid", function(entry)
    local p = entry.unit.position
    destroy_all(surface().find_entities_filtered({ name = Names.PUDDLE, position = p, radius = 2 }))
    local chest = Helpers.chest(surface(), { p.x + 0.8, p.y })
    local ok, err = pcall(wrapped, Damage, "entity_exists", function(original)
      return function(name)
        return name ~= Names.PUDDLE and original(name)
      end
    end, function()
      Damage.live(entry, Names.TAMED)
    end)
    local puddles =
      surface().count_entities_filtered({ name = Names.PUDDLE, position = p, radius = 2 })
    local chest_hurt = hurt(chest)
    destroy_all({ chest, entry.unit })
    assert(ok, err)
    assert(puddles == 0, puddles .. " puddles")
    assert(chest_hurt, "the trail spared the chest")
  end)
end)

test("an acid monster's trail hurts a chest and a native, and spares its pack", function()
  few_trails()
  with_entry({ 5000, 4000 }, "ao-biter-larva-acid", function(entry)
    local p = entry.unit.position
    local chest = Helpers.chest(surface(), { p.x + 0.8, p.y })
    local packmate = surface().create_entity({
      name = "medium-biter",
      position = { p.x - 0.8, p.y },
      force = Names.TAMED,
    })
    packmate.disabled_by_script = true
    local native = surface().create_entity({
      name = "medium-biter",
      position = { p.x, p.y + 0.8 },
      force = "enemy",
    })
    native.disabled_by_script = true
    after_ticks(2 * Balance.acid_trail_ticks, function()
      local chest_hurt = hurt(chest)
      local packmate_hurt = hurt(packmate)
      local native_hurt = hurt(native)
      local self_whole = entry.unit.health == entry.unit.max_health
      local puddles = surface().count_entities_filtered({
        name = Names.PUDDLE,
        position = p,
        radius = 2,
      })
      destroy_all({ chest, packmate, native, entry.unit })
      assert(chest_hurt, "the trail spared the chest")
      assert(native_hurt, "the trail spared the native")
      assert(not packmate_hurt, "the trail hurt a tamed packmate")
      assert(self_whole, "the trail hurt its own monster")
      assert(puddles >= 1, "no puddle look-alike")
    end)
  end)
end)

test("an old-save entry with the vanilla trail name drops the look-alike", function()
  few_trails()
  with_entry({ 5040, 4000 }, "ao-biter-larva-acid", function(entry)
    entry.trail = "acid-splash-fire-spitter-small"
    local p = entry.unit.position
    after_ticks(2 * Balance.acid_trail_ticks, function()
      local function count(name)
        return surface().count_entities_filtered({ name = name, position = p, radius = 2 })
      end
      local lookalikes, vanilla = count(Names.PUDDLE), count("acid-splash-fire-spitter-small")
      entry.unit.destroy()
      assert(lookalikes >= 1, "no puddle look-alike")
      assert(vanilla == 0, vanilla .. " vanilla puddles")
    end)
  end)
end)

-- Removes the trees around a position, so the test's own targets fill
-- the aura's limit.
local function clear_trees(p)
  destroy_all(surface().find_entities_filtered({ type = "tree", position = p, radius = 5 }))
end

-- A biter of a force that stands still, for the aura tests.
local function still_biter(position, force, name)
  local biter = surface().create_entity({
    name = name or "medium-biter",
    position = position,
    force = force,
  })
  biter.disabled_by_script = true
  return biter
end

test("a poison aura hurts natives, trees and players, and spares its pack", function()
  few_trails()
  with_entry({ 5200, 4000 }, "ao-biter-larva-poison", function(entry)
    local p = entry.unit.position
    clear_trees(p)
    local native = still_biter({ p.x + 2, p.y }, "enemy")
    local tree = surface().create_entity({ name = "tree-01", position = { p.x, p.y + 2 } })
    assert(tree, "no tree")
    local player = Helpers.character(surface(), { p.x, p.y - 2 })
    local packmate = still_biter({ p.x - 2, p.y }, Names.TAMED)
    local chest = Helpers.chest(surface(), { p.x + 1.5, p.y + 1.5 })
    after_ticks(2 * Balance.acid_trail_ticks, function()
      local result = {
        native = hurt(native),
        tree = hurt(tree),
        player = hurt(player),
        packmate = hurt(packmate),
        chest = hurt(chest),
        self = hurt(entry.unit),
      }
      destroy_all({ native, tree, player, packmate, chest, entry.unit })
      assert(result.native, "the aura spared the native")
      assert(result.tree, "the aura spared the tree")
      assert(result.player, "the aura spared the player's character")
      assert(not result.packmate, "the aura hurt a tamed packmate")
      assert(not result.chest, "the aura hurt a chest")
      assert(not result.self, "the aura hurt its own monster")
    end)
  end)
end)

test("a poison aura does not reach 5 tiles", function()
  few_trails()
  with_entry({ 5280, 4000 }, "ao-biter-larva-poison", function(entry)
    local p = entry.unit.position
    local native = still_biter({ p.x + 5, p.y }, "enemy")
    local near = still_biter({ p.x - 2, p.y }, "enemy")
    after_ticks(2 * Balance.acid_trail_ticks, function()
      local native_hurt, near_hurt = hurt(native), hurt(near)
      destroy_all({ native, near, entry.unit })
      assert(near_hurt, "the aura hit nothing, so the test proves nothing")
      assert(not native_hurt, "the aura reached 5 tiles")
    end)
  end)
end)

test("a feral poison aura hurts tamed monsters and spares feral ones", function()
  few_trails()
  with_entry({ 5360, 4000 }, "ao-biter-larva-poison", function(entry)
    FeralShell.go_feral(entry, game.tick)
    entry.unit.disabled_by_script = true
    local p = entry.unit.position
    local tamed = still_biter({ p.x + 2, p.y }, Names.TAMED)
    local feral = still_biter({ p.x - 2, p.y }, Names.FERAL)
    after_ticks(2 * Balance.acid_trail_ticks, function()
      local tamed_hurt, feral_hurt = hurt(tamed), hurt(feral)
      destroy_all({ tamed, feral, entry.unit })
      assert(tamed_hurt, "the feral aura spared a tamed monster")
      assert(not feral_hurt, "the feral aura hurt a feral monster")
    end)
  end)
end)

test("a hit with spare_force spares that force and hurts the others", function()
  local p = { x = 5440, y = 4000 }
  Helpers.arena(surface(), { p.x, p.y })
  local native = still_biter({ p.x + 1, p.y }, "enemy")
  local tamed = still_biter({ p.x - 1, p.y }, Names.TAMED)
  Damage.hit({
    surface = surface(),
    position = p,
    radius = 3,
    payload = "poison",
    damage = 3,
    force = Names.TAMED,
    spare_force = Names.TAMED,
  })
  local native_hurt, tamed_hurt = hurt(native), hurt(tamed)
  destroy_all({ native, tamed })
  assert(native_hurt, "spare_force spared the native")
  assert(not tamed_hurt, "spare_force hurt its own force")
end)

test("a hit with a limit damages at most that many targets", function()
  local p = { x = 5520, y = 4000 }
  Helpers.arena(surface(), { p.x, p.y })
  clear_trees(p)
  local trees = {}
  for i = -2, 2 do
    trees[#trees + 1] = surface().create_entity({ name = "tree-01", position = { p.x + i, p.y } })
  end
  assert(#trees == 5, #trees .. " trees")
  local _, dealt = Damage.hit({
    surface = surface(),
    position = p,
    radius = 3,
    payload = "poison",
    damage = 1,
    force = Names.TAMED,
    limit = 2,
  })
  destroy_all(trees)
  assert(dealt == 2, dealt .. " targets hit, not 2")
end)

test("a poison aura still hits when another mod removed its puff", function()
  with_entry({ 5600, 4000 }, "ao-biter-larva-poison", function(entry)
    local p = entry.unit.position
    local native = still_biter({ p.x + 2, p.y }, "enemy")
    destroy_all(surface().find_entities_filtered({ name = Names.PUFF, position = p, radius = 3 }))
    local ok, err = pcall(wrapped, Damage, "entity_exists", function(original)
      return function(name)
        return name ~= Names.PUFF and original(name)
      end
    end, function()
      Damage.live(entry, Names.TAMED)
    end)
    local puffs = surface().count_entities_filtered({ name = Names.PUFF, position = p, radius = 3 })
    local native_hurt = hurt(native)
    destroy_all({ native, entry.unit })
    assert(ok, err)
    assert(puffs == 0, puffs .. " puffs")
    assert(native_hurt, "the aura spared the native")
  end)
end)

test("a poison monster missing from the trail list returns on a configuration change", function()
  with_entry({ 5680, 4000 }, "ao-biter-larva-poison", function(entry)
    local id = entry.unit.unit_number
    storage.trails[id] = nil
    Setup.on_configuration_changed()
    local listed = storage.trails[id] ~= nil
    destroy_all({ entry.unit })
    assert(listed, "the rebuild did not list the poison monster")
  end)
end)

test("a hit spares its own force before its limit counts", function()
  local p = { x = 5760, y = 4000 }
  Helpers.arena(surface(), { p.x, p.y })
  clear_trees(p)
  local pack = {}
  for i = 0, 24 do
    pack[#pack + 1] = still_biter({ p.x - 2 + i % 5, p.y - 2 + math.floor(i / 5) }, Names.TAMED)
  end
  local native = still_biter({ p.x, p.y + 2.8 }, "enemy")
  Damage.hit({
    surface = surface(),
    position = p,
    radius = 3,
    payload = "poison",
    damage = 3,
    force = Names.TAMED,
    spare_force = Names.TAMED,
    limit = 20,
  })
  local native_hurt = hurt(native)
  destroy_all(pack)
  destroy_all({ native })
  assert(#pack == 25, #pack .. " pack monsters")
  assert(native_hurt, "the spared pack filled the limit and the native was not hit")
end)

test("a poison aura hits at most its max_targets", function()
  with_entry({ 5840, 4000 }, "ao-biter-larva-poison", function(entry)
    local p = entry.unit.position
    clear_trees(p)
    local trees = {}
    for dx = -2, 2 do
      for dy = -2, 2 do
        if dx ~= 0 or dy ~= 0 then
          trees[#trees + 1] =
            surface().create_entity({ name = "tree-01", position = { p.x + dx, p.y + dy } })
        end
      end
    end
    Damage.live(entry, Names.TAMED)
    local hit = 0
    for _, tree in pairs(trees) do
      if hurt(tree) then
        hit = hit + 1
      end
    end
    destroy_all(trees)
    destroy_all({ entry.unit })
    assert(#trees > Balance.payload_damage.aura.max_targets, #trees .. " trees")
    assert(hit <= Balance.payload_damage.aura.max_targets, hit .. " trees hit")
  end)
end)

-- A loaded monster that stands still, registered with its payloads for
-- the death tests. The caller unregisters it with forget().
local function kin_biter(position, force, payloads, name)
  local biter = still_biter(position, force, name)
  storage.loaded[biter.unit_number] = { unit = biter, payloads = payloads, test = true }
  return biter
end

-- Removes every entry that kin_biter registered, even for a unit that
-- died, and destroys the biters.
local function forget(biters)
  for id, entry in pairs(storage.loaded) do
    if entry.test then
      storage.loaded[id] = nil
    end
  end
  destroy_all(biters)
end

-- Ends the hazards near p now and removes the look-alikes near it.
local function clear_death(p, payload)
  for _, id in ipairs(hazards_at(p, payload)) do
    storage.hazards[id].end_tick = game.tick
    storage.hazards[id].last_hit = game.tick
  end
  destroy_all(surface().find_entities_filtered({
    name = { Names.CLOUD, Names.POOL },
    position = p,
    radius = 8,
  }))
end

test("a death effect spares pack monsters with the same payload and hurts the rest", function()
  local p = { 6000, 4000 }
  Helpers.arena(surface(), p, 20)
  clear_trees(p)
  local same = kin_biter({ p[1] + 1.5, p[2] }, Names.TAMED, { "acid", "poison" })
  local other = kin_biter({ p[1] - 1.5, p[2] }, Names.TAMED, { "acid" })
  local plain = still_biter({ p[1], p[2] + 1.5 }, Names.TAMED)
  local native = still_biter({ p[1], p[2] - 1.5 }, "enemy")
  Damage.detonate({
    surface = surface().index,
    position = { x = p[1], y = p[2] },
    payload = "poison",
    force = Names.TAMED,
  })
  Damage.run_hazards(game.tick)
  local result =
    { same = hurt(same), other = hurt(other), plain = hurt(plain), native = hurt(native) }
  clear_death({ x = p[1], y = p[2] }, "poison")
  forget({ same, other, plain, native })
  assert(not result.same, "the death hurt a pack monster with the same payload")
  assert(result.other, "the death spared a pack monster with another payload")
  assert(result.plain, "the death spared a plain tamed monster")
  assert(result.native, "the death spared the native")
end)

test("a death effect hurts a monster with the same payload on another side", function()
  local p = { 6040, 4000 }
  Helpers.arena(surface(), p, 20)
  clear_trees(p)
  local tamed = kin_biter({ p[1] + 1.5, p[2] }, Names.TAMED, { "poison" })
  local feral = kin_biter({ p[1] - 1.5, p[2] }, Names.FERAL, { "poison" })
  Damage.detonate({
    surface = surface().index,
    position = { x = p[1], y = p[2] },
    payload = "poison",
    force = Names.FERAL,
  })
  Damage.run_hazards(game.tick)
  local tamed_hurt, feral_hurt = hurt(tamed), hurt(feral)
  clear_death({ x = p[1], y = p[2] }, "poison")
  forget({ tamed, feral })
  assert(tamed_hurt, "a feral death spared a tamed poison monster")
  assert(not feral_hurt, "a feral death hurt a feral poison monster")
end)

test("a death pool spares pack monsters with the same payload on each visit", function()
  local p = { 6080, 4000 }
  Helpers.arena(surface(), p, 20)
  clear_trees(p)
  Damage.detonate({
    surface = surface().index,
    position = { x = p[1], y = p[2] },
    payload = "acid",
    force = Names.TAMED,
  })
  -- Placed after the death, so only the pool's own hits can reach them.
  local same = kin_biter({ p[1] + 1, p[2] }, Names.TAMED, { "acid" })
  local other = kin_biter({ p[1] - 1, p[2] }, Names.TAMED, { "poison" })
  Damage.run_hazards(game.tick + Balance.payload_damage.hazard_interval)
  local same_hurt, other_hurt = hurt(same), hurt(other)
  clear_death({ x = p[1], y = p[2] }, "acid")
  forget({ same, other })
  assert(other_hurt, "the pool spared a pack monster with another payload")
  assert(not same_hurt, "the pool hurt a pack monster with the same payload")
end)

test("an explosive death spares pack monsters with the same payload", function()
  local p = { 6120, 4000 }
  Helpers.arena(surface(), p, 20)
  clear_trees(p)
  -- Big biters survive the blast, so no death of theirs sets anything off.
  local same = kin_biter({ p[1] + 1.5, p[2] }, Names.TAMED, { "explosive" }, "big-biter")
  local other = kin_biter({ p[1] - 1.5, p[2] }, Names.TAMED, { "poison" }, "big-biter")
  Damage.detonate({
    surface = surface().index,
    position = { x = p[1], y = p[2] },
    payload = "explosive",
    force = Names.TAMED,
  })
  local same_hurt, other_hurt = hurt(same), hurt(other)
  local alive = same.valid and other.valid
  forget({ same, other })
  assert(alive, "precondition: a big biter died in the blast")
  assert(other_hurt, "the explosion spared a pack monster with another payload")
  assert(not same_hurt, "the explosion hurt a pack monster with the same payload")
end)
