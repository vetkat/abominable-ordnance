local Balance = require("core.balance")
local Payloads = require("core.payloads")
local Species = require("core.species")

local BITER, SPITTER = Species.ALL[1], Species.ALL[2]

describe("the payload table", function()
  it("lists explosive, acid and poison, with their items", function()
    local names, items = {}, {}
    for i, p in ipairs(Payloads.ALL) do
      names[i], items[i] = p.name, p.item
    end
    assert.are.same({ "explosive", "acid", "poison" }, names)
    assert.are.same({ "explosive-rocket", "sulfuric-acid-barrel", "poison-capsule" }, items)
  end)

  it("names a loaded larva and its effect", function()
    local acid = Payloads.ALL[2]
    assert.are.equal("ao-spitter-larva-acid", Payloads.loaded_name(SPITTER, acid))
    assert.are.equal("ao-hatch-spitter-acid", Payloads.effect_id(SPITTER, acid))
    assert.are.equal("ao-load-spitter-acid", Payloads.load_recipe(SPITTER, acid))
  end)

  it("decodes a loaded effect into its species and payload", function()
    local species, payload = Payloads.decode("ao-hatch-biter-poison")
    assert.are.equal(BITER, species)
    assert.are.equal("poison", payload.name)
    assert.is_nil(Payloads.decode("ao-hatch-biter"))
    assert.is_nil(Payloads.decode("ao-hatch-worm-poison"))
  end)
end)
describe("the payload effects", function()
  local p = { x = 10, y = 20 }
  local function all()
    return true
  end

  it("fire a rocket at the death spot for an explosive payload", function()
    assert.are.same(
      { { name = "explosive-rocket", position = p, target = p, speed = 1 } },
      Payloads.on_death({ "explosive" }, p, all)
    )
  end)

  it("leave a poison cloud for a poison payload", function()
    assert.are.same(
      { { name = "poison-cloud", position = p } },
      Payloads.on_death({ "poison" }, p, all)
    )
  end)

  it("spread five acid puddles for an acid payload", function()
    local d = Balance.acid_spread
    local spots = {}
    for _, e in ipairs(Payloads.on_death({ "acid" }, p, all)) do
      assert.are.equal("acid-splash-fire-spitter-big", e.name)
      spots[#spots + 1] = (e.position.x - 10) / d .. "," .. (e.position.y - 20) / d
    end
    table.sort(spots)
    assert.are.same({ "-1,0", "0,-1", "0,0", "0,1", "1,0" }, spots)
  end)

  it("give each effect its own position table", function()
    local rocket = Payloads.on_death({ "explosive" }, p, all)[1]
    assert.are_not.equal(p, rocket.position)
  end)

  it("skip an unknown payload", function()
    assert.are.same({}, Payloads.on_death({ "glitter" }, p, all))
  end)

  it("leave out an effect whose prototype is missing", function()
    local function no_rocket(name)
      return name ~= "explosive-rocket"
    end
    assert.are.same({}, Payloads.on_death({ "explosive" }, p, no_rocket))
  end)

  it("give acid a trail and no other payload one", function()
    assert.are.equal("acid-splash-fire-spitter-small", Payloads.trail({ "acid" }))
    assert.are.equal("acid-splash-fire-spitter-small", Payloads.trail({ "poison", "acid" }))
    assert.is_nil(Payloads.trail({ "poison" }))
  end)
end)
