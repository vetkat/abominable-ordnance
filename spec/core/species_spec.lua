local Species = require("core.species")

describe("the species table", function()
  it("lists the biter first, then the spitter", function()
    assert.are.equal("biter", Species.ALL[1].name)
    assert.are.equal("spitter", Species.ALL[2].name)
  end)

  it("gives each species its own egg, feed, spawner and effect", function()
    local biter, spitter = Species.ALL[1], Species.ALL[2]
    assert.are.equal("ao-biter-egg", biter.egg)
    assert.are.equal("ao-monster-chow", biter.feed)
    assert.are.equal("biter-spawner", biter.spawner)
    assert.are.equal("ao-hatch-biter", biter.effect_id)
    assert.are.equal("ao-spitter-egg", spitter.egg)
    assert.are.equal("ao-spitter-chow", spitter.feed)
    assert.are.equal("spitter-spawner", spitter.spawner)
    assert.are.equal("ao-hatch-spitter", spitter.effect_id)
  end)

  it("lists only the species' own units", function()
    for _, species in ipairs(Species.ALL) do
      for _, unit in ipairs(species.units) do
        assert.truthy(unit[1]:find(species.name, 1, true), unit[1])
      end
    end
  end)

  it("finds a species by effect ID and by spawner", function()
    assert.are.equal("spitter", Species.by_effect_id("ao-hatch-spitter").name)
    assert.are.equal("biter", Species.by_spawner("biter-spawner").name)
    assert.is_nil(Species.by_effect_id("ao-probe"))
    assert.is_nil(Species.by_spawner("gleba-spawner"))
  end)
end)
