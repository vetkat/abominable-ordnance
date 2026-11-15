local Balance = require("core.balance")
local Feral = require("core.feral")
local Names = require("core.names")

local f = Balance.feral

describe("the feral names and numbers", function()
  it("name the feral force", function()
    assert.are.equal("ao-feral", Names.FERAL)
  end)

  it("keep every feral number in Balance.feral", function()
    for _, key in ipairs({
      "radius",
      "per_payload",
      "per_size",
      "max_payloads",
      "scan_ticks",
      "idle_ticks",
      "pass_ticks",
      "batch",
      "search_radius",
      "seek_distance",
      "rewander_ticks",
      "retry_wanders",
      "unstable_per_minute",
      "warning_ticks",
    }) do
      assert.is_number(f[key], key)
    end
  end)
end)

describe("the feral radius", function()
  it("takes the size step from the species lists", function()
    assert.are.equal(0, Feral.size_step("small-biter"))
    assert.are.equal(1, Feral.size_step("medium-spitter"))
    assert.are.equal(2, Feral.size_step("big-biter"))
    assert.are.equal(3, Feral.size_step("behemoth-spitter"))
    assert.are.equal(0, Feral.size_step("some-modded-unit"))
  end)

  it("grows with size and with each extra payload", function()
    assert.are.equal(f.radius, Feral.radius("small-biter", 1))
    assert.are.equal(f.radius + 3 * f.per_size, Feral.radius("behemoth-biter", 1))
    assert.are.equal(f.radius + f.per_payload, Feral.radius("small-biter", 2))
    assert.are.equal(f.radius, Feral.radius("small-biter", nil))
  end)

  it("gives the largest radius of version 1", function()
    local largest = f.radius + f.per_payload * (f.max_payloads - 1) + f.per_size * 3
    assert.are.equal(largest, Feral.largest_radius())
  end)

  it("measures a distance between two positions", function()
    assert.are.equal(5, Feral.distance({ x = 0, y = 0 }, { x = 3, y = 4 }))
  end)
end)

describe("the too-close test", function()
  local entry = { payloads = { "explosive" } }

  it("turns a small monster feral at its radius or closer", function()
    assert.is_true(Feral.too_close(entry, f.radius, "small-biter"))
    assert.is_false(Feral.too_close(entry, f.radius + 0.1, "small-biter"))
  end)

  it("never turns a feral entry feral again", function()
    local feral = { payloads = { "explosive" }, feral = true }
    assert.is_false(Feral.too_close(feral, 0, "small-biter"))
  end)
end)

describe("the failed-hunt mark", function()
  local window = f.retry_wanders * f.rewander_ticks

  it("holds while the last failed hunt is recent", function()
    assert.is_false(Feral.marked({}, 100))
    assert.is_true(Feral.marked({ failed_at = 100 }, 100 + window - 1))
    assert.is_false(Feral.marked({ failed_at = 100 }, 100 + window))
  end)

  it("comes only from a failed hunt without a distraction", function()
    assert.is_true(Feral.marks(true, false, true))
    assert.is_false(Feral.marks(true, true, true))
    assert.is_false(Feral.marks(true, false, false))
    assert.is_false(Feral.marks(false, false, true))
  end)
end)
