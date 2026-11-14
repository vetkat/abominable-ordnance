-- The rules from docs/architecture.md, as pure functions. Each check takes
-- a path and the file's source and returns a list of problems.

local lfs = require("lfs")

local M = {}

-- A core module never names these. They are Factorio globals that plain
-- Lua 5.2 lacks. docs_spec.lua checks that docs/architecture.md names the
-- same list.
M.GAME_API = {
  "game",
  "storage",
  "script",
  "defines",
  "prototypes",
  "rendering",
  "helpers",
  "remote",
  "commands",
  "rcon",
  "settings",
  "mods",
  "data",
}

-- Returns the source without comments and string literals, so that a
-- name in a comment or a string does not count.
function M.code_only(src)
  local out, i, n = {}, 1, #src
  while i <= n do
    local c = src:sub(i, i)
    local long = src:match("^%[(=*)%[", i)
    if src:sub(i, i + 1) == "--" then
      local eq = src:match("^%[(=*)%[", i + 2)
      if eq then
        local close = src:find("]" .. eq .. "]", i, true)
        i = close and close + #eq + 2 or n + 1
      else
        i = src:find("\n", i, true) or n + 1
      end
    elseif c == '"' or c == "'" then
      local j = i + 1
      while j <= n and src:sub(j, j) ~= c do
        if src:sub(j, j) == "\\" then
          j = j + 1
        end
        j = j + 1
      end
      out[#out + 1] = " "
      i = j + 1
    elseif long then
      local close = src:find("]" .. long .. "]", i, true)
      out[#out + 1] = " "
      i = close and close + #long + 2 or n + 1
    else
      out[#out + 1] = c
      i = i + 1
    end
  end
  return table.concat(out)
end

-- True when the code uses name as a global. A field (t.name) or a method
-- (t:name) with the same name does not count, but the concat operator
-- (x .. name) does.
local function names(code, name)
  for pos in code:gmatch("()%f[%w_]" .. name .. "%f[^%w_]") do
    local before = code:sub(1, pos - 1)
    local dots = before:match("(%.+)%s*$")
    if dots ~= "." and not before:match(":%s*$") then
      return true
    end
  end
  return false
end

function M.core_problems(path, src)
  local code, problems = M.code_only(src), {}
  for _, name in ipairs(M.GAME_API) do
    if names(code, name) then
      problems[#problems + 1] = path
        .. " names "
        .. name
        .. ", but a core module never touches the game"
    end
  end
  return problems
end

function M.random_problems(path, src)
  if M.code_only(src):find("%f[%w_]math%s*%.%s*random%f[^%w_]") then
    return { path .. " uses math.random, which shares the map's generator with every mod" }
  end
  return {}
end

-- Lists the .lua files under dir, sorted. A missing dir gives {}.
function M.lua_files(dir)
  local files = {}
  if lfs.attributes(dir, "mode") ~= "directory" then
    return files
  end
  for name in lfs.dir(dir) do
    local path = dir .. "/" .. name
    if name:sub(1, 1) ~= "." then
      if lfs.attributes(path, "mode") == "directory" then
        for _, f in ipairs(M.lua_files(path)) do
          files[#files + 1] = f
        end
      elseif name:match("%.lua$") then
        files[#files + 1] = path
      end
    end
  end
  table.sort(files)
  return files
end

return M
