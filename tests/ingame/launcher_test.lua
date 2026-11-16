local Damage = require("shell.damage")
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

-- Polls each tick, up to limit ticks, until at least count tamed
-- units stand near a spot. Then it calls finish(hatched). The monster
-- hatches in the tick of the landing. Its own bites and its payload
-- come later, so at that tick only the blast hurt the targets.
local function once_landed(to, count, limit, finish)
  if #tamed_units(to) >= count or limit <= 0 then
    finish(#tamed_units(to) >= count)
    return
  end
  after_ticks(1, function()
    once_landed(to, count, limit - 1, finish)
  end)
end

-- The targets of a landing blast around a spot, by name. Each one is
-- within 3.5 tiles of the spot.
local function blast_targets(to)
  local t = {
    native = surface().create_entity({
      name = "medium-biter",
      position = { to[1] + 1, to[2] },
      force = "enemy",
    }),
    tamed = surface().create_entity({
      name = "medium-biter",
      position = { to[1] - 1, to[2] },
      force = Names.TAMED,
    }),
    chest = surface().create_entity({
      name = "wooden-chest",
      position = { to[1], to[2] + 1.5 },
      force = "player",
    }),
    character = Helpers.character(surface(), { to[1] + 1.5, to[2] + 1.5 }),
    tree = surface().create_entity({ name = "tree-01", position = { to[1] - 1.5, to[2] + 1.5 } }),
    rock = surface().create_entity({ name = "big-rock", position = { to[1], to[2] - 2 } }),
  }
  t.native.disabled_by_script = true
  t.tamed.disabled_by_script = true
  return t
end

-- Reads which targets lost health, then removes the targets, the
-- hatched monsters and the launcher, so a failed assert leaves nothing.
local function settle_blast(to, targets, launcher)
  local hurt = {}
  for name, entity in pairs(targets) do
    hurt[name] = not entity.valid or entity.health < entity.max_health
    if entity.valid then
      entity.destroy()
    end
  end
  for _, unit in ipairs(tamed_units(to)) do
    unit.destroy()
  end
  if launcher and launcher.valid then
    launcher.destroy()
  end
  return hurt
end

-- Fires a rocket from a launcher at a row and checks which of the
-- blast targets took damage against rule, a table of name = boolean.
local function landing(y, projectile, rule)
  local from, to = { 1100, y }, { 1120, y }
  Helpers.arena(surface(), to)
  local launcher = surface().create_entity({
    name = Names.LAUNCHER,
    position = from,
    force = "player",
  })
  local targets = blast_targets(to)
  fire(from, to, projectile, launcher)
  -- The pre-placed tamed monster plus the hatched one.
  once_landed(to, 2, 300, function(hatched)
    local hurt = settle_blast(to, targets, launcher)
    assert(hatched, "the monster did not hatch within 300 ticks")
    for name, hit in pairs(rule) do
      assert(hurt[name] == hit, name .. (hit and " is untouched" or " is hurt"))
    end
  end)
end

test(
  "an explosive landing hurts a native, a chest, a character, a tamed monster, a tree and a rock",
  function()
    landing(760, "ao-larva-projectile-biter-explosive", {
      native = true,
      tamed = true,
      chest = true,
      character = true,
      tree = true,
      rock = true,
    })
  end
)

test(
  "a poison landing hurts a native, a character, a tamed monster and a tree, not a chest or a rock",
  function()
    landing(1220, "ao-larva-projectile-biter-poison", {
      native = true,
      tamed = true,
      character = true,
      tree = true,
      chest = false,
      rock = false,
    })
  end
)

test(
  "an acid landing hurts a native, a chest, a character, a tamed monster and a tree, not a rock",
  function()
    landing(1260, "ao-larva-projectile-spitter-acid", {
      native = true,
      tamed = true,
      chest = true,
      character = true,
      tree = true,
      rock = false,
    })
  end
)

test("the blast of a rocket without a launcher still follows the payload", function()
  local from, to = { 1100, 780 }, { 1120, 780 }
  Helpers.arena(surface(), to)
  local targets = {
    native = surface().create_entity({
      name = "medium-biter",
      position = { to[1] + 1, to[2] },
      force = "enemy",
    }),
    chest = surface().create_entity({
      name = "wooden-chest",
      position = { to[1], to[2] + 1.5 },
      force = "player",
    }),
    rival = rival_chest({ to[1] - 1.5, to[2] + 1.5 }),
  }
  targets.native.disabled_by_script = true
  fire(from, to, "ao-larva-projectile-spitter-acid")
  once_landed(to, 1, 300, function(hatched)
    local hurt = settle_blast(to, targets, nil)
    assert(hatched, "the monster did not hatch within 300 ticks")
    assert(hurt.native, "the native is untouched")
    assert(hurt.chest, "the player chest is untouched")
    assert(hurt.rival, "the rival chest is untouched")
  end)
end)

test(
  "an explosive landing still hurts the launcher's own chest when its force has friendly fire off",
  function()
    local player = game.forces["player"]
    local old = player.friendly_fire
    local from, to = { 1100, 1300 }, { 1120, 1300 }
    Helpers.arena(surface(), to)
    local launcher = surface().create_entity({
      name = Names.LAUNCHER,
      position = from,
      force = "player",
    })
    local chest = Helpers.chest(surface(), { to[1] + 1, to[2] })
    local plain = Helpers.chest(surface(), { from[1] + 5, from[2] })
    -- A plain hit is the control: with friendly fire off, the engine
    -- swallows it. The flag goes back in the landing callback, or at
    -- once when the shot itself fails.
    player.friendly_fire = false
    plain.damage(10, "player", "explosion")
    local plain_whole = plain.health == plain.max_health
    plain.destroy()
    local ok, err = pcall(fire, from, to, "ao-larva-projectile-biter-explosive", launcher)
    if not ok then
      player.friendly_fire = old
      settle_blast(to, { chest = chest }, launcher)
      error(err)
    end
    once_landed(to, 1, 300, function(hatched)
      player.friendly_fire = old
      local hurt = settle_blast(to, { chest = chest }, launcher)
      assert(plain_whole, "control: a plain hit hurt the chest, so the engine does not swallow it")
      assert(hatched, "the monster did not hatch within 300 ticks")
      assert(hurt.chest, "the chest is untouched")
    end)
  end
)

test("a larva rocket that lands in water sets off its payload through the queue", function()
  local from, to = { 1100, 820 }, { 1130, 820 }
  Helpers.arena(surface(), to)
  local tiles = {}
  for x = -10, 10 do
    for y = -10, 10 do
      tiles[#tiles + 1] = { name = "deepwater", position = { to[1] + x, to[2] + y } }
    end
  end
  surface().set_tiles(tiles)
  -- A death of an earlier test can reach the queue in the same ticks,
  -- so the test counts only the detonations at the landing spot.
  local queue, queued = Damage.queue, 0
  ---@diagnostic disable-next-line: duplicate-set-field
  Damage.queue = function(on, position, payloads, force)
    if math.abs(position.x - to[1]) < 1 and math.abs(position.y - to[2]) < 1 then
      queued = queued + #payloads
    end
    return queue(on, position, payloads, force)
  end
  local ok, err = pcall(fire, from, to, "ao-larva-projectile-biter-poison")
  if not ok then
    Damage.queue = queue
    error(err)
  end
  after_ticks(120, function()
    Damage.queue = queue
    local clouds = surface().find_entities_filtered({
      position = to,
      radius = 6,
      name = Names.CLOUD,
    })
    local force = clouds[1] and clouds[1].force.name
    for _, cloud in pairs(clouds) do
      cloud.destroy()
    end
    assert(#tamed_units(to) == 0, "a monster hatched in the water")
    assert(queued == 1, queued .. " detonations queued")
    assert(force == Names.TAMED, "the cloud belongs to " .. tostring(force))
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
