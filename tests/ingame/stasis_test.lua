local Helpers = require("__abominable-ordnance__/tests/ingame/helpers")
local Names = require("core.names")
local Species = require("core.species")
local Stasis = require("core.prototypes.stasis")

local BITER = Species.ALL[1]
local ROCKET = "ao-biter-larva-explosive"
local WARDED_ROCKET = "ao-warded-biter-larva-explosive"

local surface = function()
  return game.surfaces[1]
end

local function unit_names(species)
  local names = {}
  for _, unit in ipairs(species.units) do
    names[#names + 1] = unit[1]
  end
  return names
end

-- Sets a stack's spoil progress p (0 to 1). spoil_tick is an absolute
-- game tick, so the test sets it right after the insert.
local function set_progress(stack, p)
  local total = prototypes.item[stack.name].get_spoil_ticks(stack.quality)
  stack.spoil_tick = game.tick + math.ceil((1 - p) * total)
end

local function near(a, b)
  return math.abs(a - b) <= 0.02
end

-- An assembler with power that runs one recipe, with its input filled.
-- The optional modules go in before the recipe, because a recipe that
-- allows no quality refuses a quality module. The insert must take all.
local function assembler(position, recipe, inputs, quality, name, modules)
  Helpers.arena(surface(), position)
  Helpers.research(true, Names.STASIS_TECH)
  local machine = Helpers.powered_machine(surface(), position, name or "assembling-machine-2")
  if modules then
    local inserted = machine.get_inventory(defines.inventory.crafter_modules).insert(modules)
    assert(inserted == modules.count, "inserted " .. inserted .. " modules")
  end
  machine.set_recipe(recipe, quality)
  local input = machine.get_inventory(defines.inventory.crafter_input)
  for _, stack in ipairs(inputs) do
    input.insert(stack)
  end
  return machine, input
end

local function output(machine)
  return machine.get_inventory(defines.inventory.crafter_output)
end

before_each(function()
  game.forces["enemy"].set_evolution_factor(0, surface())
end)

test("an assembler packs a rocket at 40% into a warded rocket at about 40%", function()
  local machine, input = assembler({ 2000, 500 }, "ao-ward-biter-larva-explosive", {
    { name = ROCKET, count = 1 },
    { name = Names.WARD, count = 1 },
  })
  set_progress(input.find_item_stack(ROCKET), 0.4)
  after_ticks(180, function()
    local out = output(machine)
    local stack = out.find_item_stack(WARDED_ROCKET)
    local p = stack and stack.spoil_percent
    local made = out.get_item_count(WARDED_ROCKET)
    local left = input.get_item_count(ROCKET) + input.get_item_count(Names.WARD)
    machine.destroy()
    assert(stack, "no warded rocket")
    assert(made == 1, made .. " warded rockets")
    assert(left == 0, left .. " inputs left")
    assert(near(p, 0.4), "warded rocket at " .. p)
  end)
end)

test("unpacking a warded rocket at 40% gives a rocket at about 40% and a ward", function()
  local machine, input = assembler({ 2040, 500 }, "ao-unward-biter-larva-explosive", {
    { name = WARDED_ROCKET, count = 1 },
  })
  set_progress(input.find_item_stack(WARDED_ROCKET), 0.4)
  after_ticks(180, function()
    local out = output(machine)
    local rocket = out.find_item_stack(ROCKET)
    local wards = out.get_item_count(Names.WARD)
    local p = rocket and rocket.spoil_percent
    machine.destroy()
    assert(rocket, "no rocket")
    assert(near(p, 0.4), "rocket at " .. tostring(p))
    assert(wards == 1, wards .. " wards")
  end)
end)

-- Needs quality, so it runs only with Space Age (factorio-test tag).
tags("space-age")
test("an uncommon egg and an uncommon ward pack into an uncommon warded egg", function()
  local machine = assembler({ 2080, 500 }, "ao-ward-biter-egg", {
    { name = BITER.egg, count = 1, quality = "uncommon" },
    { name = Names.WARD, count = 1, quality = "uncommon" },
  }, "uncommon")
  after_ticks(180, function()
    local stack = output(machine).find_item_stack({
      name = "ao-warded-biter-egg",
      quality = "uncommon",
    })
    machine.destroy()
    assert(stack, "no uncommon warded egg")
  end)
end)

-- Puts one egg in a steel chest. Its spoil progress leaves 60 ticks on
-- a plain egg, so a warded egg has 20 times as long left.
local function egg_in_chest(position, name)
  Helpers.arena(surface(), position)
  local chest = Helpers.chest(surface(), position)
  chest.insert({ name = name, count = 1 })
  local total = prototypes.item[BITER.egg].get_spoil_ticks()
  set_progress(chest.get_inventory(defines.inventory.chest)[1], 1 - 60 / total)
  return chest
end

test("a warded egg with 60 plain ticks left is still unspoiled 3 s later", function()
  local chest = egg_in_chest({ 2120, 500 }, "ao-warded-biter-egg")
  after_ticks(180, function()
    local count = chest.get_item_count("ao-warded-biter-egg")
    chest.destroy()
    assert(count == 1, "the warded egg spoiled")
  end)
end)

test("control: a plain egg with 60 ticks left spoils within 3 s", function()
  local chest = egg_in_chest({ 2240, 500 }, BITER.egg)
  after_ticks(180, function()
    local count = chest.get_item_count(BITER.egg)
    chest.destroy()
    assert(count == 0, "the plain egg did not spoil")
  end)
end)

test("a warded rocket that spoils hatches its loaded monster on the tamed force", function()
  local position = { 2160, 500 }
  Helpers.arena(surface(), position)
  Helpers.spoil(Helpers.spill(surface(), position, WARDED_ROCKET, 1))
  after_ticks(2, function()
    local units = Helpers.find_units(surface(), position, { force = Names.TAMED })
    assert(#units == 1, #units .. " tamed units")
    local entry = storage.loaded[units[1].unit_number]
    assert(entry and entry.payloads[1] == "explosive", "no loaded entry")
  end)
end)

test("10 warded biter eggs that spoil hatch one wild biter", function()
  local position = { 2200, 500 }
  Helpers.arena(surface(), position)
  Helpers.spoil(Helpers.spill(surface(), position, "ao-warded-biter-egg", 10))
  after_ticks(2, function()
    local biters = Helpers.count_units(surface(), position, unit_names(BITER))
    assert(biters == 1, biters .. " biters hatched")
  end)
end)

-- With four quality modules, a crafter rolls up a quality at 10% a
-- craft. Pack and unpack must not: 40 crafts, no roll. The control is a
-- machine with the same modules on a recipe that allows quality. It
-- fails the test when the force has no quality above normal.
local CRAFTS = 40

local function unlock_qualities()
  for _, quality in ipairs({ "uncommon", "rare", "epic", "legendary" }) do
    game.forces["player"].unlock_quality(quality)
  end
end

-- The item names and qualities in an inventory, as "name/quality x n".
local function contents(inventory)
  local lines = {}
  for _, item in pairs(inventory.get_contents()) do
    lines[#lines + 1] = item.name .. "/" .. item.quality .. " x" .. item.count
  end
  return table.concat(lines, ", ")
end

local function crafter(position, recipe, inputs, quality)
  return assembler(position, recipe, inputs, quality, "assembling-machine-3", {
    name = "quality-module-3",
    count = 4,
  })
end

-- An inserter and a chest below a machine, so that a product of a higher
-- quality has room: a full output stops a crafter. The chest is the
-- machine's output.
local function drain(position)
  local x, y = position[1] + 0.5, position[2] + 0.5
  surface().create_entity({
    name = "inserter",
    position = { x, y + 2 },
    direction = defines.direction.north,
    force = "player",
  })
  return Helpers.chest(surface(), { x, y + 3 })
end

tags("space-age")
test("quality modules lift no pack or unpack, but lift a plain recipe", function()
  unlock_qualities()
  local pack = crafter({ 2280, 500 }, "ao-ward-biter-egg", {
    { name = BITER.egg, count = CRAFTS },
    { name = Names.WARD, count = CRAFTS },
  })
  local unpack = crafter({ 2320, 500 }, "ao-unward-biter-egg", {
    { name = "ao-warded-biter-egg", count = CRAFTS, quality = "uncommon" },
  }, "uncommon")
  local control = crafter({ 2360, 500 }, "iron-gear-wheel", {
    { name = "iron-plate", count = 2 * CRAFTS },
  })
  local gears = drain({ 2360, 500 })
  after_ticks(60 * 45, function()
    local packed = output(pack)
    local unpacked = output(unpack)
    local chest = gears.get_inventory(defines.inventory.chest)
    local normal = packed.get_item_count({ name = "ao-warded-biter-egg", quality = "normal" })
    local eggs = unpacked.get_item_count({ name = BITER.egg, quality = "uncommon" })
    local wards = unpacked.get_item_count({ name = Names.WARD, quality = "uncommon" })
    local lifted = chest.get_item_count()
      - chest.get_item_count({ name = "iron-gear-wheel", quality = "normal" })
    local texts = { contents(packed), contents(unpacked), contents(chest) }
    for _, entity in ipairs({ pack, unpack, control, gears }) do
      entity.destroy()
    end
    assert(lifted > 0, "control: no gear above normal quality, got " .. texts[3])
    assert(normal == CRAFTS, "expected " .. CRAFTS .. " normal warded eggs, got " .. texts[1])
    assert(
      eggs == CRAFTS and wards == CRAFTS,
      "expected " .. CRAFTS .. " uncommon eggs and wards, got " .. texts[2]
    )
  end)
end)

tags("space-age")
test("every warded item weighs the same as its source item", function()
  local differ = {}
  for _, name in ipairs(Stasis.lifecycle_names()) do
    local plain = prototypes.item[name].weight
    local warded = prototypes.item[Stasis.warded_name(Stasis.BASE, name)].weight
    if plain ~= warded then
      differ[#differ + 1] = name .. " " .. plain .. " vs " .. warded
    end
  end
  assert(#differ == 0, "weights differ: " .. table.concat(differ, "; "))
end)
