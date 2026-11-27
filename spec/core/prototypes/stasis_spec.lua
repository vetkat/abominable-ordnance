local Balance = require("core.balance")
local Common = require("core.prototypes.common")
local Graphics = require("core.prototypes.graphics")
local Lifecycle = require("core.prototypes.lifecycle")
local Ordnance = require("core.prototypes.ordnance")
local Payloads = require("core.payloads")
local Names = require("core.names")
local Stasis = require("core.prototypes.stasis")
local Species = require("core.species")
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
  return Stubs.by_name(Stasis.prototypes(src, { Stasis.BASE })), Stubs.by_name(src)
end

-- A kind that shares no value with the base kind, so a test can tell
-- which one the builder read.
local function other_kind()
  return {
    name = "zz-ward",
    factor = 7,
    pack_time = 3,
    warded = "zz-warded-",
    pack = "zz-pack-",
    unpack = "zz-unpack-",
    icon = "zz-ward.png",
    stack = 5,
    recipe = {
      categories = { "zz-category" },
      time = 9,
      ingredients = { { type = "item", name = "zz-in", amount = 2 } },
      results = { { type = "item", name = "zz-ward", amount = 1 } },
    },
    research = {
      name = "zz-research",
      icon = "zz-research.png",
      icon_size = 128,
      prerequisites = { "zz-prerequisite" },
      count = 11,
      time = 13,
      packs = { "automation-science-pack" },
    },
    needs = {},
  }
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
      assert.truthy(all["item/" .. Stasis.warded_name(Stasis.BASE, name)], name)
      assert.truthy(all["recipe/" .. Stasis.pack_recipe(Stasis.BASE, name)], name)
      assert.truthy(all["recipe/" .. Stasis.unpack_recipe(Stasis.BASE, name)], name)
    end
    assert.are.equal(Names.WARDED .. "biter-egg", Stasis.warded_name(Stasis.BASE, "ao-biter-egg"))
    assert.are.equal(Names.PACK .. "biter-egg", Stasis.pack_recipe(Stasis.BASE, "ao-biter-egg"))
    assert.are.equal(Names.UNPACK .. "biter-egg", Stasis.unpack_recipe(Stasis.BASE, "ao-biter-egg"))
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
      local warded = all["item/" .. Stasis.warded_name(Stasis.BASE, name)]
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
      assert.are.equal(
        source.weight,
        all["item/" .. Stasis.warded_name(Stasis.BASE, name)].weight,
        name
      )
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
      for _, recipe in ipairs({
        Stasis.pack_recipe(Stasis.BASE, name),
        Stasis.unpack_recipe(Stasis.BASE, name),
      }) do
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
    local ok, err = pcall(Stasis.prototypes, src, { Stasis.BASE })
    assert.is_false(ok)
    assert.truthy(tostring(err):find("ao-spitter-egg", 1, true))
    assert.truthy(tostring(err):find("lifecycle", 1, true))
  end)

  it("orders the recipes like the items", function()
    local out = build()
    assert.are.equal(out["item/" .. Names.WARD].order, out["recipe/" .. Names.WARD].order)
    for _, name in ipairs(Stasis.lifecycle_names()) do
      local w = out["item/" .. Stasis.warded_name(Stasis.BASE, name)]
      local pack = out["recipe/" .. Stasis.pack_recipe(Stasis.BASE, name)].order
      local unpack = out["recipe/" .. Stasis.unpack_recipe(Stasis.BASE, name)].order
      assert.are.equal(w.order .. "-a", pack)
      assert.are.equal(w.order .. "-b", unpack)
    end
  end)

  it("describes the base ward as a kind", function()
    local k = Stasis.BASE
    assert.are.equal(Names.WARD, k.name)
    assert.are.equal(Balance.stasis.factor, k.factor)
    assert.are.equal(Balance.stasis.pack_time, k.pack_time)
    assert.are.same({ Names.WARDED, Names.PACK, Names.UNPACK }, { k.warded, k.pack, k.unpack })
    assert.are.same({ "crafting" }, k.recipe.categories)
    assert.are.equal(Names.STASIS_TECH, k.research.name)
    assert.are.same({ "ao-ordnance-loading" }, k.research.prerequisites)
    assert.are.same({}, k.needs)
  end)

  it("builds 34 prototypes for the base kind alone, and no cryo prototype", function()
    local out = Stasis.prototypes(sources(), { Stasis.BASE })
    assert.are.equal(34, #out)
    for _, p in ipairs(out) do
      assert.is_nil(p.name:find("cryo", 1, true), p.name)
    end
  end)

  it("builds the subgroup once for two distinct kinds", function()
    local base = Stasis.prototypes(sources(), { Stasis.BASE })
    local out = Stasis.prototypes(sources(), { Stasis.BASE, other_kind() })
    local count = 0
    for _, p in ipairs(out) do
      if p.type == "item-subgroup" then
        count = count + 1
      end
    end
    assert.are.equal(1, count)
    assert.are.equal(1 + 2 * (#base - 1), #out)
  end)

  it("does not change the kinds it builds from", function()
    local kinds = { Stasis.BASE, other_kind() }
    local before = Common.copy(kinds)
    local out = Stasis.prototypes(sources(), kinds)
    assert.are.same(before, kinds)
    local owned = {}
    for _, kind in ipairs(kinds) do
      for _, t in ipairs({
        kind.recipe.ingredients,
        kind.recipe.results,
        kind.recipe.categories,
        kind.research.packs,
        kind.research.prerequisites,
      }) do
        owned[t] = true
      end
    end
    for _, p in ipairs(out) do
      for _, field in ipairs({ "ingredients", "results", "categories", "prerequisites" }) do
        assert.is_nil(owned[p[field] or false], p.name .. " " .. field)
      end
      if p.unit then
        assert.is_nil(owned[p.unit.ingredients], p.name)
      end
    end
  end)

  it("raises a clear error when no kinds are given", function()
    local ok, err = pcall(Stasis.prototypes, sources())
    assert.is_false(ok)
    assert.truthy(tostring(err):find("kinds", 1, true))
  end)

  describe("with a second kind", function()
    local kind, out, src

    before_each(function()
      kind = other_kind()
      local list = sources()
      src = Stubs.by_name(list)
      out = Stubs.by_name(Stasis.prototypes(list, { Stasis.BASE, kind }))
    end)

    local function assert_kind_badge(icons)
      local last = icons[#icons]
      assert.are.equal(kind.icon, last.icon)
      assert.are.equal(0.25, last.scale)
      assert.are.same({ -8, -8 }, last.shift)
      assert.is_nil(last.tint)
    end

    it("takes the ward item and recipe from the kind", function()
      local item = out["item/" .. kind.name]
      local recipe = out["recipe/" .. kind.name]
      assert.truthy(item)
      assert.truthy(recipe)
      assert.are.equal(kind.stack, item.stack_size)
      assert.are.same({ { icon = kind.icon, icon_size = 64 } }, item.icons)
      assert.are.same(kind.recipe.categories, recipe.categories)
      assert.are.equal(kind.recipe.time, recipe.energy_required)
      assert.are.same(kind.recipe.ingredients, recipe.ingredients)
      assert.are.same(kind.recipe.results, recipe.results)
    end)

    it("takes the names from the kind", function()
      for _, name in ipairs(Stasis.lifecycle_names()) do
        local suffix = (name:gsub("^ao%-", ""))
        assert.truthy(out["item/" .. kind.warded .. suffix], name)
        assert.truthy(out["recipe/" .. kind.pack .. suffix], name)
        assert.truthy(out["recipe/" .. kind.unpack .. suffix], name)
      end
      assert.are.equal("zz-warded-biter-egg", Stasis.warded_name(kind, "ao-biter-egg"))
      assert.are.equal("zz-pack-biter-egg", Stasis.pack_recipe(kind, "ao-biter-egg"))
      assert.are.equal("zz-unpack-biter-egg", Stasis.unpack_recipe(kind, "ao-biter-egg"))
    end)

    it("multiplies the spoil time by the kind's factor", function()
      for _, name in ipairs(Stasis.lifecycle_names()) do
        local source = src["item/" .. name] or src["ammo/" .. name]
        local w = out["item/" .. Stasis.warded_name(kind, name)]
        assert.are.equal(source.spoil_ticks * kind.factor, w.spoil_ticks, name)
        local b = out["item/" .. Stasis.warded_name(Stasis.BASE, name)]
        assert.are.equal(source.spoil_ticks * Stasis.BASE.factor, b.spoil_ticks, name)
      end
    end)

    it("packs and unpacks with the kind's ward and time", function()
      for _, name in ipairs(Stasis.lifecycle_names()) do
        local w = Stasis.warded_name(kind, name)
        local pack = out["recipe/" .. Stasis.pack_recipe(kind, name)]
        local unpack = out["recipe/" .. Stasis.unpack_recipe(kind, name)]
        assert.are.equal(kind.pack_time, pack.energy_required, name)
        assert.are.equal(kind.pack_time, unpack.energy_required, name)
        assert.are.same({
          { type = "item", name = name, amount = 1 },
          { type = "item", name = kind.name, amount = 1 },
        }, pack.ingredients)
        assert.are.same({ { type = "item", name = w, amount = 1 } }, pack.results)
        assert.are.same({ { type = "item", name = w, amount = 1 } }, unpack.ingredients)
        assert.are.same({
          { type = "item", name = name, amount = 1 },
          { type = "item", name = kind.name, amount = 1 },
        }, unpack.results)
      end
    end)

    it("uses the kind's icon everywhere", function()
      for _, name in ipairs(Stasis.lifecycle_names()) do
        assert_kind_badge(out["item/" .. Stasis.warded_name(kind, name)].icons)
        assert_kind_badge(out["recipe/" .. Stasis.unpack_recipe(kind, name)].icons)
      end
      assert.are.same(
        { { icon = "zz-research.png", icon_size = 128 } },
        out["technology/" .. kind.research.name].icons
      )
    end)

    it("shows the payload badge and the ward badge apart on a loaded larva", function()
      local loaded = Payloads.loaded_name(Species.ALL[1], Payloads.ALL[1])
      local icons = out["item/" .. Stasis.warded_name(Stasis.BASE, loaded)].icons
      local payload, ward = icons[#icons - 1], icons[#icons]
      assert.are.equal(Payloads.ALL[1].icon, payload.icon)
      assert.are.same({ 8, 8 }, payload.shift)
      assert.are.equal(Graphics.icon_path("stasis-ward.png"), ward.icon)
      assert.are.same({ -8, -8 }, ward.shift)
    end)

    it("takes the research from the kind", function()
      local tech = out["technology/" .. kind.research.name]
      assert.truthy(tech)
      assert.are.same(kind.research.prerequisites, tech.prerequisites)
      assert.are.equal(kind.research.count, tech.unit.count)
      assert.are.equal(kind.research.time, tech.unit.time)
      assert.are.same({ { "automation-science-pack", 1 } }, tech.unit.ingredients)
      assert.are.equal(1 + 2 * #Stasis.lifecycle_names(), #tech.effects)
      assert.are.equal(kind.name, tech.effects[1].recipe)
    end)

    it("keeps the names of the two kinds apart", function()
      local seen = {}
      for _, p in ipairs(Stasis.prototypes(sources(), { Stasis.BASE })) do
        seen[p.type .. "/" .. p.name] = true
      end
      for _, p in ipairs(Stasis.prototypes(sources(), { kind })) do
        if p.type ~= "item-subgroup" then
          assert.is_nil(seen[p.type .. "/" .. p.name], p.name)
        end
      end
    end)
  end)
end)
