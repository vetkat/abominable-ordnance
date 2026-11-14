local Helpers = require("__abominable-ordnance__/tests/ingame/helpers")
local Launcher = require("core.launcher")
local LauncherShell = require("shell.launcher")
local Names = require("core.names")

local ROCKET = "ao-biter-larva-explosive"
local AMMO = defines.inventory.artillery_turret_ammo
local RED = defines.wire_connector_id.circuit_red

local surface = function()
  return game.surfaces[1]
end

local function set_range(force, level)
  for i = 1, 3 do
    force.technologies[Names.RANGE_TECH .. i].researched = i <= level
  end
end

-- A level 0 launcher with two rockets, at a test position.
local function launcher(position, force)
  Helpers.arena(surface(), position)
  local entity = surface().create_entity({
    name = Launcher.name(0),
    position = position,
    force = force or "player",
    quality = "normal",
  })
  entity.get_inventory(AMMO).insert({ name = ROCKET, count = 2 })
  return entity
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

local function one(names, level)
  return #names == 1 and names[1] == Launcher.name(level)
end

after_each(function()
  set_range(game.forces["player"], 0)
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

  set_range(game.forces["player"], 1)
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
  set_range(game.forces["player"], 2)
  after_ticks(1, function()
    local first = at(position)[1]
    local up = first and first.name
    set_range(game.forces["player"], 1)
    after_ticks(1, function()
      local names = settle(position)
      assert(up == Launcher.name(2), "not level 2: " .. tostring(up))
      assert(one(names, 1), "not back to level 1")
    end)
  end)
end)

test("a launcher built after the research is at the force's level", function()
  set_range(game.forces["player"], 3)
  local position = { 1180, 1600 }
  Helpers.arena(surface(), position)
  surface().create_entity({
    name = Launcher.name(0),
    position = position,
    force = "player",
    raise_built = true,
  })
  after_ticks(1, function()
    assert(one(settle(position), 3), "not level 3")
  end)
end)

test("a level 2 launcher on a level 0 force becomes level 0", function()
  local position = { 1220, 1600 }
  Helpers.arena(surface(), position)
  surface().create_entity({
    name = Launcher.name(2),
    position = position,
    force = "player",
    raise_built = true,
  })
  after_ticks(1, function()
    assert(one(settle(position), 0), "not level 0")
  end)
end)

test("a cloned launcher takes the force's level", function()
  local position = { 1240, 1600 }
  local target = { 1240, 1610 }
  Helpers.arena(surface(), position)
  -- create_entity without raise_built raises no event, so this launcher
  -- keeps level 1 on a level 0 force.
  local entity = surface().create_entity({
    name = Launcher.name(1),
    position = position,
    force = "player",
  })
  entity.clone({ position = target, surface = surface() })
  after_ticks(1, function()
    local names = settle(target)
    settle(position)
    assert(one(names, 0), "the clone is not level 0")
  end)
end)

test("mining a level 2 launcher gives the launcher item", function()
  local position = { 1260, 1600 }
  Helpers.arena(surface(), position)
  local entity = surface().create_entity({
    name = Launcher.name(2),
    position = position,
    force = "player",
  })
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
  launcher(position, other)
  set_range(game.forces["player"], 1)
  after_ticks(1, function()
    assert(one(settle(position, other), 0), "the other force swapped")
  end)
end)

test("the level reads the force's research", function()
  set_range(game.forces["player"], 2)
  assert(LauncherShell.level(game.forces["player"]) == 2, "level")
end)

-- The remote has no only-in-cursor flag, so it can sit in an inventory
-- and a cleared cursor does not take it away.
test("a larva targeting remote stays in the inventory when the cursor clears", function()
  local character = surface().create_entity({
    name = "character",
    position = { 1340, 1600 },
    force = "player",
  })
  local inventory = character.get_main_inventory()
  local inserted = inventory and inventory.insert({ name = Names.REMOTE, count = 1 }) or 0
  local cursor = character.cursor_stack
  local had_cursor = cursor ~= nil
  if cursor then
    cursor.set_stack({ name = Names.REMOTE, count = 1 })
    cursor.clear()
  end
  local kept = inventory and inventory.get_item_count(Names.REMOTE) or 0
  character.destroy()
  assert(inserted == 1, "the remote did not go into the inventory")
  assert(had_cursor, "the character has no cursor")
  assert(kept == 1, kept .. " remotes left after the cursor cleared")
end)
