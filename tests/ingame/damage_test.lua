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

test("the first of two explosive monsters kills the second through the queue", function()
  local position = { 4100, 4000 }
  Helpers.arena(surface(), position, 40)
  game.forces["enemy"].set_evolution_factor(0, surface())
  Helpers.spoil(Helpers.spill(surface(), position, "ao-biter-larva-explosive", 1))
  Helpers.spoil(
    Helpers.spill(surface(), { position[1] + 2.5, position[2] }, "ao-biter-larva-explosive", 1)
  )
  after_ticks(1, function()
    local units = Helpers.find_units(surface(), position, { force = Names.TAMED })
    assert(#units == 2, #units .. " tamed units")
    table.sort(units, function(a, b)
      return a.position.x < b.position.x
    end)
    local first, second = units[1], units[2]
    first.disabled_by_script = true
    second.disabled_by_script = true
    -- Only the second death reaches the chest.
    local chest = Helpers.chest(surface(), { second.position.x + 3, second.position.y })
    local radius = Balance.payload_damage.explosive.radius
    local out_of_reach = distance(first.position, chest.position) > radius
    local in_reach = distance(first.position, second.position) <= radius
    if not (out_of_reach and in_reach) then
      destroy_all({ first, second, chest })
      assert(out_of_reach, "precondition: the chest is within reach of the first")
      assert(in_reach, "precondition: the second is beyond reach of the first")
    end
    local ids = { first.unit_number, second.unit_number }
    local counter = storage.detonation_counter
    first.die()
    -- The death only queued its detonation, and no tick passed.
    local second_alive = second.valid
    local queued = storage.detonation_counter > counter
    after_ticks(3, function()
      local second_gone = not second.valid
      local chest_hurt = hurt(chest)
      local queue_empty = next(storage.detonations) == nil
      local entries_left = storage.loaded[ids[1]] ~= nil or storage.loaded[ids[2]] ~= nil
      destroy_all({ chest, second })
      assert(second_alive, "the first death killed the second inside its own event")
      assert(queued, "the first death left nothing in the queue")
      assert(second_gone, "the first death did not kill the second monster")
      assert(chest_hurt, "the second death did not run")
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
      for _, id in ipairs(ids) do
        storage.hazards[id] = nil
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
  after_ticks(1, function()
    -- More hazards than hazard_hits are due, so the pass stops part way.
    assert(storage.hazard_cursor ~= nil, "the hit budget did not stop the pass")
  end)
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
  local ok, r = pcall(without, HAZARD_FIELDS, function()
    storage.hazards, storage.hazard_counter = {}, 0
    local chests, ids, before = {}, {}, {}
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
    for _, pair in ipairs(chests) do
      destroy_all(pair)
    end
    return out
  end)
  d.hazard_targets = budget
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
