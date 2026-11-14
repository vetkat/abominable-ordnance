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

  it("make six larva rockets that spoil into their loaded effect", function()
    local all = build()
    local count = 0
    for key, p in pairs(all) do
      if key:match("^ammo/ao%-%a+%-larva%-%a+$") then
        count = count + 1
        assert.are.equal(10, p.stack_size, key)
        assert.are.equal(5 * 60 * 60, p.spoil_ticks, key)
        assert.are.equal(1, p.spoil_to_trigger_result.items_per_trigger, key)
        assert.are.equal("ao-larva-rocket", p.ammo_category, key)
      end
    end
    assert.are.equal(6, count)
    local acid = all["ammo/ao-spitter-larva-acid"]
    local effect = acid.spoil_to_trigger_result.trigger.action_delivery.source_effects[1]
    assert.are.equal("ao-hatch-spitter-acid", effect.effect_id)
  end)

  it("fire each larva rocket as its own artillery projectile", function()
    local all = build()
    local rocket = all["ammo/ao-biter-larva-poison"]
    assert.are.equal("position", rocket.ammo_type.target_type)
    local delivery = rocket.ammo_type.action.action_delivery
    assert.are.equal("artillery", delivery.type)
    assert.are.equal("ao-larva-projectile-biter-poison", delivery.projectile)
    assert.truthy(all["artillery-projectile/ao-larva-projectile-biter-poison"])
    assert.truthy(all["ammo-category/ao-larva-rocket"])
  end)

  it("land with an explosion picture, then the landing effect", function()
    local p = build()["artillery-projectile/ao-larva-projectile-spitter-acid"]
    assert.is_false(p.reveal_map)
    assert.is_true(p.hidden)
    assert.truthy(p.map_color)
    local effects = p.action.action_delivery.target_effects
    -- The probe showed that an area trigger with force "enemy" also hurts
    -- the tamed force, so the script deals the blast damage instead.
    assert.are.same({ type = "create-entity", entity_name = "grenade-explosion" }, effects[1])
    assert.are.same({ type = "script", effect_id = "ao-land-spitter-acid" }, effects[2])
    assert.are.equal(2, #effects)
  end)

  it("keep the vanilla projectile's looks without changing it", function()
    local opts = Stubs.ordnance_opts()
    local all = Stubs.by_name((Ordnance.prototypes(opts)))
    local p = all["artillery-projectile/ao-larva-projectile-biter-acid"]
    assert.are.same(opts.projectile.picture, p.picture)
    assert.are_not.equal(opts.projectile.picture, p.picture)
    local vanilla_action = Stubs.ordnance_opts().projectile.action
    assert.are.same(vanilla_action, opts.projectile.action)
    assert.are_not.equal(opts.projectile.action, p.action)
    assert.are_not.same(vanilla_action, p.action)
  end)

  it("load a larva with one payload item and one casing", function()
    local r = build()["recipe/ao-load-biter-explosive"]
    assert.are.same({ "ao-loading" }, r.categories)
    assert.are.same({
      { type = "item", name = "ao-biter-larva", amount = 1 },
      { type = "item", name = "explosive-rocket", amount = 1 },
      { type = "item", name = "ao-larva-rocket-casing", amount = 1 },
    }, r.ingredients)
    assert.are.equal("ao-biter-larva-explosive", r.results[1].name)
    assert.is_true(r.results[1].reset_freshness_on_craft)
    assert.is_false(r.auto_recycle)
  end)

  it("make the casing from steel, explosives and a circuit", function()
    local all = build()
    assert.are.equal(50, all["item/ao-larva-rocket-casing"].stack_size)
    local r = all["recipe/ao-larva-rocket-casing"]
    assert.are.same({ "crafting" }, r.categories)
    assert.are.equal(5, r.energy_required)
    assert.are.same({
      { type = "item", name = "steel-plate", amount = 2 },
      { type = "item", name = "explosives", amount = 1 },
      { type = "item", name = "electronic-circuit", amount = 1 },
    }, r.ingredients)
  end)

  it("make the loading chamber a machine of the loading category", function()
    local all = build()
    local m = all["assembling-machine/ao-loading-chamber"]
    assert.are.same({ "ao-loading" }, m.crafting_categories)
    assert.are.equal("ao-loading-chamber", all["item/ao-loading-chamber"].place_result)
    assert.truthy(all["recipe-category/ao-loading"])
  end)

  it("unlock the chamber and the load recipes with Ordnance loading", function()
    local tech = build()["technology/ao-ordnance-loading"]
    assert.are.same({ "ao-monster-husbandry", "explosive-rocketry" }, tech.prerequisites)
    local unlocked = {}
    for _, effect in ipairs(tech.effects) do
      unlocked[effect.recipe] = true
    end
    assert.truthy(unlocked["ao-loading-chamber"])
    assert.truthy(unlocked["ao-larva-rocket-casing"])
    for _, species in ipairs({ "biter", "spitter" }) do
      for _, payload in ipairs({ "explosive", "acid", "poison" }) do
        assert.truthy(unlocked["ao-load-" .. species .. "-" .. payload])
      end
    end
  end)
end)
