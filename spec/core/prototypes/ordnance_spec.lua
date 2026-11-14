local Lifecycle = require("core.prototypes.lifecycle")
local Ordnance = require("core.prototypes.ordnance")
local Stubs = require("spec.support.stubs")

local function build()
  return Stubs.by_name((Ordnance.prototypes(Stubs.ordnance_opts())))
end

describe("the ordnance prototypes", function()
  it("make larvae that hatch one monster each, with the egg's effect", function()
    local larva = build()["item/ao-biter-larva"]
    assert.are.equal(20, larva.stack_size)
    assert.are.equal(10 * 60 * 60, larva.spoil_ticks)
    local result = larva.spoil_to_trigger_result
    assert.are.equal(1, result.items_per_trigger)
    local effect = result.trigger.action_delivery.source_effects[1]
    assert.are.equal("ao-hatch-biter", effect.effect_id)
  end)

  it("incubate 10 eggs into 1 fresh larva", function()
    local r = build()["recipe/ao-incubate-spitter"]
    assert.are.same({ "ao-incubation" }, r.categories)
    assert.are.same({ type = "item", name = "ao-spitter-egg", amount = 10 }, r.ingredients[1])
    local result = r.results[1]
    assert.are.equal("ao-spitter-larva", result.name)
    assert.are.equal(1, result.amount)
    assert.is_true(result.reset_freshness_on_craft)
    assert.is_false(r.auto_recycle)
    assert.is_false(r.enabled)
  end)

  it("make the incubator a machine of the incubation category", function()
    local all = build()
    local m = all["assembling-machine/ao-incubator"]
    assert.are.same({ "ao-incubation" }, m.crafting_categories)
    assert.are.equal("ao-incubator", all["item/ao-incubator"].place_result)
    assert.truthy(all["recipe-category/ao-incubation"])
    assert.truthy(all["recipe/ao-incubator"])
  end)

  it("let Monster husbandry unlock the incubator and its recipes", function()
    local _, husbandry = Ordnance.prototypes(Stubs.ordnance_opts())
    assert.are.same({ "ao-incubate-biter", "ao-incubate-spitter", "ao-incubator" }, husbandry)
    local opts = Stubs.lifecycle_opts()
    opts.extra_unlocks = husbandry
    local tech = Stubs.by_name(Lifecycle.prototypes(opts))["technology/ao-monster-husbandry"]
    local unlocked = {}
    for _, effect in ipairs(tech.effects) do
      unlocked[effect.recipe] = true
    end
    for _, name in ipairs(husbandry) do
      assert.truthy(unlocked[name], name)
    end
  end)
end)
