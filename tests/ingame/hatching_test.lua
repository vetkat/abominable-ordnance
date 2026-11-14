local Helpers = require("__abominable-ordnance__/tests/ingame/helpers")
local Species = require("core.species")

local BITER, SPITTER = Species.ALL[1], Species.ALL[2]

local function unit_names(species)
  local names = {}
  for _, unit in ipairs(species.units) do
    names[#names + 1] = unit[1]
  end
  return names
end

local surface = function()
  return game.surfaces[1]
end

before_each(function()
  game.forces["enemy"].set_evolution_factor(0, surface())
end)

test("every hatch unit exists", function()
  for _, species in ipairs(Species.ALL) do
    for _, name in ipairs(unit_names(species)) do
      assert(prototypes.entity[name], name)
    end
  end
end)

test("10 spitter eggs in a chest hatch one spitter at evolution 0", function()
  local position = { 500, 500 }
  Helpers.arena(surface(), position)
  local chest = surface().create_entity({
    name = "steel-chest",
    position = position,
    force = "player",
  })
  chest.insert({ name = SPITTER.egg, count = 10 })
  Helpers.spoil(chest.get_inventory(defines.inventory.chest)[1])
  after_ticks(2, function()
    local spitters = Helpers.count_units(surface(), position, unit_names(SPITTER))
    local biters = Helpers.count_units(surface(), position, unit_names(BITER))
    assert(spitters == 1, "no spitter hatched")
    assert(biters == 0, "a biter hatched from spitter eggs")
  end)
end)

test("10 biter eggs on the ground hatch one biter", function()
  local position = { 540, 500 }
  Helpers.arena(surface(), position)
  surface().spill_item_stack({
    position = position,
    stack = { name = BITER.egg, count = 10 },
    drop_full_stack = true,
  })
  local items = surface().find_entities_filtered({
    name = "item-on-ground",
    area = { { 535, 495 }, { 545, 505 } },
  })
  assert(#items == 1, "the eggs did not land as one stack")
  Helpers.spoil(items[1].stack)
  after_ticks(2, function()
    local biters = Helpers.count_units(surface(), position, unit_names(BITER))
    assert(biters == 1, "no biter hatched on the ground")
  end)
end)

test("a hatched biter attacks a building near the hatch spot", function()
  local position = { 580, 500 }
  Helpers.arena(surface(), position)
  local target = surface().create_entity({
    name = "wooden-chest",
    position = { position[1] + 12, position[2] },
    force = "player",
  })
  surface().spill_item_stack({
    position = position,
    stack = { name = BITER.egg, count = 10 },
    drop_full_stack = true,
  })
  local items = surface().find_entities_filtered({
    name = "item-on-ground",
    area = { { 575, 495 }, { 585, 505 } },
  })
  Helpers.spoil(items[1].stack)
  after_ticks(20 * 60, function()
    assert(not target.valid or target.health < target.max_health, "the biter left the chest alone")
  end)
end)

test("a spoiled larva hatches one wild biter", function()
  local position = { 620, 540 }
  Helpers.arena(surface(), position)
  surface().spill_item_stack({
    position = position,
    stack = { name = BITER.larva, count = 1 },
    drop_full_stack = true,
  })
  local items = surface().find_entities_filtered({
    name = "item-on-ground",
    area = { { 615, 535 }, { 625, 545 } },
  })
  Helpers.spoil(items[1].stack)
  after_ticks(2, function()
    local biters = Helpers.count_units(surface(), position, unit_names(BITER))
    assert(biters == 1, "the larva hatched " .. biters .. " biters")
  end)
end)
