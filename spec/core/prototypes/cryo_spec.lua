local Balance = require("core.balance")
local Common = require("core.prototypes.common")
local Graphics = require("core.prototypes.graphics")
local Lifecycle = require("core.prototypes.lifecycle")
local Names = require("core.names")
local Ordnance = require("core.prototypes.ordnance")
local Stasis = require("core.prototypes.stasis")
local Stubs = require("spec.support.stubs")

describe("the cryo names and numbers", function()
  it("name the cryo ward, its research and the recipe prefixes", function()
    assert.are.equal("ao-cryo-ward", Names.CRYO_WARD)
    assert.are.equal("ao-cryo-ward", Names.CRYO_TECH)
    assert.are.equal("ao-cryo-warded-", Names.CRYO_WARDED)
    assert.are.equal("ao-cryo-ward-", Names.CRYO_PACK)
    assert.are.equal("ao-cryo-unward-", Names.CRYO_UNPACK)
  end)

  it("slow the spoil timer 100 times and price the ward", function()
    local c = Balance.cryo
    assert.are.equal(100, c.factor)
    assert.are.equal(1, c.pack_time)
    assert.are.same({ stack = 50, time = 4, lithium = 2, cold = 10, hot = 5 }, c.ward)
    assert.are.equal(300, c.pressure)
    assert.are.same({ count = 500, time = 60 }, c.research)
  end)
end)

local LIFT = 1000000

local function sources()
  local list = Lifecycle.prototypes(Stubs.lifecycle_opts(true))
  Common.append(list, (Ordnance.prototypes(Stubs.ordnance_opts())))
  return Stasis.weighted(list, LIFT)
end

local function build(kinds)
  local src = sources()
  return Stubs.by_name(Stasis.prototypes(src, kinds or { Stasis.BASE, Stasis.CRYO })),
    Stubs.by_name(src)
end

local function has_all()
  local has = {}
  for _, need in ipairs(Stasis.CRYO.needs) do
    has[Stasis.key(need.type, need.name)] = true
  end
  return has
end

local PACK_FLAGS = {
  "allow_quality",
  "allow_productivity",
  "allow_decomposition",
  "allow_as_intermediate",
  "auto_recycle",
}

describe("the ward kinds", function()
  it("give only the base kind without Space Age", function()
    local kinds, missing = Stasis.kinds({ space_age = false, has = has_all() })
    assert.are.same({ Stasis.BASE }, kinds)
    assert.are.same({}, missing)
  end)

  it("add the cryo kind with Space Age when every Aquilo prototype exists", function()
    local kinds, missing = Stasis.kinds({ space_age = true, has = has_all() })
    assert.are.same({ Stasis.BASE, Stasis.CRYO }, kinds)
    assert.are.same({}, missing)
  end)

  it("leave the cryo kind out and name the missing prototype", function()
    local has = has_all()
    has["fluid/fluoroketone-cold"] = nil
    local kinds, missing = Stasis.kinds({ space_age = true, has = has })
    assert.are.same({ Stasis.BASE }, kinds)
    assert.are.same({ "fluid/fluoroketone-cold" }, missing)
  end)

  it("treat missing facts as nothing present", function()
    local kinds, missing = Stasis.kinds({ space_age = true })
    assert.are.same({ Stasis.BASE }, kinds)
    assert.are.equal(#Stasis.CRYO.needs, #missing)
  end)

  it("list what the cryo ward needs from Space Age", function()
    local keys = {}
    for _, need in ipairs(Stasis.CRYO.needs) do
      keys[#keys + 1] = Stasis.key(need.type, need.name)
    end
    assert.are.same({
      "item/lithium-plate",
      "fluid/fluoroketone-cold",
      "fluid/fluoroketone-hot",
      "recipe-category/cryogenics",
      "technology/cryogenic-science-pack",
      "item/space-science-pack",
      "item/cryogenic-science-pack",
      "assembling-machine/cryogenic-plant",
      "planet/aquilo",
    }, keys)
  end)

  it("drop the cryo kind when any one need is missing, and keep the base kind", function()
    for _, need in ipairs(Stasis.CRYO.needs) do
      local key = Stasis.key(need.type, need.name)
      local has = has_all()
      has[key] = nil
      local kinds, missing = Stasis.kinds({ space_age = true, has = has })
      assert.are.same({ Stasis.BASE }, kinds, key)
      assert.are.same({ key }, missing, key)
    end
  end)

  it("read the pressure of the ward recipe from the facts", function()
    local kinds = Stasis.kinds({ space_age = true, has = has_all(), pressure = 123 })
    assert.are.same(
      { { property = "pressure", min = 123, max = 123 } },
      kinds[2].recipe.surface_conditions
    )
  end)

  it("fall back to the balance pressure when the facts give none", function()
    local kinds = Stasis.kinds({ space_age = true, has = has_all() })
    assert.are.same(
      { { property = "pressure", min = 300, max = 300 } },
      kinds[2].recipe.surface_conditions
    )
  end)

  it("build the cryo kind without sharing a table between two kinds", function()
    local a, b = Stasis.cryo_kind(10), Stasis.cryo_kind(20)
    assert.are.equal(10, a.recipe.surface_conditions[1].min)
    assert.are.equal(20, b.recipe.surface_conditions[1].min)
  end)
end)

describe("the cryo ward", function()
  it("names its prototypes once across both kinds", function()
    local seen = {}
    for _, p in ipairs(Stasis.prototypes(sources(), { Stasis.BASE, Stasis.CRYO })) do
      local key = p.type .. "/" .. p.name
      assert.is_nil(seen[key], key .. " twice")
      seen[key] = true
    end
    local base = #Stasis.prototypes(sources(), { Stasis.BASE })
    local cryo_only = #Stasis.prototypes(sources(), { Stasis.CRYO }) - 1
    local total = 0
    for _ in pairs(seen) do
      total = total + 1
    end
    assert.are.equal(base + cryo_only, total)
    assert.are.equal(67, total)
  end)

  it("makes no cryo prototype from the base kind alone", function()
    for key in pairs(build({ Stasis.BASE })) do
      assert.is_nil(key:find("cryo", 1, true), key)
    end
  end)

  it("gives every lifecycle item a cryo-warded item, 100 times slower", function()
    local all, src = build()
    for _, name in ipairs(Stasis.lifecycle_names()) do
      local source = src["item/" .. name] or src["ammo/" .. name]
      local warded = all["item/" .. Stasis.warded_name(Stasis.CRYO, name)]
      assert.truthy(warded, name)
      assert.are.equal("item", warded.type)
      assert.is_nil(warded.ammo_type)
      assert.is_nil(warded.ammo_category)
      assert.are.equal(source.spoil_ticks * 100, warded.spoil_ticks, name)
      assert.is_true(warded.spoil_ticks < 2 ^ 32, name)
      assert.are.same(source.spoil_to_trigger_result, warded.spoil_to_trigger_result)
      assert.are_not.equal(source.spoil_to_trigger_result, warded.spoil_to_trigger_result)
      assert.are.equal(source.stack_size, warded.stack_size)
      assert.are.equal(source.weight, warded.weight, name)
      assert.is_false(warded.auto_recycle)
      assert.are.equal(Stasis.SUBGROUP, warded.subgroup)
    end
    assert.are.equal("ao-cryo-warded-biter-egg", Stasis.warded_name(Stasis.CRYO, "ao-biter-egg"))
  end)

  it("makes the cryo ward in a cryogenic plant on Aquilo only", function()
    local all = build()
    local item = all["item/ao-cryo-ward"]
    assert.are.equal(50, item.stack_size)
    assert.is_nil(item.spoil_ticks)
    assert.is_nil(item.weight)
    local r = all["recipe/ao-cryo-ward"]
    assert.are.same({ "cryogenics" }, r.categories)
    assert.are.equal(4, r.energy_required)
    assert.are.same({
      { type = "item", name = "lithium-plate", amount = 2 },
      { type = "fluid", name = "fluoroketone-cold", amount = 10 },
    }, r.ingredients)
    assert.are.same({
      { type = "item", name = "ao-cryo-ward", amount = 1 },
      { type = "fluid", name = "fluoroketone-hot", amount = 5 },
    }, r.results)
    assert.are.equal("ao-cryo-ward", r.main_product)
    assert.are.same({ { property = "pressure", min = 300, max = 300 } }, r.surface_conditions)
    assert.are_not.equal(Balance.cryo.surface_conditions, r.surface_conditions)
    assert.is_false(r.auto_recycle)
    assert.is_false(r.allow_productivity)
    assert.is_false(r.allow_quality)
    assert.is_false(r.enabled)
    assert.are.equal(Stasis.SUBGROUP, r.subgroup)
  end)

  it("keeps the base ward recipe free of the cryo locks", function()
    local r = build()["recipe/ao-stasis-ward"]
    assert.is_nil(r.surface_conditions)
    assert.is_nil(r.auto_recycle)
    assert.is_nil(r.allow_quality)
    assert.is_nil(r.allow_productivity)
  end)

  it("packs and unpacks with the cryo ward anywhere, with the slice 5 locks", function()
    local all = build()
    for _, name in ipairs(Stasis.lifecycle_names()) do
      local pack_name = Stasis.pack_recipe(Stasis.CRYO, name)
      local unpack_name = Stasis.unpack_recipe(Stasis.CRYO, name)
      for _, recipe in ipairs({ pack_name, unpack_name }) do
        local r = all["recipe/" .. recipe]
        assert.truthy(r, recipe)
        assert.are.same({ "crafting" }, r.categories)
        assert.is_nil(r.surface_conditions)
        assert.is_nil(r.can_set_quality)
        assert.are.equal(1, r.energy_required)
        for _, flag in ipairs(PACK_FLAGS) do
          assert.is_false(r[flag], recipe .. " " .. flag)
        end
        assert.are.equal(0, r.maximum_productivity)
        assert.are.equal(Stasis.SUBGROUP, r.subgroup)
        assert.is_false(r.enabled)
        for _, result in ipairs(r.results) do
          assert.is_nil(result.always_fresh)
          assert.is_nil(result.reset_freshness_on_craft)
        end
      end
      local pack = all["recipe/" .. pack_name]
      assert.are.same({
        { type = "item", name = name, amount = 1 },
        { type = "item", name = "ao-cryo-ward", amount = 1 },
      }, pack.ingredients)
      local unpack = all["recipe/" .. unpack_name]
      assert.are.equal(name, unpack.main_product)
      assert.are.same({
        { type = "item", name = name, amount = 1 },
        { type = "item", name = "ao-cryo-ward", amount = 1 },
      }, unpack.results)
    end
    assert.are.equal("ao-cryo-ward-biter-egg", Stasis.pack_recipe(Stasis.CRYO, "ao-biter-egg"))
    assert.are.equal("ao-cryo-unward-biter-egg", Stasis.unpack_recipe(Stasis.CRYO, "ao-biter-egg"))
  end)

  it("gives each ward its own icon with no tint", function()
    local all = build()
    local stasis, cryo = Graphics.icon_path("stasis-ward.png"), Graphics.icon_path("cryo-ward.png")
    assert.are.same({ { icon = stasis, icon_size = 64 } }, all["item/ao-stasis-ward"].icons)
    assert.are.same({ { icon = cryo, icon_size = 64 } }, all["item/ao-cryo-ward"].icons)
    local warded = all["item/ao-cryo-warded-biter-egg"].icons
    assert.are.equal(cryo, warded[#warded].icon)
    assert.is_nil(warded[#warded].tint)
    assert.are.same(
      { { icon = Graphics.tech_path("stasis-ward.png"), icon_size = 256 } },
      all["technology/" .. Names.STASIS_TECH].icons
    )
    assert.are.same({ { icon = cryo, icon_size = 64 } }, all["technology/ao-cryo-ward"].icons)
  end)

  it("unlocks the cryo ward and its 20 recipes after Stasis ward and Aquilo science", function()
    local tech = build()["technology/ao-cryo-ward"]
    assert.are.same({ "ao-stasis-ward", "cryogenic-science-pack" }, tech.prerequisites)
    assert.are.equal(500, tech.unit.count)
    assert.are.equal(60, tech.unit.time)
    assert.are.same({
      { "automation-science-pack", 1 },
      { "logistic-science-pack", 1 },
      { "military-science-pack", 1 },
      { "chemical-science-pack", 1 },
      { "space-science-pack", 1 },
      { "cryogenic-science-pack", 1 },
    }, tech.unit.ingredients)
    assert.are.equal(21, #tech.effects)
    assert.are.same({ type = "unlock-recipe", recipe = "ao-cryo-ward" }, tech.effects[1])
    for _, effect in ipairs(tech.effects) do
      assert.truthy(effect.recipe:find("^ao%-cryo%-"), effect.recipe)
    end
  end)

  it("leaves the base research as it was", function()
    local tech = build()["technology/ao-stasis-ward"]
    assert.are.same({ "ao-ordnance-loading" }, tech.prerequisites)
    assert.are.equal(21, #tech.effects)
  end)
end)
