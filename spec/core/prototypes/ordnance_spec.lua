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

describe("the look-alikes", function()
  local function build_with(opts)
    return Stubs.by_name(Ordnance.lookalikes(opts))
  end

  local function lookalikes()
    return build_with(Stubs.lookalike_opts())
  end

  it("are not part of the data stage prototypes", function()
    -- data-final-fixes.lua builds them, so a vanilla effect passed here
    -- by mistake must not make one.
    local opts = Stubs.ordnance_opts()
    local vanilla = Stubs.lookalike_opts()
    opts.cloud, opts.pool, opts.puddle = vanilla.cloud, vanilla.pool, vanilla.puddle
    local all = Stubs.by_name((Ordnance.prototypes(opts)))
    assert.is_nil(all["smoke-with-trigger/ao-poison-cloud"])
    assert.is_nil(all["fire/ao-acid-pool"])
    assert.is_nil(all["fire/ao-acid-puddle"])
    assert.is_nil(all["smoke-with-trigger/ao-poison-puff"])
  end)

  it("make a small puff from the vanilla cloud, with no effects", function()
    local p = lookalikes()["smoke-with-trigger/ao-poison-puff"]
    assert.are.equal("cloud.png", p.animation.filename)
    assert.is_true(p.hidden)
    assert.is_nil(p.action)
    assert.is_nil(p.created_effect)
    assert.are.equal(4, p.particle_count)
    assert.are.same({ 1.5, 0.9 }, p.particle_spread)
    assert.are.equal(60, p.duration)
    assert.are.equal(30, p.fade_away_duration)
    assert.are.equal(20, p.spread_duration)
    assert.is_true(p.fade_away_duration <= p.duration)
  end)

  it("make no puff when the vanilla cloud is missing", function()
    local opts = Stubs.lookalike_opts()
    opts.cloud = nil
    assert.is_nil(build_with(opts)["smoke-with-trigger/ao-poison-puff"])
  end)

  it("leave the vanilla cloud unchanged", function()
    local opts = Stubs.lookalike_opts()
    Ordnance.lookalikes(opts)
    assert.are.equal(1200, opts.cloud.duration)
    assert.is_not_nil(opts.cloud.created_effect)
  end)

  it("copy the vanilla cloud's looks, with no action, for the cloud's time", function()
    local c = lookalikes()["smoke-with-trigger/ao-poison-cloud"]
    assert.are.equal("cloud.png", c.animation.filename)
    assert.is_nil(c.action)
    assert.are.equal(0, c.action_cooldown)
    assert.are.equal(1200, c.duration)
    assert.are.equal("cluster", c.created_effect[1].type)
  end)

  it("copy the vanilla pool's looks, with no damage, no spread and the pool's time", function()
    local p = lookalikes()["fire/ao-acid-pool"]
    assert.are.equal("pool.png", p.pictures[1].filename)
    assert.is_nil(p.on_damage_tick_effect)
    assert.is_nil(p.created_effect)
    assert.is_nil(p.on_fuel_added_action)
    assert.is_nil(p.spawn_entity)
    assert.are.same({ amount = 0, type = "acid" }, p.damage_per_tick)
    assert.are.equal(0, p.maximum_spread_count)
    assert.are.equal(900, p.initial_lifetime)
    assert.are.equal(900, p.maximum_lifetime)
    assert.are.equal(0, p.lifetime_increase_by)
  end)

  it("copy the vanilla trail puddle's looks, with no damage, no spread and its own time", function()
    local p = lookalikes()["fire/ao-acid-puddle"]
    assert.are.equal("puddle.png", p.pictures[1].filename)
    assert.is_nil(p.on_damage_tick_effect)
    assert.is_nil(p.created_effect)
    assert.is_nil(p.on_fuel_added_action)
    assert.is_nil(p.spawn_entity)
    assert.are.same({ amount = 0, type = "acid" }, p.damage_per_tick)
    assert.are.equal(0, p.maximum_spread_count)
    assert.are.equal(600, p.initial_lifetime)
    assert.are.equal(1800, p.maximum_lifetime)
    assert.are.equal(20, p.lifetime_increase_by)
  end)

  it("give the trail puddle the vanilla puddle's damage type as it stands", function()
    local opts = Stubs.lookalike_opts()
    opts.puddle.damage_per_tick.type = "corrosion"
    local p = build_with(opts)["fire/ao-acid-puddle"]
    assert.are.same({ amount = 0, type = "corrosion" }, p.damage_per_tick)
  end)

  it("give the pool the vanilla pool's damage type as it stands", function()
    local opts = Stubs.lookalike_opts()
    opts.pool.damage_per_tick.type = "corrosion"
    local p = build_with(opts)["fire/ao-acid-pool"]
    assert.are.same({ amount = 0, type = "corrosion" }, p.damage_per_tick)
  end)

  it("leave the vanilla prototypes unchanged", function()
    local opts = Stubs.lookalike_opts()
    build_with(opts)
    assert.are.same({ type = "direct" }, opts.cloud.action)
    assert.are.same({ type = "direct" }, opts.pool.on_damage_tick_effect)
    assert.are.equal(5, opts.pool.damage_per_tick.amount)
    assert.are.same({ type = "direct" }, opts.puddle.on_damage_tick_effect)
    assert.are.equal(1, opts.puddle.damage_per_tick.amount)
  end)

  it("skip a look-alike whose vanilla prototype is missing", function()
    local opts = Stubs.lookalike_opts()
    opts.cloud = nil
    local all = build_with(opts)
    assert.is_nil(all["smoke-with-trigger/ao-poison-cloud"])
    assert.truthy(all["fire/ao-acid-pool"])
    assert.truthy(all["fire/ao-acid-puddle"])
  end)

  it("skip the trail puddle when the vanilla puddle is missing", function()
    local opts = Stubs.lookalike_opts()
    opts.puddle = nil
    local all = build_with(opts)
    assert.is_nil(all["fire/ao-acid-puddle"])
    assert.truthy(all["fire/ao-acid-pool"])
  end)

  it("drop the cloud's created_effect when an entity it names was removed", function()
    local opts = Stubs.lookalike_opts()
    opts.entity_exists = function(name)
      return name ~= "poison-cloud-visual-dummy"
    end
    local c = build_with(opts)["smoke-with-trigger/ao-poison-cloud"]
    assert.is_nil(c.created_effect)
    assert.are.equal("cloud.png", c.animation.filename)
  end)

  it("keep only the smoke and sound effects of the cloud's created_effect", function()
    local opts = Stubs.lookalike_opts()
    local effects = opts.cloud.created_effect[1].action_delivery.target_effects
    effects[#effects + 1] = { type = "play-sound", sound = { filename = "puff.ogg" } }
    effects[#effects + 1] = { type = "damage", damage = { amount = 5, type = "poison" } }
    effects[#effects + 1] = { type = "create-entity", entity_name = "gone" }
    opts.cloud.created_effect[2] = {
      type = "direct",
      action_delivery = { type = "projectile", projectile = "gone" },
    }
    opts.entity_exists = function(name)
      return name ~= "gone"
    end
    local c = build_with(opts)["smoke-with-trigger/ao-poison-cloud"]
    assert.are.same({
      {
        type = "cluster",
        action_delivery = {
          {
            type = "instant",
            target_effects = {
              { type = "create-smoke", entity_name = "poison-cloud-visual-dummy" },
              { type = "play-sound", sound = { filename = "puff.ogg" } },
            },
          },
        },
      },
    }, c.created_effect)
  end)

  it("keep a created_effect written as single tables", function()
    local opts = Stubs.lookalike_opts()
    local smoke = { type = "create-smoke", entity_name = "poison-cloud-visual-dummy" }
    opts.cloud.created_effect = {
      type = "direct",
      action_delivery = { type = "instant", source_effects = smoke },
    }
    local c = build_with(opts)["smoke-with-trigger/ao-poison-cloud"]
    assert.are.same({
      { type = "direct", action_delivery = { { type = "instant", source_effects = { smoke } } } },
    }, c.created_effect)
  end)

  it("drop a created_effect with nothing left to show", function()
    local opts = Stubs.lookalike_opts()
    opts.cloud.created_effect[1].action_delivery.target_effects =
      { { type = "damage", damage = { amount = 5, type = "poison" } } }
    local c = build_with(opts)["smoke-with-trigger/ao-poison-cloud"]
    assert.is_nil(c.created_effect)
  end)

  it("skip the pool and the trail puddle when their damage type was removed", function()
    local opts = Stubs.lookalike_opts()
    opts.damage_exists = function(name)
      return name ~= "acid"
    end
    local all = build_with(opts)
    assert.is_nil(all["fire/ao-acid-pool"])
    assert.is_nil(all["fire/ao-acid-puddle"])
    assert.truthy(all["smoke-with-trigger/ao-poison-cloud"])
  end)

  it("skip the pool when the vanilla pool has no damage per tick", function()
    local opts = Stubs.lookalike_opts()
    opts.pool.damage_per_tick = nil
    assert.is_nil(build_with(opts)["fire/ao-acid-pool"])
  end)

  it("come in name order", function()
    local names = {}
    for _, p in ipairs(Ordnance.lookalikes(Stubs.lookalike_opts())) do
      names[#names + 1] = p.name
    end
    assert.are.same(
      { "ao-acid-pool", "ao-acid-puddle", "ao-poison-cloud", "ao-poison-puff" },
      names
    )
  end)
end)
