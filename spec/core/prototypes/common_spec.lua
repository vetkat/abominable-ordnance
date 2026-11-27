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

  it("finds a vanilla machine's sound, or nil when a mod removed it", function()
    local hum = { sound = { filename = "hum.ogg" } }
    local raw = { ["assembling-machine"] = { centrifuge = { working_sound = hum } } }
    assert.are.equal(hum, Common.vanilla_sound(raw, "centrifuge"))
    assert.is_nil(Common.vanilla_sound(raw, "chemical-plant"))
    assert.is_nil(Common.vanilla_sound({}, "centrifuge"))
  end)

  it("names a vanilla corpse only when it exists", function()
    local raw = { corpse = { ["big-remnants"] = { type = "corpse" } } }
    assert.are.equal("big-remnants", Common.vanilla_corpse(raw, "big-remnants"))
    assert.is_nil(Common.vanilla_corpse(raw, "huge-remnants"))
    assert.is_nil(Common.vanilla_corpse({}, "big-remnants"))
  end)

  it("keeps its own copy of the sound", function()
    local sound = { sound = { filename = "hum.ogg", volume = 0.5 } }
    local m = Common.machine({
      name = "ao-m",
      icons = {},
      categories = { "c" },
      graphics = { graphics_set = {}, working_sound = sound },
      numbers = numbers(),
    })
    assert.are.same(sound, m.working_sound)
    assert.are_not.equal(sound, m.working_sound)
    assert.are_not.equal(sound.sound, m.working_sound.sound)
  end)

  it("keeps machines off Aquilo and space platforms, with space travel only", function()
    local function machine(space_travel)
      return Common.machine({
        name = "ao-m",
        icons = {},
        categories = { "c" },
        graphics = { graphics_set = {} },
        space_travel = space_travel,
        numbers = numbers(),
      })
    end
    local m = machine(true)
    assert.are.same({ { property = "pressure", min = 400 } }, m.surface_conditions)
    assert.are_not.equal(Common.SURFACE_CONDITIONS, m.surface_conditions)
    -- Without space travel the game refuses surface conditions.
    assert.is_nil(machine(false).surface_conditions)
    assert.is_nil(machine(nil).surface_conditions)
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

  it("makes an icon without tint", function()
    assert.are.same({ { icon = "t.png", icon_size = 64 } }, Common.icon("t.png"))
  end)

  it("make an electric machine with no modules", function()
    local m = Common.machine({
      name = "ao-m",
      icons = {},
      categories = { "c" },
      graphics = { graphics_set = { filename = "m.png" }, working_sound = { s = 1 } },
      numbers = numbers(),
    })
    assert.are.equal("assembling-machine", m.type)
    assert.are.equal(0, m.module_slots)
    assert.are.same({}, m.allowed_effects)
    assert.are.same({ "c" }, m.crafting_categories)
    assert.are.same({ filename = "m.png" }, m.graphics_set)
    assert.are.same({ mining_time = 0.5, result = "ao-m" }, m.minable)
    assert.are.same({ s = 1 }, m.working_sound)
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
