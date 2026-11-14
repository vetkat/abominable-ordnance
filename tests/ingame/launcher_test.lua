local Helpers = require("__abominable-ordnance__/tests/ingame/helpers")
local Names = require("core.names")

local surface = function()
  return game.surfaces[1]
end

-- Fires one larva rocket from a spot to a target by hand. With a
-- launcher, the rocket's source is that launcher, as in a real shot.
local function fire(from, to, projectile, launcher)
  surface().create_entity({
    name = projectile,
    position = from,
    target = to,
    force = "player",
    speed = 1,
    source = launcher,
  })
end

local function tamed_units(position)
  return Helpers.find_units(surface(), position, { force = Names.TAMED })
end

-- A chest of a third force. It is at war with the player and at peace
-- with the natives, so only a blast that follows the launcher's force
-- can hurt it.
local function rival_chest(position)
  local rival = game.forces["ao-rival"] or game.create_force("ao-rival")
  local player, enemy = game.forces["player"], game.forces["enemy"]
  rival.set_cease_fire(player, false)
  player.set_cease_fire(rival, false)
  rival.set_cease_fire(enemy, true)
  enemy.set_cease_fire(rival, true)
  return surface().create_entity({ name = "wooden-chest", position = position, force = rival })
end

test("a larva rocket lands as its loaded monster at full health", function()
  local from, to = { 1100, 700 }, { 1120, 700 }
  Helpers.arena(surface(), to)
  fire(from, to, "ao-larva-projectile-biter-acid")
  after_ticks(120, function()
    local units = tamed_units(to)
    assert(#units == 1, #units .. " tamed units")
    local unit = units[1]
    assert(unit.health == unit.max_health, "the monster is hurt")
    local entry = storage.loaded[unit.unit_number]
    assert(entry and entry.payloads[1] == "acid", "no loaded entry")
  end)
end)

test(
  "the blast hurts a native and a rival force, and not a tamed monster, a player chest or a rock",
  function()
    local from, to = { 1100, 760 }, { 1120, 760 }
    Helpers.arena(surface(), to)
    local launcher = surface().create_entity({
      name = Names.LAUNCHER,
      position = from,
      force = "player",
    })
    local native = surface().create_entity({
      name = "medium-biter",
      position = { to[1] + 1, to[2] },
      force = "enemy",
    })
    native.disabled_by_script = true
    local tamed = surface().create_entity({
      name = "medium-biter",
      position = { to[1] - 1, to[2] },
      force = Names.TAMED,
    })
    tamed.disabled_by_script = true
    local chest = surface().create_entity({
      name = "wooden-chest",
      position = { to[1], to[2] + 1.5 },
      force = "player",
    })
    local rock = surface().create_entity({ name = "big-rock", position = { to[1], to[2] - 2 } })
    local rival = rival_chest({ to[1] - 1.5, to[2] + 1.5 })
    -- A control: this kind of rock does take explosion damage.
    local control = surface().create_entity({ name = "big-rock", position = { to[1] + 10, to[2] } })
    control.damage(35, "player", "explosion")
    fire(from, to, "ao-larva-projectile-spitter-acid", launcher)
    -- The monster hatches in the tick of the landing. Its own bites and
    -- its payload come later, so at that tick only the blast hurt the native.
    local waited = 0
    local function check()
      if #tamed_units(to) < 2 and waited < 300 then
        waited = waited + 1
        after_ticks(1, check)
        return
      end
      local hatched = #tamed_units(to) >= 2
      -- Read everything and clean up first, so a failure leaves nothing.
      local hurt = function(entity)
        return not entity.valid or entity.health < entity.max_health
      end
      local result = {
        native = hurt(native),
        control = hurt(control),
        tamed = hurt(tamed),
        chest = hurt(chest),
        rock = hurt(rock),
        rival = hurt(rival),
      }
      launcher.destroy()
      assert(hatched, "the monster did not hatch within 300 ticks")
      assert(result.native, "the blast missed the native")
      assert(result.control, "the rock shrugs off explosions")
      assert(result.rival, "the blast missed a force at war with the launcher")
      assert(not result.tamed, "the tamed monster is hurt")
      assert(not result.chest, "the player chest is hurt")
      assert(not result.rock, "the neutral rock is hurt")
    end
    after_ticks(1, check)
  end
)

test("the blast of a rocket without a launcher hurts only the natives", function()
  local from, to = { 1100, 780 }, { 1120, 780 }
  Helpers.arena(surface(), to)
  local native = surface().create_entity({
    name = "medium-biter",
    position = { to[1] + 1, to[2] },
    force = "enemy",
  })
  native.disabled_by_script = true
  local chest = surface().create_entity({
    name = "wooden-chest",
    position = { to[1], to[2] + 1.5 },
    force = "player",
  })
  local rival = rival_chest({ to[1] - 1.5, to[2] + 1.5 })
  fire(from, to, "ao-larva-projectile-spitter-acid")
  after_ticks(120, function()
    assert(not native.valid or native.health < native.max_health, "the native is untouched")
    assert(chest.valid and chest.health == chest.max_health, "the player chest is hurt")
    assert(rival.valid and rival.health == rival.max_health, "a rival force's chest is hurt")
  end)
end)

test("a larva rocket that lands in water sets off its payload there", function()
  local from, to = { 1100, 820 }, { 1130, 820 }
  Helpers.arena(surface(), to)
  local tiles = {}
  for x = -10, 10 do
    for y = -10, 10 do
      tiles[#tiles + 1] = { name = "deepwater", position = { to[1] + x, to[2] + y } }
    end
  end
  surface().set_tiles(tiles)
  fire(from, to, "ao-larva-projectile-biter-poison")
  after_ticks(120, function()
    assert(#tamed_units(to) == 0, "a monster hatched in the water")
    local clouds = surface().count_entities_filtered({
      position = to,
      radius = 6,
      name = "poison-cloud",
    })
    assert(clouds >= 1, "no poison cloud")
  end)
end)

test("a launcher fires on its own at a spawner in range", function()
  local position = { 1100, 900 }
  local target = { position[1] + 30, position[2] }
  Helpers.arena(surface(), position, 96)
  local spawner = surface().create_entity({
    name = "biter-spawner",
    position = target,
    force = "enemy",
  })
  spawner.disabled_by_script = true
  local launcher = Helpers.launcher(
    surface(),
    position,
    Names.LAUNCHER,
    { name = "ao-biter-larva-acid", count = 1 }
  )
  after_ticks(10 * 60, function()
    local fired = Helpers.ammo(launcher) == 0
    -- The shot landed if the spawner took damage or a tamed unit hatched.
    local hit = not spawner.valid or spawner.health < spawner.max_health
    local hatched = #tamed_units(target) > 0
    -- Vanilla artillery in later tests reaches this far, so nothing stays.
    if spawner.valid then
      spawner.destroy()
    end
    launcher.destroy()
    assert(fired, "the launcher did not fire")
    assert(hit or hatched, "the shot did not land at the spawner")
  end)
end)

test("a launcher does not fire on its own at a lone biter", function()
  local position = { 1100, 980 }
  local target = { position[1] + 30, position[2] }
  Helpers.arena(surface(), position, 96)
  local biter =
    surface().create_entity({ name = "small-biter", position = target, force = "enemy" })
  biter.disabled_by_script = true
  local launcher = Helpers.launcher(
    surface(),
    position,
    Names.LAUNCHER,
    { name = "ao-biter-larva-acid", count = 1 }
  )
  after_ticks(10 * 60, function()
    local held = Helpers.ammo(launcher) == 1
    biter.destroy()
    launcher.destroy()
    assert(held, "the launcher fired at a biter")
  end)
end)

-- A larva launcher and a vanilla artillery turret side by side, each
-- with one round, and a flare 40 tiles away.
local function flare_pair(y, flare)
  local position = { 1100, y }
  Helpers.arena(surface(), position, 96)
  local larva = Helpers.launcher(
    surface(),
    position,
    Names.LAUNCHER,
    { name = "ao-biter-larva-acid", count = 1 }
  )
  local vanilla = Helpers.launcher(
    surface(),
    { position[1], position[2] + 6 },
    "artillery-turret",
    { name = "artillery-shell", count = 1 }
  )
  local target = { position[1] + 40, position[2] + 3 }
  local lit = surface().create_entity({
    name = flare,
    position = target,
    force = "player",
    movement = { 0, 0 },
    height = 0,
    vertical_speed = 0,
    frame_speed = 1,
  })
  return larva, vanilla, lit
end

-- Reads which of the two fired, then removes all three entities, so a
-- failed assert cannot leave a flare or a turret for the next test.
local function settle(larva, vanilla, lit)
  local larva_fired, vanilla_fired = Helpers.ammo(larva) == 0, Helpers.ammo(vanilla) == 0
  for _, entity in pairs({ larva, vanilla, lit }) do
    entity.destroy()
  end
  return larva_fired, vanilla_fired
end

test("a larva flare fires a larva launcher and not vanilla artillery", function()
  local larva, vanilla, lit = flare_pair(1060, Names.FLARE)
  after_ticks(10 * 60, function()
    local larva_fired, vanilla_fired = settle(larva, vanilla, lit)
    assert(larva_fired, "the larva launcher did not fire")
    assert(not vanilla_fired, "vanilla artillery fired at a larva flare")
  end)
end)

test("a vanilla flare fires vanilla artillery and not a larva launcher", function()
  local larva, vanilla, lit = flare_pair(1140, "artillery-flare")
  after_ticks(10 * 60, function()
    local larva_fired, vanilla_fired = settle(larva, vanilla, lit)
    assert(vanilla_fired, "vanilla artillery did not fire")
    assert(not larva_fired, "the larva launcher fired at a vanilla flare")
  end)
end)

test("a rocket that spoils in the launcher hatches its monster beside it", function()
  local position = { 1300, 760 }
  Helpers.arena(surface(), position, 96)
  local launcher = Helpers.launcher(
    surface(),
    position,
    Names.LAUNCHER,
    { name = "ao-biter-larva-acid", count = 1 }
  )
  Helpers.spoil(launcher.get_inventory(defines.inventory.artillery_turret_ammo)[1])
  after_ticks(2, function()
    assert(Helpers.ammo(launcher) == 0, "the rocket is still in the launcher")
    local units = tamed_units(position)
    assert(#units == 1, #units .. " tamed units")
    local entry = storage.loaded[units[1].unit_number]
    assert(entry and entry.payloads[1] == "acid", "no loaded entry")
    local distance =
      math.sqrt((units[1].position.x - position[1]) ^ 2 + (units[1].position.y - position[2]) ^ 2)
    assert(distance < 8, "the monster hatched " .. distance .. " tiles away")
  end)
end)
