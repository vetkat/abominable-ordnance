local Hazards = require("core.hazards")

-- Small budgets, so a test can hit them with a few hazards.
local N = { hazard_interval = 30, hazard_hits = 2, hazard_visits = 3 }

-- n hazards, each due at tick 100 unless last_hit says otherwise.
local function hazards(n, last_hit)
  local t = {}
  for i = 1, n do
    t[i] = { last_hit = last_hit or 70, end_tick = 1000 }
  end
  return t
end

describe("a new hazard", function()
  it("has its first hit due at once and ends after its ticks", function()
    local p = { x = 1, y = 2 }
    local h = Hazards.new(1, p, "poison", "ao-tamed", 100, 1200, 30)
    assert.are.same({
      surface = 1,
      position = { x = 1, y = 2 },
      payload = "poison",
      force = "ao-tamed",
      last_hit = 70,
      end_tick = 1300,
    }, h)
    assert.are_not.equal(p, h.position)
    assert.are.equal(1, Hazards.due(h, 100, 30))
  end)
end)

describe("the due hits", function()
  local h = { last_hit = 100, end_tick = 400 }

  it("count no hit before a whole interval", function()
    assert.are.equal(0, Hazards.due(h, 129, 30))
  end)

  it("count one hit after one interval", function()
    assert.are.equal(1, Hazards.due(h, 130, 30))
  end)

  it("catch up on every whole interval of a late visit", function()
    assert.are.equal(3, Hazards.due(h, 195, 30))
  end)

  it("stop counting at the end tick", function()
    assert.are.equal(10, Hazards.due(h, 5000, 30))
  end)
end)

describe("the hazard pass", function()
  it("hits each due hazard and moves its last hit", function()
    local plan = Hazards.plan(hazards(2), nil, 100, N)
    assert.are.same({
      { id = 1, count = 1, last_hit = 100 },
      { id = 2, count = 1, last_hit = 100 },
    }, plan.hits)
    assert.are.same({}, plan.done)
    assert.is_nil(plan.cursor)
  end)

  it("stops at hazard_hits and resumes at the first hazard it did not hit", function()
    local t = hazards(3)
    local first = Hazards.plan(t, nil, 100, N)
    assert.are.equal(2, #first.hits)
    assert.are.equal(3, first.cursor)
    for _, h in ipairs(first.hits) do
      t[h.id].last_hit = h.last_hit
    end
    local second = Hazards.plan(t, first.cursor, 101, N)
    assert.are.same({ { id = 3, count = 1, last_hit = 100 } }, second.hits)
    assert.is_nil(second.cursor)
  end)

  it("stops at hazard_visits, also with no hit", function()
    local plan = Hazards.plan(hazards(5, 90), nil, 100, N)
    assert.are.same({}, plan.hits)
    assert.are.equal(4, plan.cursor)
  end)

  it("never visits a hazard twice in one tick", function()
    local wide = { hazard_interval = 30, hazard_hits = 10, hazard_visits = 10 }
    local plan = Hazards.plan(hazards(2), 2, 100, wide)
    assert.are.same({ { id = 2, count = 1, last_hit = 100 } }, plan.hits)
    assert.is_nil(plan.cursor)
  end)

  it("deals the last hits of a hazard past its end, then lets it go", function()
    local t = { { last_hit = 940, end_tick = 1000 } }
    local plan = Hazards.plan(t, nil, 1010, N)
    assert.are.same({ { id = 1, count = 2, last_hit = 1000 } }, plan.hits)
    assert.are.same({ 1 }, plan.done)
  end)

  it("lets a finished hazard go without a hit", function()
    local t = { { last_hit = 1000, end_tick = 1000 } }
    local plan = Hazards.plan(t, nil, 1005, N)
    assert.are.same({}, plan.hits)
    assert.are.same({ 1 }, plan.done)
  end)

  it("does nothing for no hazards", function()
    assert.are.same({ hits = {}, done = {} }, Hazards.plan({}, nil, 100, N))
  end)
end)
