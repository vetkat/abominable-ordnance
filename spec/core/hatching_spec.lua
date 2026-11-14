local Hatching = require("core.hatching")
local Species = require("core.species")

local MEDIUM_BITER = { { 0.2, 0.0 }, { 0.6, 0.3 }, { 0.7, 0.1 } }

describe("the hatch weight", function()
  it("keeps the first value below the first point", function()
    assert.are.equal(0, Hatching.weight(MEDIUM_BITER, 0.1))
  end)

  it("is linear between two points", function()
    assert.is_near(0.15, Hatching.weight(MEDIUM_BITER, 0.4), 1e-9)
    assert.is_near(0.2, Hatching.weight(MEDIUM_BITER, 0.65), 1e-9)
  end)

  it("keeps the last value beyond the last point", function()
    assert.is_near(0.1, Hatching.weight(MEDIUM_BITER, 0.9), 1e-9)
  end)
end)

describe("the hatch pick", function()
  local biter, spitter = Species.ALL[1], Species.ALL[2]

  it("gives a small biter at evolution 0", function()
    assert.are.equal("small-biter", Hatching.pick(biter.units, 0, 0))
    assert.are.equal("small-biter", Hatching.pick(biter.units, 0, 0.999999))
  end)

  it("gives a small spitter at evolution 0, never a biter", function()
    assert.are.equal("small-spitter", Hatching.pick(spitter.units, 0, 0))
    assert.are.equal("small-spitter", Hatching.pick(spitter.units, 0, 0.999999))
  end)

  it("picks by cumulative weight at evolution 1", function()
    -- Weights at 1: small 0, medium 0.1, big 0.4, behemoth 0.3.
    assert.are.equal("medium-biter", Hatching.pick(biter.units, 1, 0))
    assert.are.equal("big-biter", Hatching.pick(biter.units, 1, 0.5))
    assert.are.equal("behemoth-biter", Hatching.pick(biter.units, 1, 0.999999))
  end)
end)
