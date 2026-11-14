-- Splits the acid trail into small batches, so that its cost per tick
-- stays fixed when many monsters walk. Pure: it reads only its
-- parameters.
local Trail = {}

-- Up to n keys of t from cursor on, and the cursor for the next call. The
-- cursor is the next key to visit, and nil when the pass reached the end
-- of t. A cursor whose key left t counts as the start of t.
function Trail.batch(t, cursor, n)
  local key = cursor
  if key == nil or t[key] == nil then
    key = next(t)
  end
  local got = {}
  for _ = 1, n do
    if key == nil then
      break
    end
    got[#got + 1] = key
    key = next(t, key)
  end
  return got, key
end

-- The cursor to keep when key leaves t. Call it while t[key] still
-- exists, because next() needs the key in the table. A cursor on a key
-- that is not in t ends the pass.
function Trail.forget(t, cursor, key)
  if cursor ~= key then
    return cursor
  end
  if cursor == nil or t[key] == nil then
    return nil
  end
  return next(t, key)
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
