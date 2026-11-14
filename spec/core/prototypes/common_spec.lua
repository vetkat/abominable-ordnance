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

  it("make a 3x3 electric machine with no modules", function()
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
end)
