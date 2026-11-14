-- Enforces the rules in docs/architecture.md.

local A = require("spec.support.architecture")

local function read(path)
  local f = assert(io.open(path, "r"), "cannot open " .. path)
  local s = f:read("*a")
  f:close()
  return s
end

local function check(fn, path)
  return fn(path, read(path))
end

describe("the architecture checks", function()
  it("catch a game API name in a core module", function()
    local problems = check(A.core_problems, "spec/fixtures/bad_core_api.lua")
    assert.are.equal(1, #problems)
    assert.truthy(problems[1]:find("game", 1, true))
  end)

  it("catch the other runtime globals", function()
    local problems = check(A.core_problems, "spec/fixtures/bad_core_globals.lua")
    assert.are.equal(3, #problems)
  end)

  it("catch a global after the concat operator", function()
    assert.are.equal(1, #check(A.core_problems, "spec/fixtures/bad_core_concat.lua"))
  end)

  it("catch math.random", function()
    assert.are.equal(1, #check(A.random_problems, "spec/fixtures/bad_random.lua"))
  end)

  it("ignore comments, strings and longer names", function()
    assert.are.same({}, check(A.core_problems, "spec/fixtures/good_core.lua"))
  end)

  it("find Lua files in a folder", function()
    local files = A.lua_files("spec/fixtures")
    assert.are.same({
      "spec/fixtures/bad_core_api.lua",
      "spec/fixtures/bad_core_concat.lua",
      "spec/fixtures/bad_core_globals.lua",
      "spec/fixtures/bad_random.lua",
      "spec/fixtures/good_core.lua",
    }, files)
  end)

  it("return an empty list for a missing folder", function()
    assert.are.same({}, A.lua_files("no/such/folder"))
  end)
end)

describe("the repository", function()
  it("keeps the core free of the game API", function()
    for _, path in ipairs(A.lua_files("core")) do
      assert.are.same({}, check(A.core_problems, path))
    end
  end)

  it("never uses math.random in core/, shell/ or control.lua", function()
    local paths = A.lua_files("core")
    for _, path in ipairs(A.lua_files("shell")) do
      paths[#paths + 1] = path
    end
    if io.open("control.lua") then
      paths[#paths + 1] = "control.lua"
    end
    for _, path in ipairs(paths) do
      assert.are.same({}, check(A.random_problems, path))
    end
  end)
end)
