local Helpers = require("__abominable-ordnance__/tests/ingame/helpers")
local Species = require("core.species")

local BITER = Species.ALL[1]

local surface = function()
  return game.surfaces[1]
end

local function eggs_near(position)
  return Helpers.count_items(surface(), position, BITER.egg)
end

local function spawner(position)
  Helpers.arena(surface(), position)
  return surface().create_entity({
    name = BITER.spawner,
    position = position,
    force = "enemy",
  })
end

test("a spawner killed after the research drops 1 to 3 eggs", function()
  Helpers.research(true)
  local position = { 600, 600 }
  spawner(position).die(game.forces["player"])
  local n = eggs_near(position)
  assert(n >= 1 and n <= 3, "dropped " .. n .. " eggs")
end)

test("a spawner killed before the research drops none", function()
  Helpers.research(false)
  local position = { 620, 600 }
  spawner(position).die(game.forces["player"])
  assert(eggs_near(position) == 0, "eggs dropped before the research")
end)

test("a spawner that dies with no force drops none", function()
  Helpers.research(true)
  local position = { 640, 600 }
  spawner(position).die()
  assert(eggs_near(position) == 0, "eggs dropped with no killer force")
end)

test("a spawner drops its eggs beside its corpse, with a label", function()
  Helpers.research(true)
  local position = { 660, 600 }
  spawner(position).die(game.forces["player"])
  local under = surface().find_entities_filtered({
    name = "item-on-ground",
    area = { { 657.5, 597.5 }, { 662.5, 602.5 } },
  })
  assert(#under == 0, "eggs dropped under the corpse")
  assert(eggs_near(position) >= 1, "no eggs dropped")
  local texts = 0
  for _, object in pairs(rendering.get_all_objects("abominable-ordnance")) do
    if object.type == "text" then
      texts = texts + 1
    end
  end
  assert(texts >= 1, "no label")
end)
