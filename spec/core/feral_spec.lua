local Balance = require("core.balance")
local Feral = require("core.feral")
local Names = require("core.names")

local f = Balance.feral

describe("the feral names and numbers", function()
  it("name the feral force", function()
    assert.are.equal("ao-feral", Names.FERAL)
  end)

  it("keep every feral number in Balance.feral", function()
    for key, value in pairs(f) do
      assert.is_number(value, key)
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

  it("is total for an entry without payloads", function()
    assert.is_true(Feral.too_close({}, 0, "small-biter"))
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

  it("returns a boolean even for a missing failure", function()
    assert.is_false(Feral.marks(nil, false, true))
  end)
end)

describe("the player test", function()
  it("counts a player with a character at peace, off a platform", function()
    assert.is_true(Feral.player_counts(true, true, false))
  end)

  it("skips a player without a character, at war or on a platform", function()
    assert.is_false(Feral.player_counts(false, true, false))
    assert.is_false(Feral.player_counts(true, false, false))
    assert.is_false(Feral.player_counts(true, true, true))
  end)
end)

describe("the idle and unstable decision", function()
  local function entry(fields)
    local e = { payloads = { "explosive" } }
    for k, v in pairs(fields) do
      e[k] = v
    end
    return e
  end

  it("turns a monster feral after idle_ticks of idling", function()
    assert.is_false(Feral.decide(entry({}), 1000, 0.99))
    assert.is_false(Feral.decide(entry({ idle_since = 1000 }), 1000 + f.idle_ticks - 1, 0.99))
    assert.is_true(Feral.decide(entry({ idle_since = 1000 }), 1000 + f.idle_ticks, 0.99))
  end)

  it("never rolls on the first check", function()
    assert.are.equal(0, Feral.unstable_chance(1, 0))
    assert.is_false(Feral.decide(entry({}), 600, 0))
  end)

  it("rolls the chance for the time since the last check", function()
    local chance = 1 - (1 - f.unstable_per_minute) ^ (600 / 3600)
    assert.are.near(chance, Feral.unstable_chance(1, 600), 1e-12)
    local e = entry({ checked_at = 0 })
    assert.is_true(Feral.decide(e, 600, chance / 2))
    assert.is_false(Feral.decide(e, 600, chance * 2))
  end)

  it("grows the chance with each payload", function()
    assert.is_true(Feral.unstable_chance(2, 600) > Feral.unstable_chance(1, 600))
  end)

  it("never decides for a feral entry", function()
    assert.is_false(Feral.decide(entry({ feral = true, idle_since = 0 }), 10 ^ 9, 0))
  end)

  it("copes with an entry that has no payload list", function()
    assert.is_false(Feral.decide({ checked_at = 0 }, 600, 0))
  end)
end)
