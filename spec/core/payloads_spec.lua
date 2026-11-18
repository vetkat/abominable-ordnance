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

  it("names a larva rocket's landing effect and projectile", function()
    local acid = Payloads.ALL[2]
    assert.are.equal("ao-land-spitter-acid", Payloads.land_id(SPITTER, acid))
    assert.are.equal("ao-larva-projectile-spitter-acid", Payloads.projectile_name(SPITTER, acid))
  end)

  it("decodes a landing effect, and only a landing effect", function()
    local species, payload = Payloads.decode_land("ao-land-biter-poison")
    assert.are.equal(BITER, species)
    assert.are.equal("poison", payload.name)
    assert.is_nil(Payloads.decode_land("ao-hatch-biter-poison"))
    assert.is_nil(Payloads.decode_land("ao-land-worm-poison"))
    assert.is_nil(Payloads.decode("ao-land-biter-poison"))
  end)
end)

describe("the target rules", function()
  it("let explosive hurt every class", function()
    for _, class in ipairs(Payloads.CLASSES) do
      assert.is_true(Payloads.hits("explosive", class), class)
    end
  end)

  it("let poison hurt organics only", function()
    assert.is_true(Payloads.hits("poison", "organic"))
    assert.is_false(Payloads.hits("poison", "rock"))
    assert.is_false(Payloads.hits("poison", "building"))
  end)

  it("let acid hurt everything except rocks", function()
    assert.is_true(Payloads.hits("acid", "organic"))
    assert.is_true(Payloads.hits("acid", "building"))
    assert.is_false(Payloads.hits("acid", "rock"))
  end)

  it("hurt nothing for an unknown payload or class", function()
    assert.is_false(Payloads.hits("glitter", "organic"))
    assert.is_false(Payloads.hits("explosive", "cloud"))
  end)

  it("give each payload its own damage type", function()
    assert.are.equal("explosion", Payloads.damage_type("explosive"))
    assert.are.equal("acid", Payloads.damage_type("acid"))
    assert.are.equal("poison", Payloads.damage_type("poison"))
    assert.is_nil(Payloads.damage_type("glitter"))
  end)
end)

describe("the payload numbers", function()
  it("all live in Balance.payload_damage", function()
    local d = Balance.payload_damage
    for _, name in ipairs({ "explosive", "poison", "acid", "trail" }) do
      assert.is_number(d[name].damage, name)
      assert.is_number(d[name].radius, name)
    end
    assert.is_number(d.poison.ticks)
    assert.is_number(d.acid.ticks)
    local keys = { "hazard_interval", "hazard_hits", "hazard_visits", "detonation_batch" }
    for _, key in ipairs(keys) do
      assert.is_number(d[key], key)
    end
  end)

  it("come from Payloads.numbers by payload name", function()
    assert.are.equal(Balance.payload_damage.acid, Payloads.numbers("acid"))
    assert.is_nil(Payloads.numbers("glitter"))
    assert.is_nil(Payloads.numbers("hazard_hits"))
  end)
end)

describe("the death plans", function()
  local p = { x = 10, y = 20 }
  local function all()
    return true
  end

  it("show an explosion and deal one hit for an explosive payload", function()
    assert.are.same({
      {
        payload = "explosive",
        entities = { { name = "big-explosion", position = p } },
        hit = { damage = 150, radius = 4 },
      },
    }, Payloads.on_death({ "explosive" }, p, all))
  end)

  it("leave a cloud look-alike and a hazard for a poison payload", function()
    assert.are.same({
      {
        payload = "poison",
        entities = { { name = "ao-poison-cloud", position = p } },
        hazard = { ticks = 1200 },
      },
    }, Payloads.on_death({ "poison" }, p, all))
  end)

  it("spread five pool look-alikes with one hazard for an acid payload", function()
    local d = Balance.acid_spread
    local plan = Payloads.on_death({ "acid" }, p, all)[1]
    assert.are.equal("acid", plan.payload)
    assert.is_nil(plan.hit)
    assert.are.same({ ticks = 900 }, plan.hazard)
    local spots = {}
    for _, e in ipairs(plan.entities) do
      assert.are.equal("ao-acid-pool", e.name)
      spots[#spots + 1] = (e.position.x - 10) / d .. "," .. (e.position.y - 20) / d
    end
    table.sort(spots)
    assert.are.same({ "-1,0", "0,-1", "0,0", "0,1", "1,0" }, spots)
  end)

  it("keep the hazard when the look-alike's prototype is missing", function()
    local function none()
      return false
    end
    local plan = Payloads.on_death({ "poison" }, p, none)[1]
    assert.are.same({}, plan.entities)
    assert.are.same({ ticks = 1200 }, plan.hazard)
  end)

  it("give each entity its own position table", function()
    local entity = Payloads.on_death({ "explosive" }, p, all)[1].entities[1]
    assert.are_not.equal(p, entity.position)
  end)

  it("skip an unknown payload", function()
    assert.are.same({}, Payloads.on_death({ "glitter" }, p, all))
  end)

  it("keep the hit when the explosion's prototype is missing", function()
    local function no_explosion(name)
      return name ~= "big-explosion"
    end
    local plan = Payloads.on_death({ "explosive" }, p, no_explosion)[1]
    assert.are.same({}, plan.entities)
    assert.are.same({ damage = 150, radius = 4 }, plan.hit)
  end)

  it("give one plan per payload, in order", function()
    local plans = Payloads.on_death({ "poison", "explosive" }, p, all)
    assert.are.same({ "poison", "explosive" }, { plans[1].payload, plans[2].payload })
  end)

  it("give acid a live trail", function()
    local live, name = Payloads.live({ "acid" })
    assert.are.same({ lookalike = "ao-acid-puddle", balance_key = "trail" }, live)
    assert.are.equal("acid", name)
  end)

  it("give poison a live aura", function()
    local live, name = Payloads.live({ "poison" })
    assert.are.same({ lookalike = "ao-poison-puff", balance_key = "aura" }, live)
    assert.are.equal("poison", name)
  end)

  it("take the live effect of the first payload that has one", function()
    assert.are.equal("poison", select(2, Payloads.live({ "explosive", "poison", "acid" })))
  end)

  it("give no live effect to explosive or an unknown payload", function()
    assert.are.same({}, { Payloads.live({ "explosive" }) })
    assert.are.same({}, { Payloads.live({ "glitter" }) })
  end)

  it("give the aura 3 damage in radius 3, at most 8 targets", function()
    assert.are.same({ damage = 3, radius = 3, max_targets = 8 }, Balance.payload_damage.aura)
  end)

  it("give only acid a sticker", function()
    assert.are.equal("acid-sticker-big", Payloads.sticker("acid"))
    assert.is_nil(Payloads.sticker("poison"))
    assert.is_nil(Payloads.sticker("glitter"))
  end)
end)
