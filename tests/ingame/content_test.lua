local Helpers = require("__abominable-ordnance__/tests/ingame/helpers")

local Names = require("core.names")
local Species = require("core.species")

test("the items, pod, recipes and research exist", function()
  local items = { Names.MONSTER_CHOW, Names.SPITTER_CHOW, Names.POD }
  local recipes = { Names.MONSTER_CHOW, Names.SPITTER_CHOW, Names.POD }
  for _, species in ipairs(Species.ALL) do
    items[#items + 1] = species.egg
    recipes[#recipes + 1] = "ao-breed-" .. species.name
  end
  for _, name in ipairs(items) do
    assert(prototypes.item[name], name)
  end
  for _, name in ipairs(recipes) do
    assert(prototypes.recipe[name], name)
  end
  assert(prototypes.entity[Names.POD], Names.POD)
  assert(prototypes.technology[Names.TECH], Names.TECH)
end)

test("a breeding pod makes 2 eggs from 1 egg and 5 chow", function()
  Helpers.arena(game.surfaces[1], { 400, 400 })
  local pod = Helpers.powered_pod(game.surfaces[1], { 400, 400 })
  pod.set_recipe("ao-breed-biter")
  pod.insert({ name = "ao-biter-egg", count = 1 })
  pod.insert({ name = "ao-monster-chow", count = 5 })
  after_ticks(1000, function()
    assert(
      pod.get_output_inventory().get_item_count("ao-biter-egg") == 2,
      "the pod did not make 2 eggs"
    )
  end)
end)

tags("space-age")
test("the adopt recipe turns a biter-egg into a mod egg", function()
  Helpers.arena(game.surfaces[1], { 420, 400 })
  local pod = Helpers.powered_pod(game.surfaces[1], { 420, 400 })
  pod.set_recipe("ao-adopt-biter-egg")
  pod.insert({ name = "biter-egg", count = 1 })
  pod.insert({ name = "ao-monster-chow", count = 1 })
  after_ticks(400, function()
    assert(
      pod.get_output_inventory().get_item_count("ao-biter-egg") == 1,
      "the pod did not adopt the egg"
    )
  end)
end)
