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
