local Forces = require("core.forces")

describe("the force rules", function()
  it("keep peace between the tamed force and player forces", function()
    assert.is_true(Forces.peaceful("player"))
    assert.is_true(Forces.peaceful("team-2"))
  end)

  it("keep the tamed force hostile to the natives", function()
    assert.is_false(Forces.peaceful("enemy"))
    assert.is_false(Forces.peaceful("neutral"))
    assert.is_false(Forces.peaceful("ao-tamed"))
  end)
end)
