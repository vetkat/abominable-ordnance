local Names = require("core.names")
local Tamed = require("shell.tamed")
local Balance = require("core.balance")
local FeralShell = require("shell.feral")
local Helpers = require("__abominable-ordnance__/tests/ingame/helpers")

local f = Balance.feral

local surface = function()
  return game.surfaces[1]
end

-- Hatches one small loaded biter at a position and passes its entry to
-- after(entry) a tick later. Evolution 0 makes it a small biter.
local function with_entry(position, item, after)
  Helpers.arena(surface(), position, 40)
  game.forces["enemy"].set_evolution_factor(0, surface())
  Helpers.spoil(Helpers.spill(surface(), position, item, 1))
  after_ticks(1, function()
    local units = Helpers.find_units(surface(), position, { force = Names.TAMED })
    assert(#units == 1, #units .. " tamed units")
    local entry = storage.loaded[units[1].unit_number]
    assert(entry, "no loaded entry")
    entry.unit.disabled_by_script = true
    after(entry)
  end)
end

test("the feral force is at war with the natives, players and the tamed force", function()
  local feral = game.forces[Names.FERAL]
  assert(feral, "no feral force")
  for _, name in ipairs({ "enemy", "player", Names.TAMED }) do
    assert(not feral.get_cease_fire(name), "the feral force spares " .. name)
    assert(not game.forces[name].get_cease_fire(feral), name .. " spares the feral force")
  end
end)

test("a second setup keeps the tamed and the feral force at war", function()
  Tamed.ensure()
  Tamed.ensure()
  local feral = game.forces[Names.FERAL]
  assert(not feral.get_cease_fire(Names.TAMED), "the feral force spares the tamed force")
  local tamed = game.forces[Names.TAMED]
  assert(not tamed.get_cease_fire(feral), "the tamed force spares the feral force")
end)

test("a force made later is at war with the feral force", function()
  local other = game.forces["ao-feral-test-force"] or game.create_force("ao-feral-test-force")
  after_ticks(1, function()
    local feral = game.forces[Names.FERAL]
    assert(not feral.get_cease_fire(other) and not other.get_cease_fire(feral), "no war")
  end)
end)

test("the force limit guard allows a force below 64 forces only", function()
  assert(Tamed.can_create(63), "63 forces should leave room")
  assert(not Tamed.can_create(64), "64 forces should be full")
end)

test("a character within the feral radius makes a loaded monster feral", function()
  with_entry({ 3000, 3000 }, "ao-biter-larva-explosive", function(entry)
    local p = entry.unit.position
    local character = surface().create_entity({
      name = "character",
      position = { p.x + f.radius - 1, p.y },
      force = "player",
    })
    local player = { character = character, force = character.force }
    FeralShell.scan_player(player, game.tick)
    local feral, force = entry.feral, entry.unit.force.name
    character.destroy()
    entry.unit.destroy()
    assert(feral, "the monster stayed tamed")
    assert(force == Names.FERAL, "the monster is on " .. force)
  end)
end)

test("a character outside the feral radius leaves the monster tamed", function()
  with_entry({ 3040, 3000 }, "ao-biter-larva-explosive", function(entry)
    local p = entry.unit.position
    local character = surface().create_entity({
      name = "character",
      position = { p.x + f.radius + 1, p.y },
      force = "player",
    })
    FeralShell.scan_player({ character = character, force = character.force }, game.tick)
    local feral = entry.feral
    character.destroy()
    entry.unit.destroy()
    assert(not feral, "the monster went feral")
  end)
end)

test("a player without a character never makes a monster feral", function()
  with_entry({ 3080, 3000 }, "ao-biter-larva-explosive", function(entry)
    FeralShell.scan_player({ character = nil, force = game.forces["player"] }, game.tick)
    local feral = entry.feral
    entry.unit.destroy()
    assert(not feral, "the monster went feral")
  end)
end)

test("a feral monster's payload belongs to the feral force", function()
  with_entry({ 3120, 3000 }, "ao-biter-larva-poison", function(entry)
    FeralShell.go_feral(entry, game.tick)
    local p = entry.unit.position
    entry.unit.die()
    after_ticks(2, function()
      local clouds = surface().find_entities_filtered({
        name = "poison-cloud",
        position = p,
        radius = 4,
      })
      local forces = {}
      for _, cloud in pairs(clouds) do
        forces[#forces + 1] = cloud.force.name
        cloud.destroy()
      end
      assert(#forces >= 1, "no poison cloud")
      assert(forces[1] == Names.FERAL, "the cloud belongs to " .. forces[1])
    end)
  end)
end)

test("a feral monster with a player chest in range hunts it", function()
  with_entry({ 3160, 3000 }, "ao-biter-larva-explosive", function(entry)
    local p = entry.unit.position
    local chest = Helpers.chest(surface(), { p.x + 20, p.y })
    entry.unit.disabled_by_script = false
    FeralShell.go_feral(entry, game.tick)
    local hunting = entry.hunting
    local has_command = entry.unit.commandable.has_command
    chest.destroy()
    entry.unit.destroy()
    assert(hunting, "the monster is not hunting")
    assert(has_command, "the monster has no command")
  end)
end)

test("a feral monster kill drops no nest loot", function()
  local position = { 3200, 3000 }
  with_entry(position, "ao-biter-larva-explosive", function(entry)
    FeralShell.go_feral(entry, game.tick)
    local spawner = surface().create_entity({
      name = "biter-spawner",
      position = { position[1] + 10, position[2] },
      force = "enemy",
    })
    local spot = { spawner.position.x, spawner.position.y }
    spawner.die(entry.unit.force, entry.unit)
    after_ticks(2, function()
      local eggs = Helpers.count_items(surface(), spot, "ao-biter-egg")
      entry.unit.destroy()
      assert(eggs == 0, eggs .. " eggs dropped")
    end)
  end)
end)
