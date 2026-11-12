-- Pure checks for Factorio's .cfg locale format.

local M = {}

local function lines(text)
  local out = {}
  for line in (text .. "\n"):gmatch("([^\n]*)\n") do
    out[#out + 1] = (line:gsub("\r$", ""))
  end
  return out
end

function M.problems(path, text)
  local problems, section = {}, nil
  for n, line in ipairs(lines(text)) do
    local where = path .. ":" .. n .. ": "
    -- A blank line or a comment needs no check.
    local skip = line:match("^%s*$") or line:match("^%s*[;#]")
    if not skip and line:match("^%[.+%]%s*$") then
      section = line:match("^%[(.+)%]")
    elseif not skip then
      local key, value = line:match("^([^=]+)=(.*)$")
      if not key then
        problems[#problems + 1] = where .. "not a key=value line"
      elseif not section then
        problems[#problems + 1] = where .. "key outside a [section]"
      elseif value:find(";", 1, true) then
        -- The .cfg format may read a semicolon as the start of a comment.
        problems[#problems + 1] = where .. "semicolon in a value"
      end
    end
  end
  return problems
end

function M.value(text, wanted_section, wanted_key)
  local section
  for _, line in ipairs(lines(text)) do
    local name = line:match("^%[(.+)%]%s*$")
    if name then
      section = name
    elseif section == wanted_section then
      local key, value = line:match("^([^=]+)=(.*)$")
      if key == wanted_key then return value end
    end
  end
  return nil
end

return M
