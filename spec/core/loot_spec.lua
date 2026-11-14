local Loot = require("core.loot")

describe("the nest loot", function()
  it("drops nothing before the research", function()
    assert.is_nil(Loot.drop("biter-spawner", false, 0.5))
  end)

  it("drops nothing from a spawner of no species", function()
    assert.is_nil(Loot.drop("gleba-spawner", true, 0.5))
  end)

  it("drops 1 to 3 eggs of the spawner's species", function()
    assert.are.same({ name = "ao-biter-egg", count = 1 }, Loot.drop("biter-spawner", true, 0))
    assert.are.same({ name = "ao-spitter-egg", count = 2 }, Loot.drop("spitter-spawner", true, 0.5))
    assert.are.same(
      { name = "ao-biter-egg", count = 3 },
      Loot.drop("biter-spawner", true, 0.999999)
    )
  end)

  it("drops the eggs beside the spawner's corpse", function()
    assert.are.same({ x = 14, y = 5 }, Loot.beside({ x = 10, y = 5 }, 2.5))
  end)

  it("labels a drop with its count, icon and name", function()
    assert.are.same(
      { "", "+2 [item=ao-biter-egg] ", { "item-name.ao-biter-egg" } },
      Loot.label({ name = "ao-biter-egg", count = 2 })
    )
  end)
end)
