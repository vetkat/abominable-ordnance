local Helpers = require("__abominable-ordnance__/tests/ingame/helpers")
local Names = require("core.names")
local Species = require("core.species")
local Tamed = require("shell.tamed")

local BITER = Species.ALL[1]

local surface = function()
  return game.surfaces[1]
end

local function tamed_units(position)
  return Helpers.find_units(surface(), position, { force = Names.TAMED })
end

test("the tamed force fights the natives and spares the players", function()
  local tamed = game.forces[Names.TAMED]
  assert(tamed, "no tamed force")
  assert(not tamed.get_cease_fire("enemy"), "the tamed force spares the natives")
  assert(not game.forces["enemy"].get_cease_fire(tamed), "the natives spare the tamed force")
  assert(tamed.get_cease_fire("player"), "the tamed force attacks players")
  assert(game.forces["player"].get_cease_fire(tamed), "players attack the tamed force")
end)

test("a force made later gets cease-fire with the tamed force", function()
  local other = game.create_force("ao-test-force")
  after_ticks(1, function()
    local tamed = game.forces[Names.TAMED]
    assert(tamed.get_cease_fire(other) and other.get_cease_fire(tamed), "no cease-fire")
  end)
end)

test("the tamed force setup can run twice", function()
  Tamed.ensure()
  Tamed.ensure()
  local tamed = game.forces[Names.TAMED]
  assert(tamed.get_cease_fire("player") and not tamed.get_cease_fire("enemy"))
end)

test("a loaded larva that spoils in a character's inventory becomes a loaded monster", function()
  local position = { 700, 700 }
  Helpers.arena(surface(), position)
  local character =
    surface().create_entity({ name = "character", position = position, force = "player" })
  character.insert({ name = "ao-biter-larva-explosive", count = 1 })
  Helpers.spoil(character.get_main_inventory()[1])
  after_ticks(2, function()
    local units = tamed_units(position)
    assert(#units == 1, #units .. " tamed units")
    local entry = storage.loaded[units[1].unit_number]
    assert(entry and entry.payloads[1] == "explosive", "no loaded entry")
  end)
end)

test("a loaded monster attacks a nearby spawner", function()
  local position = { 740, 700 }
  Helpers.arena(surface(), position)
  local spawner = surface().create_entity({
    name = BITER.spawner,
    position = { position[1] + 10, position[2] },
    force = "enemy",
  })
  -- A working spawner sends defenders, which kill one small monster fast.
  spawner.disabled_by_script = true
  Helpers.spoil(Helpers.spill(surface(), position, "ao-biter-larva-poison", 1))
  after_ticks(20 * 60, function()
    assert(not spawner.valid or spawner.health < spawner.max_health, "the spawner is untouched")
  end)
end)

-- Hatches a loaded monster at a position and passes it to then(unit) a
-- tick later.
local function with_loaded_monster(position, item, after)
  Helpers.arena(surface(), position)
  Helpers.spoil(Helpers.spill(surface(), position, item, 1))
  after_ticks(1, function()
    after(tamed_units(position)[1])
  end)
end

test("an explosive monster that dies blows up the natives' chest", function()
  local position = { 780, 700 }
  local chest
  with_loaded_monster(position, "ao-biter-larva-explosive", function(unit)
    chest = surface().create_entity({
      name = "wooden-chest",
      position = { unit.position.x + 1.5, unit.position.y },
      force = "enemy",
    })
    local number = unit.unit_number
    unit.die()
    after_ticks(2, function()
      assert(not chest.valid or chest.health < chest.max_health, "the chest is untouched")
      assert(storage.loaded[number] == nil, "the loaded entry is still there")
    end)
  end)
end)

test("a poison monster that dies poisons a native biter", function()
  local position = { 820, 700 }
  local foe
  with_loaded_monster(position, "ao-biter-larva-poison", function(unit)
    foe = surface().create_entity({
      name = "medium-biter",
      position = { unit.position.x + 1.5, unit.position.y },
      force = "enemy",
    })
    foe.disabled_by_script = true
    unit.die()
    after_ticks(120, function()
      assert(not foe.valid or foe.health < foe.max_health, "the biter is untouched")
    end)
  end)
end)

test("a loaded monster removed without dying loses its entry", function()
  with_loaded_monster({ 860, 700 }, "ao-biter-larva-acid", function(unit)
    local number = unit.unit_number
    unit.destroy()
    after_ticks(1, function()
      assert(storage.loaded[number] == nil, "the loaded entry is still there")
    end)
  end)
end)

test("a native biter that dies sets off nothing", function()
  local position = { 900, 700 }
  Helpers.arena(surface(), position)
  local biter =
    surface().create_entity({ name = "small-biter", position = position, force = "enemy" })
  biter.die()
  local effects = surface().count_entities_filtered({
    position = position,
    radius = 6,
    name = { "explosive-rocket", "poison-cloud", "acid-splash-fire-spitter-big" },
  })
  assert(effects == 0, effects .. " effects")
end)

test("an acid monster leaves an acid trail", function()
  with_loaded_monster({ 940, 700 }, "ao-biter-larva-acid", function(unit)
    unit.disabled_by_script = true
    after_ticks(90, function()
      local puddles = surface().count_entities_filtered({
        position = unit.position,
        radius = 2,
        name = "acid-splash-fire-spitter-small",
      })
      assert(puddles >= 1, "no acid trail")
    end)
  end)
end)
