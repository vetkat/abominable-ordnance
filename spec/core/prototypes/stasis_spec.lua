local Lifecycle = require("core.prototypes.lifecycle")
local Ordnance = require("core.prototypes.ordnance")
local Stasis = require("core.prototypes.stasis")
local Stubs = require("spec.support.stubs")

local function sources()
  local list = Lifecycle.prototypes(Stubs.lifecycle_opts(false))
  for _, p in ipairs((Ordnance.prototypes(Stubs.ordnance_opts()))) do
    list[#list + 1] = p
  end
  return list
end

local function build()
  local src = sources()
  return Stubs.by_name(Stasis.prototypes(src)), Stubs.by_name(src)
end

local PACK_FLAGS = {
  "allow_quality",
  "allow_productivity",
  "allow_decomposition",
  "allow_as_intermediate",
  "auto_recycle",
}

describe("the stasis ward", function()
  it("lists the 10 version 1 lifecycle items", function()
    local names = Stasis.lifecycle_names()
    assert.are.equal(10, #names)
    assert.are.equal("ao-biter-egg", names[1])
    assert.are.equal("ao-biter-larva", names[2])
  end)

  it("gives every lifecycle item one warded item, one pack and one unpack", function()
    local all = build()
    for _, name in ipairs(Stasis.lifecycle_names()) do
      assert.truthy(all["item/" .. Stasis.warded_name(name)], name)
      assert.truthy(all["recipe/" .. Stasis.pack_recipe(name)], name)
      assert.truthy(all["recipe/" .. Stasis.unpack_recipe(name)], name)
    end
    assert.are.equal("ao-warded-biter-egg", Stasis.warded_name("ao-biter-egg"))
    assert.are.equal("ao-ward-biter-egg", Stasis.pack_recipe("ao-biter-egg"))
    assert.are.equal("ao-unward-biter-egg", Stasis.unpack_recipe("ao-biter-egg"))
  end)

  it("wards nothing outside the list", function()
    local all = build()
    local warded = 0
    for key in pairs(all) do
      if key:find("^item/ao%-warded%-") then
        warded = warded + 1
      end
    end
    assert.are.equal(10, warded)
  end)

  it("slows the spoil timer 20 times and keeps the item's spoil effect", function()
    local all, src = build()
    for _, name in ipairs(Stasis.lifecycle_names()) do
      local source = src["item/" .. name] or src["ammo/" .. name]
      local warded = all["item/" .. Stasis.warded_name(name)]
      assert.are.equal(source.spoil_ticks * 20, warded.spoil_ticks, name)
      assert.are.same(source.spoil_to_trigger_result, warded.spoil_to_trigger_result)
      assert.are_not.equal(source.spoil_to_trigger_result, warded.spoil_to_trigger_result)
      assert.are.equal(source.stack_size, warded.stack_size)
      assert.is_false(warded.auto_recycle)
      assert.are.equal(Stasis.SUBGROUP, warded.subgroup)
    end
  end)

  it("makes a warded rocket a plain item with no ammo type", function()
    local all = build()
    local warded = all["item/ao-warded-biter-larva-explosive"]
    assert.are.equal("item", warded.type)
    assert.is_nil(warded.ammo_type)
    assert.is_nil(warded.ammo_category)
  end)

  it("packs one item and one ward into one warded item", function()
    local r = build()["recipe/ao-ward-spitter-larva"]
    assert.are.same({
      { type = "item", name = "ao-spitter-larva", amount = 1 },
      { type = "item", name = "ao-stasis-ward", amount = 1 },
    }, r.ingredients)
    assert.are.same({ { type = "item", name = "ao-warded-spitter-larva", amount = 1 } }, r.results)
    assert.are.equal(1, r.energy_required)
  end)

  it("unpacks to the item as main product and the ward", function()
    local r = build()["recipe/ao-unward-biter-larva-acid"]
    assert.are.same(
      { { type = "item", name = "ao-warded-biter-larva-acid", amount = 1 } },
      r.ingredients
    )
    assert.are.same({
      { type = "item", name = "ao-biter-larva-acid", amount = 1 },
      { type = "item", name = "ao-stasis-ward", amount = 1 },
    }, r.results)
    assert.are.equal("ao-biter-larva-acid", r.main_product)
    assert.truthy(r.icons)
  end)

  it("locks quality, productivity, loops and recycling on pack and unpack", function()
    local all = build()
    for _, name in ipairs(Stasis.lifecycle_names()) do
      for _, recipe in ipairs({ Stasis.pack_recipe(name), Stasis.unpack_recipe(name) }) do
        local r = all["recipe/" .. recipe]
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
    end
  end)

  it("makes a recyclable ward from plastic, steel and a circuit", function()
    local all = build()
    local item = all["item/ao-stasis-ward"]
    assert.are.equal(50, item.stack_size)
    assert.is_nil(item.spoil_ticks)
    local r = all["recipe/ao-stasis-ward"]
    assert.are.same({
      { type = "item", name = "plastic-bar", amount = 2 },
      { type = "item", name = "steel-plate", amount = 1 },
      { type = "item", name = "electronic-circuit", amount = 1 },
    }, r.ingredients)
    assert.are.equal(2, r.energy_required)
    assert.is_nil(r.auto_recycle)
  end)

  it("puts the subgroup in the intermediate products group", function()
    local g = build()["item-subgroup/ao-stasis"]
    assert.are.equal("intermediate-products", g.group)
  end)

  it("unlocks the ward and every pack and unpack after Ordnance loading", function()
    local tech = build()["technology/ao-stasis-ward"]
    assert.are.same({ "ao-ordnance-loading" }, tech.prerequisites)
    assert.are.equal(150, tech.unit.count)
    assert.are.equal(30, tech.unit.time)
    assert.are.equal(21, #tech.effects)
    assert.are.same({ type = "unlock-recipe", recipe = "ao-stasis-ward" }, tech.effects[1])
  end)

  it("skips a lifecycle item that is missing from the sources", function()
    local src = {}
    for _, p in ipairs(sources()) do
      if p.name ~= "ao-spitter-egg" then
        src[#src + 1] = p
      end
    end
    local all = Stubs.by_name(Stasis.prototypes(src))
    assert.is_nil(all["item/ao-warded-spitter-egg"])
    assert.is_nil(all["recipe/ao-ward-spitter-egg"])
    assert.are.equal(19, #all["technology/ao-stasis-ward"].effects)
  end)
end)
