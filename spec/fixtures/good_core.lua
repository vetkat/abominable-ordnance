-- The word game in a comment is fine.
local s = "storage in a string is fine"
local t = [[ script in a long string is fine ]]
-- A field or method with a global's name is fine too.
local T = {}
function T.prototypes(opts)
  return opts.data, T:settings()
end
local M = { gamey = s, t = t, T = T }
return M
