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
-- within radius tiles (24 by default), so that native nests cannot
-- change a count. A firing test passes 96, the area that
-- Helpers.launcher charts.
function Helpers.arena(surface, position, radius)
  radius = radius or 24
  surface.request_to_generate_chunks(position, math.ceil(radius / 32))
  surface.force_generate_chunk_requests()
  for _, entity in
    pairs(surface.find_entities_filtered({
      area = area(position, radius),
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

-- A steel chest of the player force at a position.
function Helpers.chest(surface, position)
  return surface.create_entity({
    name = "steel-chest",
    position = position,
    force = "player",
  })
end

-- A character of a force at a position.
function Helpers.character(surface, position, force)
  return surface.create_entity({
    name = "character",
    position = position,
    force = force or "player",
  })
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

-- The units of some names, or of a force, near a position.
function Helpers.find_units(surface, position, filter)
  filter.area = area(position, 12)
  filter.type = "unit"
  return surface.find_entities_filtered(filter)
end

function Helpers.count_units(surface, position, names)
  return #Helpers.find_units(surface, position, { name = names, force = "enemy" })
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

-- An artillery turret of the player force with some ammo, at a
-- position. The force sees the area, because artillery only fires on
-- its own at what the force can see. The chart covers only 96 tiles
-- around the turret. The test clears the enemies of that area first
-- with Helpers.arena(surface, position, 96). The force (default
-- "player") and the quality (the game's default) are optional.
function Helpers.launcher(surface, position, name, ammo, force, quality)
  force = force or "player"
  local turret = surface.create_entity({
    name = name,
    position = position,
    force = force,
    quality = quality,
  })
  if ammo then
    turret.insert(ammo)
  end
  game.forces[force].chart(surface, area(position, 96))
  return turret
end

-- The number of items left in an artillery turret.
function Helpers.ammo(turret)
  return turret.get_inventory(defines.inventory.artillery_turret_ammo).get_item_count()
end

return Helpers
