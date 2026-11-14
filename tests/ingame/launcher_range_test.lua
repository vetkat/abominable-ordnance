local Helpers = require("__abominable-ordnance__/tests/ingame/helpers")
local Launcher = require("core.launcher")
local LauncherShell = require("shell.launcher")
local Names = require("core.names")
local Setup = require("shell.setup")

local ROCKET = "ao-biter-larva-explosive"
local AMMO = defines.inventory.artillery_turret_ammo
local RED = defines.wire_connector_id.circuit_red

local surface = function()
  return game.surfaces[1]
end

local function set_range(level)
  for i = 1, 3 do
    Helpers.research(i <= level, Names.RANGE_TECH .. i)
  end
end

-- A level 0 launcher with two rockets, at a test position.
local function launcher(position, force)
  Helpers.arena(surface(), position)
  return Helpers.launcher(
    surface(),
    position,
    Launcher.name(0),
    { name = ROCKET, count = 2 },
    force,
    "normal"
  )
end

local function at(position, force)
  return surface().find_entities_filtered({
    name = Launcher.NAMES,
    position = position,
    radius = 1,
    force = force or "player",
  })
end

-- Reads the names of the launchers at a position, then destroys them, so
-- that a failed assert leaves nothing for the next test.
local function settle(position, force)
  local names = {}
  for _, entity in pairs(at(position, force)) do
    names[#names + 1] = entity.name
    entity.destroy()
  end
  return names
end

-- Clears a test position of enemies and places a bare launcher of a
-- level there. raise is true to raise the built event.
local function place(level, position, raise)
  Helpers.arena(surface(), position)
  return surface().create_entity({
    name = Launcher.name(level),
    position = position,
    force = "player",
    raise_built = raise,
  })
end

local function one(names, level)
  return #names == 1 and names[1] == Launcher.name(level)
end

after_each(function()
  set_range(0)
end)

test("a range research swaps a placed launcher to the next level", function()
  local position = { 1100, 1600 }
  local old = launcher(position)
  old.health = old.max_health / 2
  old.artillery_auto_targeting = false
  old.get_inventory(AMMO)[1].spoil_percent = 0.5
  local chest = surface().create_entity({
    name = "iron-chest",
    position = { position[1] + 3, position[2] },
    force = "player",
  })
  old.get_wire_connector(RED, true).connect_to(chest.get_wire_connector(RED, true), false)
  local behaviour = old.get_or_create_control_behavior()
  ---@cast behaviour LuaArtilleryTurretControlBehavior
  behaviour.circuit_enable_disable = true
  behaviour.circuit_condition = {
    first_signal = { type = "item", name = "iron-plate" },
    comparator = ">",
    constant = 5,
  }
  behaviour.read_ammo = true
  local half = old.health

  set_range(1)
  after_ticks(1, function()
    local found = at(position)
    local new = found[1]
    local got = {}
    if #found == 1 then
      local ammo = new.get_inventory(AMMO)[1]
      local red = new.get_wire_connector(RED, false)
      local b = new.get_control_behavior()
      ---@cast b LuaArtilleryTurretControlBehavior?
      got = {
        name = new.name,
        quality = new.quality.name,
        health = new.health,
        auto = new.artillery_auto_targeting,
        count = ammo.valid_for_read and ammo.count or 0,
        spoil = ammo.valid_for_read and ammo.spoil_percent or -1,
        wires = red and red.connection_count or 0,
        enable = b and b.circuit_enable_disable,
        constant = b and b.circuit_condition and b.circuit_condition.constant,
        read_ammo = b and b.read_ammo,
      }
    end
    local launchers_on_ground = Helpers.count_items(surface(), position, Names.LAUNCHER)
    local rockets_on_ground = Helpers.count_items(surface(), position, ROCKET)
    settle(position)
    chest.destroy()
    assert(#found == 1, #found .. " launchers")
    assert(got.name == Launcher.name(1), "level " .. tostring(got.name))
    assert(got.quality == "normal", "quality " .. got.quality)
    assert(got.health == half, "health " .. got.health)
    assert(got.auto == false, "auto targeting came back")
    assert(got.count == 2, got.count .. " rockets in the launcher")
    assert(math.abs(got.spoil - 0.5) < 0.01, "spoil " .. got.spoil)
    assert(got.wires == 1, "red wire lost")
    assert(got.enable, "circuit setting lost")
    assert(got.constant == 5, "circuit condition lost")
    assert(got.read_ammo, "read ammo setting lost")
    assert(launchers_on_ground == 0, "launcher item on the ground")
    assert(rockets_on_ground == 0, "rockets on the ground")
  end)
end)

test("a reversed range research swaps the launcher back", function()
  local position = { 1140, 1600 }
  launcher(position)
  set_range(2)
  after_ticks(1, function()
    local first = at(position)[1]
    local up = first and first.name
    set_range(1)
    after_ticks(1, function()
      local names = settle(position)
      assert(up == Launcher.name(2), "not level 2: " .. tostring(up))
      assert(one(names, 1), "not back to level 1")
    end)
  end)
end)

test("a launcher built after the research is at the force's level", function()
  set_range(3)
  local position = { 1180, 1600 }
  place(0, position, true)
  after_ticks(1, function()
    assert(one(settle(position), 3), "not level 3")
  end)
end)

test("a level 2 launcher on a level 0 force becomes level 0", function()
  local position = { 1220, 1600 }
  place(2, position, true)
  after_ticks(1, function()
    assert(one(settle(position), 0), "not level 0")
  end)
end)

test("a cloned launcher takes the force's level", function()
  local position = { 1240, 1600 }
  local target = { 1240, 1610 }
  -- No raise_built, so this launcher keeps level 1 on a level 0 force.
  local entity = place(1, position)
  entity.clone({ position = target, surface = surface() })
  after_ticks(1, function()
    local names = settle(target)
    settle(position)
    assert(one(names, 0), "the clone is not level 0")
  end)
end)

test("mining a level 2 launcher gives the launcher item", function()
  local position = { 1260, 1600 }
  local entity = place(2, position)
  local inventory = game.create_inventory(10)
  entity.mine({ inventory = inventory, force = true })
  local count = inventory.get_item_count(Names.LAUNCHER)
  inventory.destroy()
  settle(position)
  assert(count == 1, count .. " launcher items")
end)

test("a research of one force leaves another force's launcher alone", function()
  local other = game.forces["ao-range-test"] or game.create_force("ao-range-test")
  local position = { 1300, 1600 }
  launcher(position, other.name)
  set_range(1)
  after_ticks(1, function()
    assert(one(settle(position, other), 0), "the other force swapped")
  end)
end)

test("the level reads the force's research", function()
  set_range(2)
  assert(LauncherShell.level(game.forces["player"]) == 2, "level")
end)

-- The busted test of the remote's flags is the main guard. This test
-- checks only the main inventory. It cannot check the cursor, because
-- a cursor clear deletes the stack.
test("a larva targeting remote can sit in a character's main inventory", function()
  local character = surface().create_entity({
    name = "character",
    position = { 1340, 1600 },
    force = "player",
  })
  local inventory = character.get_main_inventory()
  local inserted = inventory and inventory.insert({ name = Names.REMOTE, count = 1 }) or 0
  local kept = inventory and inventory.get_item_count(Names.REMOTE) or 0
  character.destroy()
  assert(inserted == 1, "the remote did not go into the inventory")
  assert(kept == 1, kept .. " remotes in the inventory")
end)

test("a configuration change swaps a launcher to its force's level", function()
  local position = { 1380, 1600 }
  -- No raise_built, so this launcher keeps level 2 on a level 0 force
  -- until the sync.
  place(2, position)
  Setup.on_configuration_changed()
  assert(one(settle(position), 0), "not level 0")
end)

test("a swap's state holds the quality as a name", function()
  local position = { 1420, 1600 }
  local entity = launcher(position)
  local state = LauncherShell.read(entity)
  settle(position)
  assert(type(state.quality) == "string", "quality is " .. type(state.quality))
  assert(state.quality == "normal", state.quality)
end)

test("a spill of a lost launcher puts the item on the ground", function()
  local position = { 1440, 1600 }
  Helpers.arena(surface(), position)
  local entity = launcher(position)
  local state = LauncherShell.read(entity)
  settle(position)
  local temp = game.create_inventory(1)
  LauncherShell.spill(temp, state, state.quality)
  temp.destroy()
  local count = Helpers.count_items(surface(), position, Names.LAUNCHER)
  assert(count == 1, count .. " launcher items on the ground")
end)

test("a force merge swaps the launcher to the destination's level", function()
  local other = game.forces["ao-merge-test"] or game.create_force("ao-merge-test")
  local position = { 1460, 1600 }
  set_range(1)
  -- The launcher is at level 0, the wrong level for the merged force.
  launcher(position, other.name)
  game.merge_forces(other, game.forces["player"])
  local waited = 0
  local function check()
    waited = waited + 1
    local names = at(position)
    if (#names == 1 and names[1].name == Launcher.name(1)) or waited >= 30 then
      local result = settle(position)
      assert(one(result, 1), "not level 1 after the merge")
    else
      after_ticks(1, check)
    end
  end
  after_ticks(1, check)
end)
