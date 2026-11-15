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
    local war = not feral.get_cease_fire(other) and not other.get_cease_fire(feral)
    game.merge_forces(other, "player")
    assert(war, "no war")
  end)
end)

test("a character within the feral radius makes a loaded monster feral", function()
  with_entry({ 3000, 3000 }, "ao-biter-larva-explosive", function(entry)
    local p = entry.unit.position
    local character = Helpers.character(surface(), { p.x + f.radius - 1, p.y })
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
    local character = Helpers.character(surface(), { p.x + f.radius + 1, p.y })
    FeralShell.scan_player({ character = character, force = character.force }, game.tick)
    local feral = entry.feral
    character.destroy()
    entry.unit.destroy()
    assert(not feral, "the monster went feral")
  end)
end)

test("a player at war with the tamed force never makes a monster feral", function()
  with_entry({ 3060, 3000 }, "ao-biter-larva-explosive", function(entry)
    local other = game.forces["ao-feral-test-hostile"] or game.create_force("ao-feral-test-hostile")
    local tamed = game.forces[Names.TAMED]
    tamed.set_cease_fire(other, false)
    other.set_cease_fire(tamed, false)
    local p = entry.unit.position
    local character = Helpers.character(surface(), { p.x + 1, p.y }, other.name)
    FeralShell.scan_player({ character = character, force = other }, game.tick)
    local feral = entry.feral
    character.destroy()
    entry.unit.destroy()
    game.merge_forces(other, "player")
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
    local command = entry.unit.commandable.command
    local chest_x, chest_y = chest.position.x, chest.position.y
    chest.destroy()
    entry.unit.destroy()
    assert(hunting, "the monster is not hunting")
    assert(command, "the monster has no command")
    assert(command.type == defines.command.attack_area, "the command is not attack_area")
    local d = command.destination
    assert(
      math.abs(d.x - chest_x) < 1 and math.abs(d.y - chest_y) < 1,
      "the hunt aims at " .. d.x .. "," .. d.y
    )
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

test("an idle loaded monster goes feral at its next check", function()
  with_entry({ 3240, 3000 }, "ao-biter-larva-explosive", function(entry)
    entry.idle_since = game.tick - f.idle_ticks
    FeralShell.check(entry.unit.unit_number, game.tick, 0.99)
    local feral = entry.feral
    entry.unit.destroy()
    assert(feral, "the idle monster stayed tamed")
  end)
end)

test("a native in range clears the idle clock", function()
  with_entry({ 3280, 3000 }, "ao-biter-larva-explosive", function(entry)
    local p = entry.unit.position
    local native = surface().create_entity({
      name = "small-biter",
      position = { p.x + 10, p.y },
      force = "enemy",
    })
    native.disabled_by_script = true
    entry.idle_since = game.tick - 100
    FeralShell.check(entry.unit.unit_number, game.tick, 0.99)
    local idle = entry.idle_since
    native.destroy()
    entry.unit.destroy()
    assert(idle == nil, "the idle clock still runs")
  end)
end)

test("a feral monster with no command gets one at its next check", function()
  with_entry({ 3320, 3000 }, "ao-biter-larva-explosive", function(entry)
    FeralShell.go_feral(entry, game.tick)
    entry.unit.commandable.set_command({
      type = defines.command.stop,
      ticks_to_wait = 1,
    })
    after_ticks(5, function()
      FeralShell.check(entry.unit.unit_number, game.tick, 0.99)
      local has_command = entry.unit.commandable.has_command
      entry.unit.destroy()
      assert(has_command, "the feral monster has no command")
    end)
  end)
end)

test("a failed hunt marks the monster, a distraction does not", function()
  with_entry({ 3360, 3000 }, "ao-biter-larva-explosive", function(entry)
    FeralShell.go_feral(entry, game.tick)
    local number = entry.unit.unit_number
    entry.hunting = true
    FeralShell.completed({
      unit_number = number,
      result = defines.behavior_result.fail,
      was_distracted = true,
      tick = game.tick,
    })
    local after_distraction = entry.failed_at
    local still_hunting = entry.hunting
    FeralShell.completed({
      unit_number = number,
      result = defines.behavior_result.fail,
      was_distracted = false,
      tick = game.tick,
    })
    local after_fail = entry.failed_at
    local hunting = entry.hunting
    entry.unit.destroy()
    assert(after_distraction == nil, "a distraction marked the monster")
    assert(still_hunting == true, "a distraction ended the hunt")
    assert(after_fail == game.tick, "a failed hunt did not mark the monster")
    assert(hunting == false, "the monster still hunts after a failure")
  end)
end)

test("a failure of another unit number leaves the entry alone", function()
  with_entry({ 3380, 3000 }, "ao-biter-larva-explosive", function(entry)
    FeralShell.go_feral(entry, game.tick)
    entry.hunting = true
    FeralShell.completed({
      unit_number = entry.unit.unit_number + 1000000,
      result = defines.behavior_result.fail,
      was_distracted = false,
      tick = game.tick,
    })
    local failed_at = entry.failed_at
    entry.unit.destroy()
    assert(failed_at == nil, "another unit's failure marked the monster")
  end)
end)

test("a marked monster wanders instead of hunting", function()
  with_entry({ 3400, 3000 }, "ao-biter-larva-explosive", function(entry)
    local p = entry.unit.position
    local chest = Helpers.chest(surface(), { p.x + 20, p.y })
    FeralShell.go_feral(entry, game.tick)
    entry.failed_at = game.tick
    FeralShell.hunt(entry, game.tick + 1)
    local while_marked = entry.hunting
    FeralShell.hunt(entry, game.tick + f.retry_wanders * f.rewander_ticks)
    local afterwards = entry.hunting
    chest.destroy()
    entry.unit.destroy()
    assert(while_marked == false, "a marked monster hunted")
    assert(afterwards == true, "the mark did not end")
  end)
end)

test("a monster that dies under the feral cursor does not stop the check", function()
  with_entry({ 3440, 3000 }, "ao-biter-larva-explosive", function(first)
    storage.feral_cursor = first.unit.unit_number
    first.unit.destroy()
    after_ticks(2, function()
      local cursor = storage.feral_cursor
      assert(cursor == nil or storage.loaded[cursor] ~= nil, "the cursor points at a removed entry")
    end)
  end)
end)

tags("space-age")
test("a Gleba native keeps a tamed monster from idling", function()
  with_entry({ 3480, 3000 }, "ao-biter-larva-explosive", function(entry)
    local p = entry.unit.position
    local native = surface().create_entity({
      name = "small-strafer-pentapod",
      position = { p.x + 10, p.y },
      force = "enemy",
    })
    entry.idle_since = game.tick - 100
    FeralShell.check(entry.unit.unit_number, game.tick, 0.99)
    local idle = entry.idle_since
    if native.valid then
      native.destroy()
    end
    entry.unit.destroy()
    assert(idle == nil, "a spider unit did not count as a native")
  end)
end)
