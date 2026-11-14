local Forces = require("core.forces")

describe("the force rules", function()
  it("keep peace between the tamed force and player forces", function()
    assert.is_true(Forces.cease_fire("player"))
    assert.is_true(Forces.cease_fire("team-2"))
  end)

  it("keep the tamed force at war with the natives", function()
    assert.is_false(Forces.cease_fire("enemy"))
  end)

  it("leave the neutral force and the tamed force alone", function()
    assert.is_nil(Forces.cease_fire("neutral"))
    assert.is_nil(Forces.cease_fire("ao-tamed"))
  end)

  it("let a researched force or the tamed force earn nest loot", function()
    assert.is_true(Forces.earns_loot("player", true))
    assert.is_false(Forces.earns_loot("player", false))
    assert.is_true(Forces.earns_loot("ao-tamed", false))
  end)
end)
