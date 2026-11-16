local Names = require("core.names")
local Tamed = require("shell.tamed")
local Balance = require("core.balance")
local FeralShell = require("shell.feral")
local Helpers = require("__abominable-ordnance__/tests/ingame/helpers")

local f = Balance.feral

local surface = function()
  return game.surfaces[1]
end

-- Hatches one small loaded biter and passes its entry to after(entry).
local function with_entry(position, item, after)
  Helpers.loaded_entry(surface(), position, item, after)
end

-- Stops the background batch check for the length of a test, so that
-- it can't touch the entry. restore() puts the schedule back.
local function pause_batch_check()
  local next_tick, cursor = storage.feral_next_tick, storage.feral_cursor
  storage.feral_next_tick = game.tick + 1000000
  storage.feral_cursor = nil
  return function()
    storage.feral_next_tick = next_tick
    storage.feral_cursor = cursor
  end
end

-- Polls every tick, up to limit ticks, until done() is true. Then it
-- calls finish(reached).
local function poll(limit, done, finish)
  if done() or limit <= 0 then
    finish(done())
    return
  end
  after_ticks(1, function()
    poll(limit - 1, done, finish)
  end)
end

-- A native of this species stands in range of a tamed monster that has
-- idled for a while. The check must clear the idle clock. The native
-- stays idle, so it can't fight.
local function native_clears_idle(position, native_name)
  with_entry(position, "ao-biter-larva-explosive", function(entry)
    local restore = pause_batch_check()
    local p = entry.unit.position
    local native = surface().create_entity({
      name = native_name,
      position = { p.x + 10, p.y },
      force = "enemy",
    })
    native.disabled_by_script = true
    entry.idle_since = game.tick - 100
    FeralShell.check(entry.unit.unit_number, game.tick, function()
      return 0.99
    end)
    local idle = entry.idle_since
    restore()
    native.destroy()
    entry.unit.destroy()
    assert(idle == nil, native_name .. " did not clear the idle clock")
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
    FeralShell.check(entry.unit.unit_number, game.tick, function()
      return 0.99
    end)
    local feral = entry.feral
    entry.unit.destroy()
    assert(feral, "the idle monster stayed tamed")
  end)
end)

test("a native in range clears the idle clock", function()
  native_clears_idle({ 3280, 3000 }, "small-biter")
end)

-- The "no command" branch of the batch check has no in-game test. In
-- Factorio 2.1 has_command reads true for a fresh unit and stays true
-- after a command ends, because the unit falls back to a default
-- command. The branch is a backup for a state that a test can't make.
-- The re-hunt on completion below covers the real path.

test("a feral monster whose wander ends hunts a chest in range", function()
  with_entry({ 3500, 3000 }, "ao-biter-larva-explosive", function(entry)
    local restore = pause_batch_check()
    entry.unit.disabled_by_script = false
    FeralShell.go_feral(entry, game.tick)
    local p = entry.unit.position
    local chest = Helpers.chest(surface(), { p.x + 20, p.y })
    assert(entry.hunting == false, "the precondition failed: the monster hunts with no target")
    entry.unit.commandable.set_command({
      type = defines.command.wander,
      radius = 2,
      ticks_to_wait = 5,
    })
    local ended = false
    poll(300, function()
      ended = ended or not entry.unit.commandable.has_command
      return entry.hunting
    end, function(reached)
      local command = entry.unit.commandable.command
      local seen_ended = ended
      local hunting = entry.hunting
      local chest_x = chest.position.x
      restore()
      chest.destroy()
      entry.unit.destroy()
      log("has_command read false after the wander ended: " .. tostring(seen_ended))
      assert(reached and hunting, "the monster never hunted")
      assert(command and command.type == defines.command.attack_area, "no attack_area command")
      assert(math.abs(command.destination.x - chest_x) < 1, "the hunt aims elsewhere")
    end)
  end)
end)

test("a second failed wander inside the mark window waits for the batch check", function()
  with_entry({ 3520, 3000 }, "ao-biter-larva-explosive", function(entry)
    local restore = pause_batch_check()
    entry.unit.disabled_by_script = false
    FeralShell.go_feral(entry, game.tick)
    local number = entry.unit.unit_number
    local function fail_after(set_up)
      entry.unit.commandable.set_command({
        type = defines.command.attack_area,
        destination = entry.unit.position,
        radius = 1,
      })
      entry.hunting = false
      set_up()
      FeralShell.completed({
        unit_number = number,
        result = defines.behavior_result.fail,
        was_distracted = false,
        tick = game.tick,
      })
      return entry.unit.commandable.command.type
    end
    local recent = fail_after(function()
      entry.failed_at = game.tick - 1
    end)
    local first = fail_after(function()
      entry.failed_at = nil
    end)
    local marked_at = entry.failed_at
    restore()
    entry.unit.destroy()
    assert(recent == defines.command.attack_area, "a recent failure rewandered at once")
    assert(first == defines.command.wander, "a first failure did not rewander")
    assert(marked_at == game.tick, "a failed wander did not mark the monster")
  end)
end)

test("a feral monster that waits for the batch check gets a command from it", function()
  with_entry({ 3540, 3000 }, "ao-biter-larva-explosive", function(entry)
    local restore = pause_batch_check()
    entry.unit.disabled_by_script = false
    FeralShell.go_feral(entry, game.tick)
    entry.unit.commandable.set_command({
      type = defines.command.attack_area,
      destination = entry.unit.position,
      radius = 1,
    })
    entry.hunting = false
    entry.failed_at = game.tick - 1
    FeralShell.completed({
      unit_number = entry.unit.unit_number,
      result = defines.behavior_result.fail,
      was_distracted = false,
      tick = game.tick,
    })
    local waiting = entry.awaiting_check
    local before = entry.unit.commandable.command.type
    FeralShell.check(entry.unit.unit_number, game.tick, function()
      return 0.99
    end)
    local after = entry.unit.commandable.command.type
    local cleared = entry.awaiting_check
    restore()
    entry.unit.destroy()
    assert(waiting == true, "the failed wander did not wait for the check")
    assert(before == defines.command.attack_area, "the precondition failed")
    assert(after == defines.command.wander, "the check gave no new command")
    assert(not cleared, "the wait flag stayed set")
  end)
end)

test("a tamed monster near a native gets an attack_area from the check", function()
  with_entry({ 3560, 3000 }, "ao-biter-larva-explosive", function(entry)
    local restore = pause_batch_check()
    entry.unit.disabled_by_script = false
    local p = entry.unit.position
    local native = surface().create_entity({
      name = "small-biter",
      position = { p.x + 10, p.y },
      force = "enemy",
    })
    native.disabled_by_script = true
    entry.unit.commandable.set_command({ type = defines.command.stop, ticks_to_wait = 1000 })
    FeralShell.check(entry.unit.unit_number, game.tick, function()
      return 0.99
    end)
    local command = entry.unit.commandable.command
    restore()
    native.destroy()
    entry.unit.destroy()
    assert(command and command.type == defines.command.attack_area, "no attack_area command")
  end)
end)

test("a success against the same target wanders instead of attacking again", function()
  with_entry({ 3580, 3000 }, "ao-biter-larva-explosive", function(entry)
    local restore = pause_batch_check()
    entry.unit.disabled_by_script = false
    local p = entry.unit.position
    local chest = Helpers.chest(surface(), { p.x + 20, p.y })
    FeralShell.go_feral(entry, game.tick)
    local first = entry.unit.commandable.command.type
    FeralShell.completed({
      unit_number = entry.unit.unit_number,
      result = defines.behavior_result.success,
      was_distracted = false,
      tick = game.tick,
    })
    local second = entry.unit.commandable.command.type
    local hunting = entry.hunting
    restore()
    chest.destroy()
    entry.unit.destroy()
    assert(first == defines.command.attack_area, "the precondition failed")
    assert(second == defines.command.wander, "the monster attacked the same target again")
    assert(hunting == false, "the monster still counts as hunting")
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

-- The cursor moving past a removed monster is core: Trail.forget, covered
-- in spec/core/trail_spec.lua.

tags("space-age")
test("a Gleba native keeps a tamed monster from idling", function()
  native_clears_idle({ 3480, 3000 }, "small-strafer-pentapod")
end)
