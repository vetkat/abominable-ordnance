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
    assert.are.equal("ao-load-spitter-acid", Payloads.effect_id(SPITTER, acid))
  end)

  it("decodes a loaded effect into its species and payload", function()
    local species, payload = Payloads.decode("ao-load-biter-poison")
    assert.are.equal(BITER, species)
    assert.are.equal("poison", payload.name)
    assert.is_nil(Payloads.decode("ao-hatch-biter"))
    assert.is_nil(Payloads.decode("ao-load-worm-poison"))
  end)
end)
