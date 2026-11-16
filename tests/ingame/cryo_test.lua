local Names = require("core.names")
local Stasis = require("core.prototypes.stasis")
local Helpers = require("__abominable-ordnance__/tests/ingame/helpers")
local Species = require("core.species")

tags("space-age")
test("the cryo ward, its warded items, recipes and research exist", function()
  assert(prototypes.item[Names.CRYO_WARD], Names.CRYO_WARD)
  assert(prototypes.recipe[Names.CRYO_WARD], "recipe " .. Names.CRYO_WARD)
  assert(prototypes.technology[Names.CRYO_TECH], Names.CRYO_TECH)
  for _, name in ipairs(Stasis.lifecycle_names()) do
    assert(prototypes.item[Stasis.warded_name(Stasis.CRYO, name)], name)
    assert(prototypes.recipe[Stasis.pack_recipe(Stasis.CRYO, name)], name)
    assert(prototypes.recipe[Stasis.unpack_recipe(Stasis.CRYO, name)], name)
  end
end)

tags("base")
test("without Space Age there is no cryo ward", function()
  assert(not prototypes.item[Names.CRYO_WARD], "the cryo ward exists")
  assert(not prototypes.technology[Names.CRYO_TECH], "the cryo research exists")
  assert(prototypes.item[Names.WARD], "the base ward is missing")
end)

local BITER = Species.ALL[1]
local ROCKET = "ao-biter-larva-explosive"
local WARDED_ROCKET = "ao-warded-biter-larva-explosive"
local CRYO_ROCKET = "ao-cryo-warded-biter-larva-explosive"
local CRYO_EGG = "ao-cryo-warded-biter-egg"

local surface = function()
  return game.surfaces[1]
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

-- An assembling machine 3 with power that runs one recipe, with its
-- input filled. The force gets both ward researches. The fast machine
-- keeps a plain rocket's time short during the hand-off.
local function assembler(position, recipe, inputs)
  Helpers.arena(surface(), position)
  Helpers.research(true, Names.STASIS_TECH)
  Helpers.research(true, Names.CRYO_TECH)
  local machine = Helpers.powered_machine(surface(), position, "assembling-machine-3")
  machine.set_recipe(recipe)
  local input = machine.get_inventory(defines.inventory.crafter_input)
  for _, stack in ipairs(inputs) do
    input.insert(stack)
  end
  return machine, input
end

local function output(machine)
  return machine.get_inventory(defines.inventory.crafter_output)
end

-- Copies a stack from one inventory to another and clears the source.
-- The check after the copy makes a failure name the move, not a recipe.
local function move(from, to, name)
  local stack = from.find_item_stack(name)
  assert(stack, "no " .. name .. " to move")
  local p = stack.spoil_percent
  assert(to.insert(stack) == 1, "could not move the " .. name)
  stack.clear()
  local moved = to.find_item_stack(name)
  assert(moved and near(moved.spoil_percent, p), "the move changed the progress of " .. name)
end

before_each(function()
  game.forces["enemy"].set_evolution_factor(0, surface())
end)

tags("space-age")
test("an assembler packs a rocket at 40% into a cryo-warded rocket at about 40%", function()
  local machine, input = assembler({ 4000, 4000 }, "ao-cryo-ward-biter-larva-explosive", {
    { name = ROCKET, count = 1 },
    { name = Names.CRYO_WARD, count = 1 },
  })
  set_progress(input.find_item_stack(ROCKET), 0.4)
  after_ticks(90, function()
    local out = output(machine)
    local stack = out.find_item_stack(CRYO_ROCKET)
    local p = stack and stack.spoil_percent
    local left = input.get_item_count(ROCKET) + input.get_item_count(Names.CRYO_WARD)
    machine.destroy()
    assert(stack, "no cryo-warded rocket")
    assert(left == 0, left .. " inputs left")
    assert(near(p, 0.4), "cryo-warded rocket at " .. p)
  end)
end)

tags("space-age")
test("unpacking a cryo-warded rocket at 40% gives a rocket at about 40% and the ward", function()
  local machine, input = assembler({ 4040, 4000 }, "ao-cryo-unward-biter-larva-explosive", {
    { name = CRYO_ROCKET, count = 1 },
  })
  set_progress(input.find_item_stack(CRYO_ROCKET), 0.4)
  after_ticks(90, function()
    local out = output(machine)
    local rocket = out.find_item_stack(ROCKET)
    local wards = out.get_item_count(Names.CRYO_WARD)
    local p = rocket and rocket.spoil_percent
    machine.destroy()
    assert(rocket, "no rocket")
    assert(near(p, 0.4), "rocket at " .. tostring(p))
    assert(wards == 1, wards .. " cryo wards")
  end)
end)

tags("space-age")
test("the hand-off: base ward, unpack, then cryo ward keeps about 40%", function()
  local a, a_in = assembler({ 4080, 4000 }, "ao-ward-biter-larva-explosive", {
    { name = ROCKET, count = 1 },
    { name = Names.WARD, count = 1 },
  })
  set_progress(a_in.find_item_stack(ROCKET), 0.4)
  local b, b_in = assembler({ 4120, 4000 }, "ao-unward-biter-larva-explosive", {})
  local c, c_in = assembler({ 4160, 4000 }, "ao-cryo-ward-biter-larva-explosive", {
    { name = Names.CRYO_WARD, count = 1 },
  })
  after_ticks(90, function()
    move(output(a), b_in, WARDED_ROCKET)
    after_ticks(90, function()
      move(output(b), c_in, ROCKET)
      after_ticks(90, function()
        local out = output(c)
        local stack = out.find_item_stack(CRYO_ROCKET)
        local p = stack and stack.spoil_percent
        local base_wards = output(b).get_item_count(Names.WARD)
        for _, m in ipairs({ a, b, c }) do
          m.destroy()
        end
        assert(stack, "no cryo-warded rocket after the hand-off")
        assert(base_wards == 1, base_wards .. " base wards back")
        assert(near(p, 0.4), "cryo-warded rocket at " .. p)
      end)
    end)
  end)
end)

-- Puts one egg in a steel chest. Its spoil progress leaves 60 ticks on
-- a plain egg, so a cryo-warded egg has 100 times as long left.
local function egg_in_chest(position, name)
  Helpers.arena(surface(), position)
  local chest = Helpers.chest(surface(), position)
  chest.insert({ name = name, count = 1 })
  local total = prototypes.item[BITER.egg].get_spoil_ticks()
  set_progress(chest.get_inventory(defines.inventory.chest)[1], 1 - 60 / total)
  return chest
end

tags("space-age")
test("a cryo-warded egg with 60 plain ticks left is still unspoiled 3 s later", function()
  local chest = egg_in_chest({ 4200, 4000 }, CRYO_EGG)
  after_ticks(180, function()
    local count = chest.get_item_count(CRYO_EGG)
    chest.destroy()
    assert(count == 1, "the cryo-warded egg spoiled")
  end)
end)

tags("space-age")
test("control: a plain egg with 60 ticks left spoils within 3 s", function()
  local chest = egg_in_chest({ 4240, 4000 }, BITER.egg)
  after_ticks(180, function()
    local count = chest.get_item_count(BITER.egg)
    chest.destroy()
    assert(count == 0, "the plain egg did not spoil")
  end)
end)

tags("space-age")
test("a cryo-warded rocket that spoils hatches its loaded monster on the tamed force", function()
  local position = { 4280, 4000 }
  Helpers.arena(surface(), position)
  Helpers.spoil(Helpers.spill(surface(), position, CRYO_ROCKET, 1))
  after_ticks(2, function()
    local units = Helpers.find_units(surface(), position, { force = Names.TAMED })
    local entry = units[1] and storage.loaded[units[1].unit_number]
    for _, unit in ipairs(units) do
      unit.destroy()
    end
    assert(#units == 1, #units .. " tamed units")
    assert(entry and entry.payloads[1] == "explosive", "no loaded entry")
  end)
end)

tags("space-age")
test("every cryo-warded item weighs the same as its source item", function()
  local differ = {}
  for _, name in ipairs(Stasis.lifecycle_names()) do
    local plain = prototypes.item[name].weight
    local warded = prototypes.item[Stasis.warded_name(Stasis.CRYO, name)].weight
    if plain ~= warded then
      differ[#differ + 1] = name .. " " .. plain .. " vs " .. warded
    end
  end
  assert(#differ == 0, "weights differ: " .. table.concat(differ, "; "))
end)

-- A cryogenic plant with power. The plant is 5 by 5. The pole and the
-- energy interface stand further out than Helpers.powered_machine puts
-- them. x and y are the plant's centre, on half tiles.
local function cryogenic_plant(on, x, y)
  Helpers.research(true, Names.CRYO_TECH)
  local plant =
    on.create_entity({ name = "cryogenic-plant", position = { x, y }, force = "player" })
  on.create_entity({ name = "small-electric-pole", position = { x + 3, y }, force = "player" })
  on.create_entity({
    name = "electric-energy-interface",
    position = { x + 5.5, y },
    force = "player",
  })
  return plant
end

-- Aquilo freezes a plant that gets no heat. A heating tower with coal
-- heats the plant through two heat pipes on its south side: the tower's
-- heat connections sit one tile out from its edge.
local function heat(on, x, y)
  for _, dy in ipairs({ 3, 4 }) do
    on.create_entity({ name = "heat-pipe", position = { x, y + dy }, force = "player" })
  end
  local tower =
    on.create_entity({ name = "heating-tower", position = { x, y + 6 }, force = "player" })
  tower.insert({ name = "coal", count = 50 })
  return tower
end

-- Aquilo's surface. The planet makes none on its own, and create_surface
-- gives the existing one back on a second call. A square of ice
-- platform keeps the machines out of the ocean.
local function aquilo(x, y)
  local on = game.planets["aquilo"].create_surface()
  Helpers.arena(on, { x, y })
  local tiles = {}
  for tx = x - 12, x + 12 do
    for ty = y - 12, y + 12 do
      tiles[#tiles + 1] = { name = "ice-platform", position = { tx, ty } }
    end
  end
  on.set_tiles(tiles)
  return on
end

-- Calls fn once the plant is no longer frozen, within tries seconds.
local function once_warm(plant, tries, fn)
  if not plant.frozen then
    return fn()
  end
  assert(tries > 0, "the cryogenic plant stayed frozen")
  after_ticks(60, function()
    once_warm(plant, tries - 1, fn)
  end)
end

tags("space-age")
test("a cryogenic plant on Aquilo makes a cryo ward and gives hot fluoroketone back", function()
  local on = aquilo(8, 8)
  local plant = cryogenic_plant(on, 8.5, 8.5)
  local tower = heat(on, 8.5, 8.5)
  once_warm(plant, 20, function()
    plant.set_recipe(Names.CRYO_WARD)
    plant.insert({ name = "lithium-plate", count = 2 })
    local poured = plant.insert_fluid({ name = "fluoroketone-cold", amount = 10 })
    assert(poured == 10, "poured " .. poured .. " cold fluoroketone")
    after_ticks(300, function()
      local wards = output(plant).get_item_count(Names.CRYO_WARD)
      local hot = plant.get_fluid_contents()["fluoroketone-hot"] or 0
      tower.destroy()
      plant.destroy()
      assert(wards == 1, wards .. " cryo wards")
      assert(hot >= 4.99, hot .. " hot fluoroketone back")
    end)
  end)
end)

-- The engine checks surface conditions when a player picks a recipe. It
-- does not check them when a script sets one: a plant on Nauvis with
-- set_recipe still crafts the ward. So the test pins the data that the
-- picker reads. The recipe asks for pressure 300, and Nauvis has another.
tags("space-age")
test("the cryo ward recipe asks for Aquilo's pressure, and Nauvis has another", function()
  local conditions = prototypes.recipe[Names.CRYO_WARD].surface_conditions
  assert(conditions and #conditions == 1, "the recipe has no single surface condition")
  local c = conditions[1]
  assert(c.property == "pressure", "the condition is on " .. tostring(c.property))
  local aquilo_pressure = game.planets["aquilo"].prototype.surface_properties["pressure"]
  assert(
    c.min <= aquilo_pressure and aquilo_pressure <= c.max,
    "Aquilo has pressure " .. aquilo_pressure
  )
  local nauvis = surface().get_property("pressure")
  assert(nauvis < c.min or nauvis > c.max, "Nauvis has pressure " .. nauvis)
end)

tags("space-age")
test("a cryogenic plant on Aquilo without heat freezes", function()
  local on = aquilo(40, 8)
  local plant = cryogenic_plant(on, 40.5, 8.5)
  after_ticks(600, function()
    local frozen = plant.frozen
    plant.destroy()
    assert(frozen, "the unheated plant did not freeze")
  end)
end)
