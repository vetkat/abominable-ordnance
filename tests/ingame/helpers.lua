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

-- Gives the player force Monster husbandry, or takes it away.
function Helpers.research(done)
  game.forces["player"].technologies[Names.TECH].researched = done
end

-- A breeding pod with power from an electric energy interface. The
-- force gets Monster husbandry, so it can use the pod's recipes.
function Helpers.powered_pod(surface, position)
  local x, y = position[1], position[2]
  Helpers.research(true)
  local pod = surface.create_entity({
    name = "ao-breeding-pod",
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
  return pod
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
