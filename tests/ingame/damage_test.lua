local Balance = require("core.balance")
local Damage = require("shell.damage")
local FeralShell = require("shell.feral")
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
    assert(class == thing[2], thing[1] .. " is " .. class)
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

test("a hit spares the entity it is told to skip", function()
  local position = { 4040, 4000 }
  Helpers.arena(surface(), position)
  local native = surface().create_entity({
    name = "medium-biter",
    position = position,
    force = "enemy",
  })
  native.disabled_by_script = true
  Damage.hit({
    surface = surface(),
    position = native.position,
    radius = 2,
    payload = "acid",
    damage = 10,
    force = "ao-tamed",
    skip = native,
  })
  local whole = native.health == native.max_health
  native.destroy()
  assert(whole, "the skipped native is hurt")
end)

test("a hit still hurts a force's own chest when that force has friendly fire off", function()
  local position = { 4060, 3960 }
  Helpers.arena(surface(), position)
  local player = game.forces["player"]
  local chest = Helpers.chest(surface(), { position[1] + 1, position[2] })
  local old = player.friendly_fire
  player.friendly_fire = false
  Damage.hit({
    surface = surface(),
    position = { x = position[1], y = position[2] },
    radius = 3,
    payload = "explosive",
    damage = 10,
    force = "player",
  })
  player.friendly_fire = old
  local was_hurt = chest.health < chest.max_health
  chest.destroy()
  assert(was_hurt, "the chest is untouched")
end)

local function hurt(entity)
  return not entity.valid or entity.health < entity.max_health
end

local function distance(a, b)
  local dx, dy = a.x - b.x, a.y - b.y
  return math.sqrt(dx * dx + dy * dy)
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
    entry.unit.die()
    after_ticks(2, function()
      local first = {}
      for name, entity in pairs(targets) do
        first[name] = hurt(entity)
      end
      local chest_health = targets.chest.valid and targets.chest.health
      after_ticks(60, function()
        local once = targets.chest.valid and targets.chest.health == chest_health
        for _, entity in pairs(targets) do
          if entity.valid then
            entity.destroy()
          end
        end
        for name in pairs(targets) do
          assert(first[name], name .. " is untouched")
        end
        assert(once, "the chest took a second hit")
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
    assert(
      distance(first.position, chest.position) > radius,
      "precondition: the chest is within reach of the first"
    )
    assert(
      distance(first.position, second.position) <= radius,
      "precondition: the second is beyond reach of the first"
    )
    local ids = { first.unit_number, second.unit_number }
    first.die()
    after_ticks(3, function()
      local second_gone = not second.valid
      local chest_hurt = hurt(chest)
      local queue_empty = next(storage.detonations) == nil
      local entries_left = storage.loaded[ids[1]] ~= nil or storage.loaded[ids[2]] ~= nil
      if chest.valid then
        chest.destroy()
      end
      if second.valid then
        second.destroy()
      end
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
    Damage.queue(surface(), { x = position[1], y = position[2] }, { "explosive" }, gone.name)
    game.merge_forces(gone, "player")
    after_ticks(3, function()
      local whole = chest.valid and chest.health == chest.max_health
      local empty = next(storage.detonations) == nil
      chest.destroy()
      assert(whole, "the chest took damage from a gone force")
      assert(empty, "the detonation is still in the queue")
    end)
  end
)

test("a feral monster's explosive death kills a nest and drops no eggs", function()
  with_entry({ 4180, 4000 }, "ao-biter-larva-explosive", function(entry)
    FeralShell.go_feral(entry, game.tick)
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
      if spawner.valid then
        spawner.destroy()
      end
      assert(dead, "the nest survived")
      assert(eggs == 0, eggs .. " eggs dropped")
    end)
  end)
end)

test("a configuration change creates the queue", function()
  local detonations, counter = storage.detonations, storage.detonation_counter
  storage.detonations = nil
  storage.detonation_counter = nil
  Setup.on_configuration_changed()
  local created = storage.detonations ~= nil and storage.detonation_counter == 0
  storage.detonations, storage.detonation_counter = detonations, counter
  assert(created, "the queue is missing after a configuration change")
end)
