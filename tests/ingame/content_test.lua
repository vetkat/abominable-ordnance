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

test("an incubator makes 1 larva from 10 eggs", function()
  Helpers.arena(game.surfaces[1], { 440, 400 })
  local incubator = Helpers.powered_machine(game.surfaces[1], { 440, 400 }, Names.INCUBATOR)
  incubator.set_recipe("ao-incubate-biter")
  incubator.insert({ name = "ao-biter-egg", count = 10 })
  after_ticks(900, function()
    assert(
      incubator.get_output_inventory().get_item_count("ao-biter-larva") == 1,
      "the incubator did not make a larva"
    )
  end)
end)

test("a loading chamber loads a larva with an explosive rocket", function()
  Helpers.arena(game.surfaces[1], { 460, 400 })
  local chamber = Helpers.powered_machine(game.surfaces[1], { 460, 400 }, Names.CHAMBER)
  Helpers.research(true, Names.ORDNANCE_TECH)
  chamber.set_recipe("ao-load-biter-explosive")
  chamber.insert({ name = "ao-biter-larva", count = 1 })
  chamber.insert({ name = "explosive-rocket", count = 1 })
  chamber.insert({ name = Names.CASING, count = 1 })
  after_ticks(600, function()
    assert(
      chamber.get_output_inventory().get_item_count("ao-biter-larva-explosive") == 1,
      "the chamber did not load the larva"
    )
  end)
end)

test("the machines have their new footprints", function()
  assert(prototypes.entity[Names.POD].tile_width == 5, "the pod is not 5 tiles wide")
  assert(prototypes.entity[Names.POD].tile_height == 5, "the pod is not 5 tiles high")
  for _, name in ipairs({ Names.INCUBATOR, Names.CHAMBER }) do
    assert(prototypes.entity[name].tile_width == 4, name .. " is not 4 tiles wide")
    assert(prototypes.entity[name].tile_height == 4, name .. " is not 4 tiles high")
  end
  assert(prototypes.entity["ao-loading-chamber-remnants"], "the chamber has no remnants")
end)

test("the mod's buildings stay off Aquilo and space platforms", function()
  local space_travel = script.feature_flags["space_travel"]
  for _, name in ipairs({ Names.POD, Names.INCUBATOR, Names.CHAMBER, Names.LAUNCHER }) do
    local min
    for _, c in pairs(prototypes.entity[name].surface_conditions or {}) do
      if c.property == "pressure" then
        min = c.min
      end
    end
    if space_travel then
      assert(min == 400, name .. " lacks the pressure rule")
    else
      assert(min == nil, name .. " has a pressure rule without space travel")
    end
  end
  if game.planets["aquilo"] then
    local pressure = game.planets["aquilo"].prototype.surface_properties["pressure"]
    assert(pressure < 400, "Aquilo has pressure " .. pressure)
  end
end)
