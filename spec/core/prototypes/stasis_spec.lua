local Balance = require("core.balance")
local Common = require("core.prototypes.common")
local Lifecycle = require("core.prototypes.lifecycle")
local Ordnance = require("core.prototypes.ordnance")
local Names = require("core.names")
local Stasis = require("core.prototypes.stasis")
local Stubs = require("spec.support.stubs")

local LIFT = 1000000

local function raw_sources()
  local list = Lifecycle.prototypes(Stubs.lifecycle_opts(false))
  Common.append(list, (Ordnance.prototypes(Stubs.ordnance_opts())))
  return list
end

local function sources()
  return Stasis.weighted(raw_sources(), LIFT)
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
    assert.are.equal(Names.WARDED .. "biter-egg", Stasis.warded_name("ao-biter-egg"))
    assert.are.equal(Names.PACK .. "biter-egg", Stasis.pack_recipe("ao-biter-egg"))
    assert.are.equal(Names.UNPACK .. "biter-egg", Stasis.unpack_recipe("ao-biter-egg"))
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

  it("slows the spoil timer and keeps the item's spoil effect", function()
    local all, src = build()
    for _, name in ipairs(Stasis.lifecycle_names()) do
      local source = src["item/" .. name] or src["ammo/" .. name]
      local warded = all["item/" .. Stasis.warded_name(name)]
      assert.are.equal(source.spoil_ticks * Balance.stasis.factor, warded.spoil_ticks, name)
      assert.are.same(source.spoil_to_trigger_result, warded.spoil_to_trigger_result)
      assert.are_not.equal(source.spoil_to_trigger_result, warded.spoil_to_trigger_result)
      assert.are.equal(source.stack_size, warded.stack_size)
      assert.is_false(warded.auto_recycle)
      assert.are.equal(Stasis.SUBGROUP, warded.subgroup)
    end
  end)

  it("gives every lifecycle item a default weight of the lift weight over its stack", function()
    local _, src = build()
    for _, name in ipairs(Stasis.lifecycle_names()) do
      local source = src["item/" .. name] or src["ammo/" .. name]
      assert.are.equal(LIFT / source.stack_size, source.weight, name)
    end
  end)

  it("keeps a weight that a prototype sets and leaves other prototypes alone", function()
    local raw = raw_sources()
    local egg, recipes
    for _, p in ipairs(raw) do
      if p.name == "ao-biter-egg" then
        egg = p
        p.weight = 777
      end
    end
    local out = Stasis.weighted(raw, LIFT)
    local by_name = Stubs.by_name(out)
    assert.are.equal(777, by_name["item/ao-biter-egg"].weight)
    for _, p in ipairs(out) do
      if p.type == "recipe" then
        recipes = true
        assert.is_nil(p.weight)
      end
    end
    assert.is_true(recipes)
    assert.are.equal(#raw, #out)
    assert.is_not_nil(egg)
  end)

  it("does not change the list that it weighs", function()
    local raw = raw_sources()
    Stasis.weighted(raw, LIFT)
    assert.is_nil(Stubs.by_name(raw)["item/ao-biter-egg"].weight)
  end)

  it("gives every warded item the weight of its source item", function()
    local all, src = build()
    for _, name in ipairs(Stasis.lifecycle_names()) do
      local source = src["item/" .. name] or src["ammo/" .. name]
      assert.are.equal(source.weight, all["item/" .. Stasis.warded_name(name)].weight, name)
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
      { type = "item", name = Names.WARD, amount = 1 },
    }, r.ingredients)
    assert.are.same({ { type = "item", name = "ao-warded-spitter-larva", amount = 1 } }, r.results)
    assert.are.equal(Balance.stasis.pack_time, r.energy_required)
  end)

  it("unpacks to the item as main product and the ward", function()
    local r = build()["recipe/ao-unward-biter-larva-acid"]
    assert.are.same(
      { { type = "item", name = "ao-warded-biter-larva-acid", amount = 1 } },
      r.ingredients
    )
    assert.are.same({
      { type = "item", name = "ao-biter-larva-acid", amount = 1 },
      { type = "item", name = Names.WARD, amount = 1 },
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
    local item = all["item/" .. Names.WARD]
    assert.are.equal(Balance.stasis.ward.stack, item.stack_size)
    assert.is_nil(item.spoil_ticks)
    local r = all["recipe/" .. Names.WARD]
    assert.are.same({
      { type = "item", name = "plastic-bar", amount = Balance.stasis.ward.plastic },
      { type = "item", name = "steel-plate", amount = Balance.stasis.ward.steel },
      { type = "item", name = "electronic-circuit", amount = Balance.stasis.ward.circuit },
    }, r.ingredients)
    assert.are.equal(Balance.stasis.ward.time, r.energy_required)
    assert.is_nil(r.auto_recycle)
  end)

  it("puts the subgroup in the intermediate products group", function()
    local g = build()["item-subgroup/ao-stasis"]
    assert.are.equal("intermediate-products", g.group)
  end)

  it("unlocks the ward and every pack and unpack after Ordnance loading", function()
    local tech = build()["technology/" .. Names.STASIS_TECH]
    assert.are.same({ "ao-ordnance-loading" }, tech.prerequisites)
    assert.are.equal(Balance.stasis.research.count, tech.unit.count)
    assert.are.equal(Balance.stasis.research.time, tech.unit.time)
    assert.are.equal(21, #tech.effects)
    assert.are.same({ type = "unlock-recipe", recipe = Names.WARD }, tech.effects[1])
  end)

  it("raises a clear error for a lifecycle item that is missing from the sources", function()
    local src = {}
    for _, p in ipairs(sources()) do
      if p.name ~= "ao-spitter-egg" then
        src[#src + 1] = p
      end
    end
    local ok, err = pcall(Stasis.prototypes, src)
    assert.is_false(ok)
    assert.truthy(tostring(err):find("ao-spitter-egg", 1, true))
    assert.truthy(tostring(err):find("lifecycle", 1, true))
  end)

  it("orders the recipes like the items", function()
    local out = build()
    assert.are.equal(out["item/" .. Names.WARD].order, out["recipe/" .. Names.WARD].order)
    for _, name in ipairs(Stasis.lifecycle_names()) do
      local w = out["item/" .. Stasis.warded_name(name)]
      local pack = out["recipe/" .. Stasis.pack_recipe(name)].order
      local unpack = out["recipe/" .. Stasis.unpack_recipe(name)].order
      assert.are.equal(w.order .. "-a", pack)
      assert.are.equal(w.order .. "-b", unpack)
    end
  end)
end)
