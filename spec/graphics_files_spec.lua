-- Every art file that ships is in use, and every path the prototypes name
-- exists. An unused file would only grow the mod zip.
local lfs = require("lfs")
local LauncherPrototypes = require("core.prototypes.launcher")
local Lifecycle = require("core.prototypes.lifecycle")
local Ordnance = require("core.prototypes.ordnance")
local Stasis = require("core.prototypes.stasis")
local Stubs = require("spec.support.stubs")

local PREFIX = "__abominable-ordnance__/"

-- The repository paths of every mod file that value names.
local function named(value, out)
  if type(value) == "string" and value:sub(1, #PREFIX) == PREFIX then
    out[value:sub(#PREFIX + 1)] = true
  elseif type(value) == "table" then
    for _, v in pairs(value) do
      named(v, out)
    end
  end
  return out
end

-- Every file under dir, as repository paths.
local function walk(dir, out)
  if lfs.attributes(dir, "mode") ~= "directory" then
    return out
  end
  for name in lfs.dir(dir) do
    if name ~= "." and name ~= ".." then
      local path = dir .. "/" .. name
      if lfs.attributes(path, "mode") == "directory" then
        walk(path, out)
      else
        out[#out + 1] = path
      end
    end
  end
  return out
end

-- Every prototype of the mod, with the cryo ward built in, because only
-- the cryo ward uses cryo-ward.png.
local function all_prototypes()
  local sources = {}
  for _, p in ipairs(Lifecycle.prototypes(Stubs.lifecycle_opts(true))) do
    sources[#sources + 1] = p
  end
  for _, p in ipairs((Ordnance.prototypes(Stubs.ordnance_opts()))) do
    sources[#sources + 1] = p
  end
  local has = {}
  for _, n in ipairs(Stasis.CRYO.needs) do
    has[Stasis.key(n.type, n.name)] = true
  end
  local kinds = Stasis.kinds({ space_age = true, has = has, pressure = 300 })
  assert.are.equal(2, #kinds)
  return {
    sources,
    Stasis.prototypes(sources, kinds),
    LauncherPrototypes.prototypes(Stubs.launcher_opts()),
  }
end

describe("the art files", function()
  it("uses every shipped art file", function()
    local used = named(all_prototypes(), {})
    local files = walk("sound", walk("graphics", {}))
    assert.is_true(#files > 0)
    for _, path in ipairs(files) do
      assert.is_true(used[path] == true, path .. " ships, but no prototype uses it")
    end
  end)

  it("names only files that exist", function()
    for path in pairs(named(all_prototypes(), {})) do
      assert.are.equal("file", lfs.attributes(path, "mode"), path)
    end
  end)
end)
