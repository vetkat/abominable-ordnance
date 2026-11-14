-- Splits the acid trail into small batches, so that its cost per tick
-- stays fixed when many monsters walk. Pure: it reads only its
-- parameters.
local Trail = {}

-- Up to n keys of t after cursor, and the cursor for the next call. The
-- cursor is nil when the pass reached the end of t. A cursor whose key
-- left t counts as the start of t.
function Trail.batch(t, cursor, n)
  if cursor ~= nil and t[cursor] == nil then
    cursor = nil
  end
  local got = {}
  local key = cursor
  for _ = 1, n do
    key = next(t, key)
    if key == nil then
      break
    end
    got[#got + 1] = key
  end
  if key ~= nil and next(t, key) == nil then
    key = nil
  end
  return got, key
end

-- The cursor to keep when key leaves t. Call it while t[key] still
-- exists: next() needs the key in the table.
function Trail.forget(t, cursor, key)
  if cursor ~= nil and cursor == key then
    return next(t, key)
  end
  return cursor
end

-- Returns true when the handler works this tick. It also returns the
-- tick when the next pass may start. A new pass starts at most once per
-- interval, so a few monsters still leave one puddle a second.
function Trail.start(cursor, tick, next_tick, interval)
  if cursor ~= nil then
    return true, next_tick
  end
  if tick < (next_tick or 0) then
    return false, next_tick
  end
  return true, tick + interval
end

return Trail
