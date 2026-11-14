local Launcher = require("core.launcher")

describe("the launcher levels", function()
  it("name level 0 after the item, and the others with a number", function()
    assert.are.equal("ao-larva-launcher", Launcher.name(0))
    assert.are.equal("ao-larva-launcher-2", Launcher.name(2))
  end)

  it("treat a missing or unknown level as level 0", function()
    assert.are.equal("ao-larva-launcher", Launcher.name(nil))
    assert.are.equal("ao-larva-launcher", Launcher.name(7))
    assert.are.equal(64, Launcher.range(nil))
    assert.are.equal(64, Launcher.range(-1))
  end)

  it("treat a fractional or non-number level as level 0", function()
    for _, level in ipairs({ 1.5, "2" }) do
      assert.are.equal("ao-larva-launcher", Launcher.name(level))
      assert.are.equal(64, Launcher.range(level))
      assert.are.equal("ao-larva-launcher-gun-0", Launcher.gun(level))
    end
    assert.are.equal("ao-larva-launcher-gun-0", Launcher.gun(7))
    assert.are.equal("ao-larva-launcher-gun-0", Launcher.gun(nil))
  end)

  it("list all four names", function()
    assert.are.same({
      "ao-larva-launcher",
      "ao-larva-launcher-1",
      "ao-larva-launcher-2",
      "ao-larva-launcher-3",
    }, Launcher.NAMES)
  end)

  it("give each level 16 more tiles of range", function()
    assert.are.same(
      { 64, 80, 96, 112 },
      { Launcher.range(0), Launcher.range(1), Launcher.range(2), Launcher.range(3) }
    )
  end)

  it("read the level back from a name", function()
    assert.are.equal(0, Launcher.level_of("ao-larva-launcher"))
    assert.are.equal(3, Launcher.level_of("ao-larva-launcher-3"))
    assert.is_nil(Launcher.level_of("artillery-turret"))
  end)

  it("give each level its own gun", function()
    assert.are.equal("ao-larva-launcher-gun-0", Launcher.gun(0))
    assert.are.equal("ao-larva-launcher-gun-3", Launcher.gun(3))
  end)
end)

describe("the launcher level from research", function()
  local function researched(...)
    local done = {}
    for _, name in ipairs({ ... }) do
      done[name] = true
    end
    return function(name)
      return done[name] == true
    end
  end

  it("is 0 with no range research", function()
    assert.are.equal(0, Launcher.level(researched()))
  end)

  it("is the highest finished range research", function()
    assert.are.equal(
      2,
      Launcher.level(researched("ao-larva-launcher-range-1", "ao-larva-launcher-range-2"))
    )
  end)

  it("takes the highest level even when a lower one is missing", function()
    -- The editor or a command can research level 3 alone.
    assert.are.equal(3, Launcher.level(researched("ao-larva-launcher-range-3")))
  end)

  it("ignores other technologies", function()
    assert.are.equal(0, Launcher.level(researched("ao-larva-rockets")))
  end)

  it("knows the range technologies", function()
    assert.is_true(Launcher.is_range_tech("ao-larva-launcher-range-1"))
    assert.is_true(Launcher.is_range_tech("ao-larva-launcher-range-3"))
    assert.is_false(Launcher.is_range_tech("ao-larva-launcher-range-4"))
    assert.is_false(Launcher.is_range_tech("ao-larva-launcher-speed-1"))
  end)

  it("reads no level from a name that is not a launcher", function()
    assert.is_nil(Launcher.level_of("ao-larva-launcher-4"))
  end)
end)

describe("the swap steps", function()
  it("create after a destroy, and finish after a create", function()
    assert.are.equal("create", Launcher.after("destroy", true))
    assert.are.equal("finish", Launcher.after("create", true))
    assert.are.equal("finish", Launcher.after("create_old", true))
  end)

  it("give the ammo back when the destroy fails", function()
    assert.are.equal("give_back", Launcher.after("destroy", false))
  end)

  it("restore the old launcher, then spill, when creates fail", function()
    assert.are.equal("create_old", Launcher.after("create", false))
    assert.are.equal("spill", Launcher.after("create_old", false))
  end)

  it("stop after any other step", function()
    assert.are.equal("stop", Launcher.after("finish", true))
    assert.are.equal("stop", Launcher.after("spill", false))
    assert.are.equal("stop", Launcher.after("nonsense", true))
  end)
end)

describe("the leftovers of a swap", function()
  it("are nothing when no ammo is left and no launcher is lost", function()
    assert.are.same({}, Launcher.leftovers(false, nil))
  end)

  it("are the ammo marker when ammo is left", function()
    assert.are.same({ "ammo" }, Launcher.leftovers(true, nil))
  end)

  it("are one launcher item of the lost quality", function()
    assert.are.same(
      { { name = "ao-larva-launcher", count = 1, quality = "rare" } },
      Launcher.leftovers(false, "rare")
    )
  end)

  it("are the ammo marker first, then the launcher item", function()
    assert.are.same(
      { "ammo", { name = "ao-larva-launcher", count = 1, quality = "normal" } },
      Launcher.leftovers(true, "normal")
    )
  end)
end)
