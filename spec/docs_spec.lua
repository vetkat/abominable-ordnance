-- Checks that the docs still describe the code. A rule list in the docs
-- that differs from the test is wrong, and nobody notices until a reader
-- trusts it.

local A = require("spec.support.architecture")

local function read(path)
  local f = assert(io.open(path, "r"), "cannot open " .. path)
  local s = f:read("*a")
  f:close()
  return s
end

-- The names in backticks in the first paragraph that states the core
-- rule ("never names"). A paragraph ends at a blank line.
local function rule_names(text)
  for paragraph in (text .. "\n\n"):gmatch("(.-)\n%s*\n") do
    if paragraph:find("never names", 1, true) then
      local names = {}
      for name in paragraph:gmatch("`([%w_]+)`") do names[#names + 1] = name end
      return names
    end
  end
  return {}
end

describe("docs/architecture.md", function()
  local text = read("docs/architecture.md")

  it("names the same game API as the architecture test", function()
    local names = rule_names(text)
    table.sort(names)
    local expected = {}
    for _, name in ipairs(A.GAME_API) do expected[#expected + 1] = name end
    table.sort(expected)
    assert.are.same(expected, names)
  end)

  it("still forbids math.random", function()
    assert.truthy(text:find("math.random", 1, true))
  end)
end)

describe("the rule finder", function()
  it("reads the names from the rule paragraph, across a line break", function()
    local text = "x\n\nA module never names `a`\nor `b`.\n\nLater `c`.\n"
    assert.are.same({ "a", "b" }, rule_names(text))
  end)

  it("gives an empty list without a rule line", function()
    assert.are.same({}, rule_names("nothing here"))
  end)
end)
