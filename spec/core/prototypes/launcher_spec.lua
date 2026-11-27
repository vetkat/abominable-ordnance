local Balance = require("core.balance")
local Graphics = require("core.prototypes.graphics")
local Launcher = require("core.launcher")
local LauncherPrototypes = require("core.prototypes.launcher")
local Names = require("core.names")
local Stubs = require("spec.support.stubs")

local function build(levels, space_age)
  local opts = Stubs.launcher_opts(levels)
  opts.space_age = space_age
  return Stubs.by_name(LauncherPrototypes.prototypes(opts))
end

describe("the launcher prototypes", function()
  it("make a level 0 artillery turret that holds five rockets", function()
    local t = build()["artillery-turret/ao-larva-launcher"]
    assert.are.equal("ao-larva-launcher-gun-0", t.gun)
    assert.are.equal(1, t.inventory_size)
    assert.are.equal(5, t.ammo_stack_limit)
    assert.are.equal(5, t.automated_ammo_count)
    assert.are.equal(1.5, t.manual_range_modifier)
    assert.are.equal(1000, t.max_health)
    assert.are.equal("ao-larva-launcher", t.minable.result)
    assert.is_nil(t.fast_replaceable_group)
    assert.is_nil(t.next_upgrade)
    assert.is_nil(t.hidden)
  end)

  it("show the launcher art at 3x3 with no tint", function()
    local all = build({ 0, 1 })
    for _, name in ipairs({ "ao-larva-launcher", "ao-larva-launcher-1" }) do
      local t = all["artillery-turret/" .. name]
      assert.are.same(Graphics.launcher(3), t.cannon_base_pictures, name)
      for _, layer in ipairs(t.cannon_base_pictures.layers) do
        assert.is_nil(layer.tint)
      end
      assert.are.same({ 0.25, -0.5, 1.75 }, t.cannon_base_shift)
      assert.are.equal(0.001, t.turret_rotation_speed)
    end
  end)

  it("drop the vanilla base, barrel and their fields", function()
    local t = build()["artillery-turret/ao-larva-launcher"]
    for _, field in ipairs({
      "base_picture",
      "base_picture_render_layer",
      "cannon_barrel_pictures",
      "cannon_barrel_recoil_shiftings",
      "cannon_barrel_recoil_shiftings_load_correction_matrix",
      "cannon_barrel_light_direction",
    }) do
      assert.is_nil(t[field], field)
    end
  end)

  it("give the launcher, its guns and its upgrades the launcher icon", function()
    local all = build({ 0, 1 })
    local want = { { icon = Graphics.icon_path("larva-launcher.png"), icon_size = 64 } }
    for _, key in ipairs({
      "item/ao-larva-launcher",
      "artillery-turret/ao-larva-launcher",
      "gun/ao-larva-launcher-gun-0",
      "technology/ao-larva-launcher-speed-1",
      "technology/ao-larva-launcher-range-1",
    }) do
      assert.are.same(want, all[key].icons, key)
    end
    assert.are.same(
      { { icon = Graphics.tech_path("larva-rockets.png"), icon_size = 256 } },
      all["technology/ao-larva-rockets"].icons
    )
  end)

  it("keep the tinted vanilla icons of the remote and the flare", function()
    local all = build()
    for _, key in ipairs({ "capsule/" .. Names.REMOTE, "artillery-flare/" .. Names.FLARE }) do
      local icon = all[key].icons[1]
      assert.are.equal("__base__/graphics/icons/artillery-targeting-remote.png", icon.icon, key)
      assert.are.same(LauncherPrototypes.TINT, icon.tint, key)
    end
  end)

  it("copy the circuit connector and the cheap extras of the vanilla turret", function()
    local opts = Stubs.launcher_opts()
    local t =
      Stubs.by_name(LauncherPrototypes.prototypes(opts))["artillery-turret/ao-larva-launcher"]
    for _, field in ipairs({
      "circuit_connector",
      "circuit_wire_max_distance",
      "alert_when_attacking",
      "open_sound",
      "close_sound",
      "mined_sound",
      "damaged_trigger_effect",
    }) do
      assert.are.same(opts.turret[field], t[field], field)
    end
    assert.are_not.equal(opts.turret.circuit_connector, t.circuit_connector)
  end)

  it("stay off Aquilo and space platforms, so they need no heat", function()
    for _, space_travel in ipairs({ false, true }) do
      local opts = Stubs.launcher_opts({ 0, 1 })
      opts.space_travel = space_travel
      local t = Stubs.by_name(LauncherPrototypes.prototypes(opts))
      for _, name in ipairs({ "ao-larva-launcher", "ao-larva-launcher-1" }) do
        local turret = t["artillery-turret/" .. name]
        local want = space_travel and { { property = "pressure", min = 400 } } or nil
        assert.are.same(want, turret.surface_conditions)
        assert.is_nil(turret.heating_energy)
      end
    end
  end)

  it("share no nested table with the vanilla prototypes", function()
    local opts = Stubs.launcher_opts()
    local all = Stubs.by_name(LauncherPrototypes.prototypes(opts))
    local t = all["artillery-turret/ao-larva-launcher"]
    assert.are.same(opts.turret.collision_box, t.collision_box)
    assert.are_not.equal(opts.turret.collision_box, t.collision_box)
    assert.are_not.equal(opts.turret.rotating_sound, t.rotating_sound)
    local f = all["artillery-flare/ao-larva-flare"]
    assert.are_not.equal(opts.flare.pictures, f.pictures)
    assert.are_not.equal(opts.flare.map_color, f.map_color)
    local r = all["capsule/ao-larva-targeting-remote"]
    assert.are_not.equal(opts.remote.flags, r.flags)
  end)

  it("give the level 0 gun 64 tiles, a 5 s cooldown and larva rockets", function()
    local gun = build()["gun/ao-larva-launcher-gun-0"]
    assert.is_true(gun.hidden)
    local a = gun.attack_parameters
    assert.are.equal("projectile", a.type)
    assert.are.equal("ao-larva-rocket", a.ammo_category)
    assert.are.equal(64, a.range)
    assert.are.equal(300, a.cooldown)
    assert.are.equal(8, a.min_range)
  end)

  it("keep the sound and the muzzle of the vanilla cannon on the gun", function()
    local opts = Stubs.launcher_opts()
    local all = Stubs.by_name(LauncherPrototypes.prototypes(opts))
    local a = all["gun/ao-larva-launcher-gun-0"].attack_parameters
    assert.are.same(opts.cannon.sound, a.sound)
    assert.are_not.equal(opts.cannon.sound, a.sound)
    assert.are.same(opts.cannon.projectile_center, a.projectile_center)
    assert.are.same(opts.cannon.projectile_creation_parameters, a.projectile_creation_parameters)
    assert.are.equal(1.6, a.projectile_creation_distance)
  end)

  it("place the level 0 launcher with the launcher item", function()
    local all = build()
    assert.are.equal("ao-larva-launcher", all["item/ao-larva-launcher"].place_result)
    local r = all["recipe/ao-larva-launcher"]
    assert.are.equal(10, r.energy_required)
    assert.are.same({
      { type = "item", name = "steel-plate", amount = 20 },
      { type = "item", name = "iron-gear-wheel", amount = 10 },
      { type = "item", name = "advanced-circuit", amount = 10 },
      { type = "item", name = "pipe", amount = 5 },
    }, r.ingredients)
  end)

  it("make a flare that only larva rockets answer", function()
    local flare = build()["artillery-flare/ao-larva-flare"]
    assert.are.equal("ao-larva-rocket", flare.shot_category)
    assert.are.equal(3600, flare.life_time)
    assert.is_true(flare.hidden)
  end)

  it("make a remote that places the larva flare", function()
    local all = build()
    local remote = all["capsule/ao-larva-targeting-remote"]
    assert.are.same({ type = "artillery-remote", flare = "ao-larva-flare" }, remote.capsule_action)
    assert.are.equal(1, remote.stack_size)
    -- It has a recipe, so it must survive a cleared cursor.
    assert.are.same({ "not-stackable" }, remote.flags)
    assert.are.same({
      { type = "item", name = "electronic-circuit", amount = 1 },
      { type = "item", name = "radar", amount = 1 },
      { type = "item", name = "coal", amount = 1 },
      { type = "item", name = "sulfur", amount = 1 },
    }, all["recipe/ao-larva-targeting-remote"].ingredients)
  end)

  it("unlock the launcher and the remote with Larva rockets", function()
    local tech = build()["technology/ao-larva-rockets"]
    assert.are.same({ "ao-ordnance-loading", "rocketry" }, tech.prerequisites)
    assert.are.equal(200, tech.unit.count)
    assert.are.same({
      { type = "unlock-recipe", recipe = "ao-larva-launcher" },
      { type = "unlock-recipe", recipe = "ao-larva-targeting-remote" },
    }, tech.effects)
  end)

  it("speed up larva rockets alone, 20% per level, in a chain", function()
    local all = build()
    for level, count in ipairs({ 150, 250, 400 }) do
      local tech = all["technology/ao-larva-launcher-speed-" .. level]
      assert.are.equal(count, tech.unit.count)
      assert.is_true(tech.upgrade)
      assert.are.same(
        { { type = "gun-speed", ammo_category = "ao-larva-rocket", modifier = 0.2 } },
        tech.effects
      )
      local before = level == 1 and "ao-larva-rockets" or "ao-larva-launcher-speed-" .. (level - 1)
      assert.are.same({ before }, tech.prerequisites)
    end
  end)

  it("build only the levels it is asked for", function()
    local all = build({ 0 })
    assert.is_nil(all["artillery-turret/ao-larva-launcher-1"])
  end)
end)

describe("the launcher levels", function()
  local all = build({ 0, 1, 2, 3 })

  it("build one turret and one gun per level", function()
    for level, range in pairs({ [0] = 64, [1] = 80, [2] = 96, [3] = 112 }) do
      local turret = all["artillery-turret/" .. Launcher.name(level)]
      assert.truthy(turret, "no turret for level " .. level)
      assert.are.equal(Launcher.gun(level), turret.gun)
      local gun = all["gun/" .. Launcher.gun(level)]
      assert.are.equal(range, gun.attack_parameters.range)
      assert.are.equal(1.5, turret.manual_range_modifier)
    end
  end)

  it("hide levels 1 to 3 and let the launcher item place them", function()
    for level = 1, 3 do
      local turret = all["artillery-turret/" .. Launcher.name(level)]
      assert.is_true(turret.hidden)
      assert.are.same({ item = "ao-larva-launcher", count = 1 }, turret.placeable_by)
      assert.are.equal("ao-larva-launcher", turret.minable.result)
    end
  end)

  it("give no level a fast-replace group or a next upgrade", function()
    for level = 0, 3 do
      local turret = all["artillery-turret/" .. Launcher.name(level)]
      assert.is_nil(turret.fast_replaceable_group)
      assert.is_nil(turret.next_upgrade)
    end
  end)

  it("add three range technologies with no effects", function()
    local u = Balance.upgrade_research
    for i = 1, 3 do
      local tech = all["technology/ao-larva-launcher-range-" .. i]
      assert.truthy(tech, "no range tech " .. i)
      assert.are.same({}, tech.effects)
      local before = i == 1 and "ao-larva-rockets" or "ao-larva-launcher-range-" .. (i - 1)
      assert.are.same({ before }, tech.prerequisites)
      assert.are.equal(u.counts[i], tech.unit.count)
      assert.are.equal(u.time, tech.unit.time)
      assert.is_true(tech.upgrade)
      -- The packs are not in Balance: the range chain uses the speed chain's.
      local speed = all["technology/ao-larva-launcher-speed-" .. i]
      assert.are.same(speed.unit.ingredients, tech.unit.ingredients)
      assert.are.equal(4, #tech.unit.ingredients)
    end
  end)
end)
