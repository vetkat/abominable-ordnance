local Balance = require("core.balance")
local Trail = require("core.trail")

-- A table with the keys 1 to n, as storage.trails holds unit numbers.
local function keys(n)
  local t = {}
  for i = 1, n do
    t[i] = true
  end
  return t
end

describe("a trail batch", function()
  it("visits at most n keys and returns the last one as the cursor", function()
    local t = keys(12)
    local got, cursor = Trail.batch(t, nil, 5)
    assert.are.equal(5, #got)
    assert.are.equal(got[5], cursor)
  end)

  it("ends the pass with a nil cursor", function()
    local t = keys(3)
    local got, cursor = Trail.batch(t, nil, 5)
    assert.are.equal(3, #got)
    assert.is_nil(cursor)
  end)

  it("gives nothing for an empty table", function()
    local got, cursor = Trail.batch({}, nil, 5)
    assert.are.same({}, got)
    assert.is_nil(cursor)
  end)

  it("starts again when the cursor's key is gone", function()
    local t = keys(4)
    local got = Trail.batch(t, 99, 5)
    assert.are.equal(4, #got)
  end)

  it("covers 300 keys once each in 60 batches of 5", function()
    local t = keys(300)
    local seen, cursor, count = {}, nil, 0
    for _ = 1, 60 do
      local got
      got, cursor = Trail.batch(t, cursor, 5)
      for _, k in ipairs(got) do
        assert.is_nil(seen[k], "key " .. k .. " twice")
        seen[k] = true
        count = count + 1
      end
    end
    assert.are.equal(300, count)
    assert.is_nil(cursor)
  end)

  it("uses a batch of 5 by default", function()
    assert.are.equal(5, Balance.trail_batch)
  end)
end)

describe("forgetting a trail key", function()
  it("moves the cursor past the key that leaves", function()
    local t = keys(6)
    local _, cursor = Trail.batch(t, nil, 2)
    local moved = Trail.forget(t, cursor, cursor)
    assert.are.equal(next(t, cursor), moved)
    t[cursor] = nil
    local got = Trail.batch(t, moved, 10)
    assert.are.equal(6 - 3, #got)
  end)

  it("keeps the cursor when another key leaves", function()
    local t = keys(6)
    local _, cursor = Trail.batch(t, nil, 2)
    local other = cursor == 6 and 5 or 6
    assert.are.equal(cursor, Trail.forget(t, cursor, other))
  end)

  it("keeps a nil cursor", function()
    assert.is_nil(Trail.forget(keys(3), nil, 2))
  end)
end)

describe("the start of a trail pass", function()
  it("starts a pass when the wait is over", function()
    local go, next_tick = Trail.start(nil, 120, 100, 60)
    assert.is_true(go)
    assert.are.equal(180, next_tick)
  end)

  it("starts the first pass at once", function()
    local go, next_tick = Trail.start(nil, 0, nil, 60)
    assert.is_true(go)
    assert.are.equal(60, next_tick)
  end)

  it("waits until the next pass is due", function()
    local go, next_tick = Trail.start(nil, 90, 100, 60)
    assert.is_false(go)
    assert.are.equal(100, next_tick)
  end)

  it("goes on with a pass that is under way", function()
    local go, next_tick = Trail.start(7, 90, 100, 60)
    assert.is_true(go)
    assert.are.equal(100, next_tick)
  end)
end)
