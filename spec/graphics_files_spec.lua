-- Every art file that ships is in use, and every path the prototypes name
-- exists. An unused file would only grow the mod zip.
local A = require("spec.support.architecture")
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

-- The width and height of the PNG file at path, from its header.
local function png_size(path)
  local f = assert(io.open(path, "rb"))
  local head = f:read(24)
  f:close()
  local function u32(i)
    local a, b, c, d = head:byte(i, i + 3)
    return ((a * 256 + b) * 256 + c) * 256 + d
  end
  return u32(17), u32(21)
end

-- Every table in value that names a sheet of this mod with a frame size.
local function sheets(value, out)
  if type(value) == "table" then
    if
      type(value.filename) == "string"
      and value.filename:sub(1, #PREFIX) == PREFIX
      and value.width
    then
      out[#out + 1] = value
    end
    for _, v in pairs(value) do
      sheets(v, out)
    end
  end
  return out
end

describe("the art files", function()
  local used, protos

  setup(function()
    assert.are.equal(
      "directory",
      lfs.attributes("graphics", "mode"),
      "run busted from the repository root"
    )
    protos = all_prototypes()
    used = named(protos, {})
  end)

  it("fits every declared frame inside its sheet", function()
    local found = sheets(protos, {})
    assert.is_true(#found > 0)
    for _, s in ipairs(found) do
      local path = s.filename:sub(#PREFIX + 1)
      local w, h = png_size(path)
      local frames = (s.frame_count or 1) * (s.direction_count or 1)
      local line = s.line_length or frames
      local rows = math.ceil(frames / line)
      assert.is_true(s.width * line <= w, path .. ": the frames are wider than the sheet")
      assert.is_true(s.height * rows <= h, path .. ": the frames are taller than the sheet")
    end
  end)

  it("uses every shipped art file", function()
    local files = A.files("graphics", ".")
    for _, path in ipairs(A.files("sound", ".")) do
      files[#files + 1] = path
    end
    assert.is_true(#files > 0)
    for _, path in ipairs(files) do
      assert.is_true(used[path] == true, path .. " ships, but no prototype uses it")
    end
  end)

  it("names only files that exist", function()
    for path in pairs(used) do
      assert.are.equal("file", lfs.attributes(path, "mode"), path)
    end
  end)
end)
