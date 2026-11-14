-- Checks on the locale files. In the game, all of these failures are
-- silent: a broken value shows as cut-off text, and a broken key shows as
-- the raw key.

local L = require("spec.support.locale")

local Lifecycle = require("core.prototypes.lifecycle")
local Ordnance = require("core.prototypes.ordnance")
local Stubs = require("spec.support.stubs")

local SECTION = {
  item = "item-name",
  recipe = "recipe-name",
  technology = "technology-name",
  ["assembling-machine"] = "entity-name",
}

local function read(path)
  local f = assert(io.open(path, "r"), "cannot open " .. path)
  local s = f:read("*a")
  f:close()
  return s
end

describe("the locale checks", function()
  it("accept sections, keys and comments", function()
    assert.are.same({}, L.problems("x.cfg", "; comment\n[a]\nk=v\n\n# also\n"))
  end)

  it("catch a semicolon in a value", function()
    assert.are.equal(1, #L.problems("x.cfg", "[a]\nk=one; two\n"))
  end)

  it("catch a key outside a section", function()
    assert.are.equal(1, #L.problems("x.cfg", "k=v\n"))
  end)

  it("catch a line that is not key=value", function()
    assert.are.equal(1, #L.problems("x.cfg", "[a]\njust text\n"))
  end)

  it("read a value", function()
    assert.are.equal("v", L.value("[a]\nk=v\n", "a", "k"))
    assert.is_nil(L.value("[a]\nk=v\n", "b", "k"))
  end)
end)

describe("locale/en/locale.cfg", function()
  local text = read("locale/en/locale.cfg")

  it("names every prototype", function()
    local all = Lifecycle.prototypes(Stubs.lifecycle_opts(true))
    for _, p in ipairs((Ordnance.prototypes(Stubs.ordnance_opts()))) do
      all[#all + 1] = p
    end
    for _, p in ipairs(all) do
      local section = SECTION[p.type]
      if section then
        assert.truthy(L.value(text, section, p.name), section .. "." .. p.name)
      end
    end
  end)

  it("has no problems", function()
    assert.are.same({}, L.problems("locale/en/locale.cfg", text))
  end)

  it("names the mod with the title from info.json", function()
    local title = read("info.json"):match('"title"%s*:%s*"(.-)"')
    assert.are.equal(title, L.value(text, "mod-name", "abominable-ordnance"))
  end)

  it("describes the mod", function()
    assert.truthy(L.value(text, "mod-description", "abominable-ordnance"))
  end)
end)
