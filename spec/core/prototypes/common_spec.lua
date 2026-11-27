local Common = require("core.prototypes.common")

local function numbers()
  return {
    crafting_speed = 1,
    energy_usage = "1kW",
    pollution = 1,
    max_health = 10,
    mining_time = 0.5,
  }
end

describe("the shared prototype helpers", function()
  it("tint a copy of the graphics, but not shadows", function()
    local g = {
      layers = {
        { filename = "a.png" },
        { filename = "s.png", draw_as_shadow = true },
      },
    }
    local t = Common.tinted(g, { r = 1 })
    assert.are.same({ r = 1 }, t.layers[1].tint)
    assert.is_nil(t.layers[2].tint)
    assert.is_nil(g.layers[1].tint)
  end)

  it("copy a table all the way down", function()
    local t = { a = { b = { 1, 2 } }, c = "x" }
    local c = Common.copy(t)
    assert.are.same(t, c)
    assert.are_not.equal(t.a, c.a)
    assert.are_not.equal(t.a.b, c.a.b)
    assert.are.equal(3, Common.copy(3))
  end)

  it("make an item from an icons list", function()
    local icons = Common.icon("x.png", { r = 1 })
    local i = Common.item("ao-x", icons, "intermediate-product", 20)
    assert.are.equal("item", i.type)
    assert.are.equal(20, i.stack_size)
    assert.are.same(icons, i.icons)
  end)

  it("make a disabled recipe", function()
    local r = Common.recipe("x", { "crafting" }, 2, {}, {})
    assert.is_false(r.enabled)
    assert.are.equal(2, r.energy_required)
  end)

  it("turn off recycling", function()
    assert.is_false(Common.no_recycling(Common.recipe("x", {}, 1, {}, {})).auto_recycle)
  end)

  it("make a spoil trigger with a script effect", function()
    local t = Common.spoil_trigger("ao-x", 1)
    assert.are.equal(1, t.items_per_trigger)
    assert.are.same(
      { type = "script", effect_id = "ao-x" },
      t.trigger.action_delivery.source_effects[1]
    )
  end)

  it("sizes the boxes from the footprint", function()
    local want = {
      [3] = { 1.2, 1.5 },
      [4] = { 1.7, 2.0 },
      [5] = { 2.2, 2.5 },
    }
    for size, boxes in pairs(want) do
      local m = Common.machine({
        name = "ao-m",
        icons = {},
        categories = { "c" },
        graphics = { graphics_set = {} },
        size = size,
        numbers = numbers(),
      })
      assert.are.near(boxes[1], m.collision_box[2][1], 1e-9)
      assert.are.near(-boxes[1], m.collision_box[1][2], 1e-9)
      assert.are.near(boxes[2], m.selection_box[2][2], 1e-9)
      assert.are.near(-boxes[2], m.selection_box[1][1], 1e-9)
      assert.are.equal(size, m.tile_width)
      assert.are.equal(size, m.tile_height)
    end
  end)

  it("uses the graphics as given without a tint", function()
    local m = Common.machine({
      name = "ao-m",
      icons = {},
      categories = { "c" },
      graphics = { graphics_set = { animation = { layers = { { filename = "a.png" } } } } },
      numbers = numbers(),
    })
    assert.is_nil(m.graphics_set.animation.layers[1].tint)
    assert.are.equal(3, m.tile_width)
    assert.is_nil(m.corpse)
  end)

  it("takes the corpse from the spec", function()
    local m = Common.machine({
      name = "ao-m",
      icons = {},
      categories = { "c" },
      graphics = { graphics_set = {} },
      corpse = "big-remnants",
      numbers = numbers(),
    })
    assert.are.equal("big-remnants", m.corpse)
  end)

  it("makes an icon without tint and at 256 px", function()
    local icons = Common.icon("t.png", nil, 256)
    assert.are.same({ { icon = "t.png", icon_size = 256 } }, icons)
    assert.is_nil(icons[1].tint)
  end)

  it("make an electric machine with no modules", function()
    local m = Common.machine({
      name = "ao-m",
      icons = {},
      categories = { "c" },
      graphics = { graphics_set = { filename = "m.png" }, working_sound = { s = 1 } },
      tint = { r = 1 },
      numbers = numbers(),
    })
    assert.are.equal("assembling-machine", m.type)
    assert.are.equal(0, m.module_slots)
    assert.are.same({}, m.allowed_effects)
    assert.are.same({ "c" }, m.crafting_categories)
    assert.are.same({ r = 1 }, m.graphics_set.tint)
    assert.are.same({ mining_time = 0.5, result = "ao-m" }, m.minable)
    assert.are.same({ s = 1 }, m.working_sound)
  end)

  it("copy a machine's looks", function()
    local machines = { a = { graphics_set = { g = 1 }, working_sound = { s = 1 }, x = 1 } }
    assert.are.same(
      { graphics_set = { g = 1 }, working_sound = { s = 1 } },
      Common.looks(machines, "a", "b")
    )
  end)

  it("fall back when another mod removed the machine", function()
    local machines = { b = { graphics_set = { g = 2 } } }
    assert.are.same({ graphics_set = { g = 2 } }, Common.looks(machines, "a", "b"))
  end)

  it("give nil when both machines are gone", function()
    assert.is_nil(Common.looks({}, "a", "b"))
  end)

  it("pick copies only the named fields, and leaves out missing ones", function()
    local source = { a = 1, b = { 2 }, c = 3 }
    local copy = Common.pick(source, { "a", "b", "d" })
    assert.are.same({ a = 1, b = { 2 } }, copy)
    copy.a = 9
    assert.are.equal(1, source.a)
  end)

  it("pick shares no nested table with the source", function()
    local source = { b = { c = { 1 } } }
    local copy = Common.pick(source, { "b" })
    assert.are_not.equal(source.b, copy.b)
    assert.are_not.equal(source.b.c, copy.b.c)
  end)

  it("append adds every item of a list to the end of another", function()
    local out = { 1 }
    Common.append(out, { 2, 3 })
    assert.are.same({ 1, 2, 3 }, out)
  end)
end)
