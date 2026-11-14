-- Shared set-up for the in-game tests.
local Names = require("core.names")

local Helpers = {}

function Helpers.spoil(stack)
  stack.spoil()
end

local function area(position, radius)
  local x, y = position[1], position[2]
  return { { x - radius, y - radius }, { x + radius, y + radius } }
end

-- Generates the chunks around a test position and removes every enemy
-- there, so that native nests cannot change a count.
function Helpers.arena(surface, position)
  surface.request_to_generate_chunks(position, 1)
  surface.force_generate_chunk_requests()
  for _, entity in
    pairs(surface.find_entities_filtered({
      area = area(position, 24),
      force = "enemy",
    }))
  do
    entity.destroy()
  end
end

-- Gives the player force a technology, or takes it away. The default is
-- Monster husbandry.
function Helpers.research(done, tech)
  game.forces["player"].technologies[tech or Names.TECH].researched = done
end

-- A machine with power from an electric energy interface. The force
-- gets Monster husbandry, so it can use the mod's recipes.
function Helpers.powered_machine(surface, position, name)
  local x, y = position[1], position[2]
  Helpers.research(true)
  local machine = surface.create_entity({
    name = name,
    position = { x, y },
    force = "player",
  })
  surface.create_entity({
    name = "small-electric-pole",
    position = { x + 2.5, y },
    force = "player",
  })
  surface.create_entity({
    name = "electric-energy-interface",
    position = { x + 4.5, y },
    force = "player",
  })
  return machine
end

function Helpers.powered_pod(surface, position)
  return Helpers.powered_machine(surface, position, Names.POD)
end

-- Spills a stack on the ground as one pile and returns the pile's stack.
function Helpers.spill(surface, position, name, count)
  surface.spill_item_stack({
    position = position,
    stack = { name = name, count = count },
    drop_full_stack = true,
  })
  local piles = surface.find_entities_filtered({
    name = "item-on-ground",
    area = area(position, 5),
  })
  assert(#piles == 1, "the items did not land as one pile")
  return piles[1].stack
end

function Helpers.count_units(surface, position, names)
  return surface.count_entities_filtered({
    area = area(position, 12),
    name = names,
    force = "enemy",
  })
end

-- The number of items of one name on the ground near a position.
function Helpers.count_items(surface, position, name)
  local count = 0
  local items = surface.find_entities_filtered({
    area = area(position, 6),
    name = "item-on-ground",
  })
  for _, item in pairs(items) do
    if item.stack.name == name then
      count = count + item.stack.count
    end
  end
  return count
end

return Helpers
