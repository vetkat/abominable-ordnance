local Graphics = require("core.prototypes.graphics")
local Names = require("core.names")
local Payloads = require("core.payloads")
local Species = require("core.species")

local EPS = 1e-9

local function assert_vec(want, got)
  assert.are.near(want[1], got[1], EPS)
  assert.are.near(want[2], got[2], EPS)
end

-- Every table in value that names a file.
local function sprites(value, out)
  out = out or {}
  if type(value) == "table" then
    if value.filename then
      out[#out + 1] = value
    end
    for _, v in pairs(value) do
      sprites(v, out)
    end
  end
  return out
end

describe("the graphics module", function()
  it("fits the pod to 5×5", function()
    local g = Graphics.machine("breeding-pod", 5)
    local k = 5 / 7
    local sheet, shadow = g.animation.layers[1], g.animation.layers[2]
    local emission = g.working_visualisations[1]
    for _, layer in ipairs({ sheet, shadow, emission.animation }) do
      assert.are.near(0.5 * k, layer.scale, EPS)
      assert_vec({ 0, -0.5 * k }, layer.shift)
    end
    assert.are.equal(60, sheet.frame_count)
    assert.are.equal(8, sheet.line_length)
    assert.are.equal(0.15, sheet.animation_speed)
    assert.is_true(shadow.draw_as_shadow)
    assert.are.equal(60, shadow.repeat_count)
    assert.is_true(emission.fadeout)
    assert.is_true(emission.animation.draw_as_glow)
    assert.are.equal("additive", emission.animation.blend_mode)
  end)

  it("keeps the incubator at its drawn size", function()
    local g = Graphics.machine("incubator", 4)
    local sheet, shadow = g.animation.layers[1], g.animation.layers[2]
    local emission = g.working_visualisations[1].animation
    assert.are.near(0.5, sheet.scale, EPS)
    assert_vec({ 2.5 / 64, 2.5 / 64 }, sheet.shift)
    assert_vec({ 51 / 64, 31 / 64 }, shadow.shift)
    assert_vec({ 0, 0 }, emission.shift)
    assert.are.equal(9, emission.line_length)
  end)

  it("fits the chamber to 4×4", function()
    local g = Graphics.machine("loading-chamber", 4)
    local k = 4 / 6
    assert.are.near(0.5 * k, g.animation.layers[1].scale, EPS)
    assert.is_true(g.animation.layers[2].draw_as_shadow)
    local screen = g.working_visualisations[1].animation
    local creature = g.working_visualisations[2].animation
    local glow = g.working_visualisations[3].animation
    assert.are.equal(255, screen.frame_count)
    assert.are.equal(32, screen.line_length)
    assert.is_true(screen.draw_as_glow)
    assert_vec({ -2 * k, -1.75 * k }, screen.shift)
    assert.truthy(creature.filename:find("simulation%-chamber%-layer4%.png$"))
    assert.is_nil(creature.draw_as_glow)
    assert.is_true(glow.draw_as_glow)
    assert.are.equal("additive", glow.blend_mode)
    for _, v in ipairs(g.working_visualisations) do
      assert.is_nil(v.apply_recipe_tint)
    end
  end)

  it("reads each sheet from its own file", function()
    local function base(layer)
      return layer.filename:match("[^/]+$")
    end
    local want = {
      ["breeding-pod"] = {
        "pathogen-lab-animation.png",
        "pathogen-lab-shadow.png",
        "pathogen-lab-emission.png",
      },
      incubator = { "oxidizer-base.png", "oxidizer-shadow.png", "oxidizer-emission.png" },
      ["loading-chamber"] = {
        "simulation-chamber-base.png",
        "simulation-chamber-shadow.png",
        "simulation-chamber-screen-animation.png",
        "simulation-chamber-layer4.png",
        "simulation-chamber-glow.png",
      },
    }
    for name, files in pairs(want) do
      local g = Graphics.machine(name, Graphics.SIZE[name])
      local got = { base(g.animation.layers[1]), base(g.animation.layers[2]) }
      for _, v in ipairs(g.working_visualisations) do
        got[#got + 1] = base(v.animation)
      end
      assert.are.same(files, got, name)
    end
    local l = Graphics.launcher(3)
    assert.are.same(
      { "rocket-turret-attack.png", "rocket-turret-attack-shadow.png" },
      { base(l.layers[1]), base(l.layers[2]) }
    )
  end)

  it("has no tint on any building sheet", function()
    local looks = {
      Graphics.machine("breeding-pod", 5),
      Graphics.machine("incubator", 4),
      Graphics.machine("loading-chamber", 4),
      Graphics.remnants(4),
    }
    for _, look in ipairs(looks) do
      local found = sprites(look)
      assert.is_true(#found > 0)
      for _, s in ipairs(found) do
        assert.is_nil(s.tint, s.filename)
        assert.truthy(s.filename:find("^__abominable%-ordnance__/graphics/entity/"))
      end
    end
  end)

  it("fits the launcher to 3×3", function()
    local l = Graphics.launcher(3)
    for _, layer in ipairs(l.layers) do
      assert.are.equal(64, layer.direction_count)
      assert.are.equal(8, layer.line_length)
      assert.are.equal(512, layer.width)
      assert.are.equal(512, layer.height)
      assert.are.near(0.225, layer.scale, EPS)
      assert.is_nil(layer.tint)
    end
    assert.is_true(l.layers[2].draw_as_shadow)
    assert_vec({ 1.5, 0 }, l.layers[2].shift)
  end)

  it("builds the chamber remnants", function()
    local r = Graphics.remnants(4)
    assert.are.equal("corpse", r.type)
    assert.are.equal("ao-loading-chamber-remnants", r.name)
    assert.are.equal(4, r.tile_width)
    assert.are.equal(4, r.tile_height)
    assert.are.same({ { -2, -2 }, { 2, 2 } }, r.selection_box)
    assert.are.same({ "entity-name." .. Names.CHAMBER }, r.localised_name)
    local a = r.animation[1]
    assert.truthy(a.filename:find("simulation%-chamber%-remnants%.png$"))
    assert.are.equal(1, a.direction_count)
    assert.are.near(0.5 * 4 / 6, a.scale, EPS)
  end)

  it("gives the chamber its own sound", function()
    local s = Graphics.chamber_sound()
    local dir = "__abominable-ordnance__/sound/loading-chamber/"
    assert.are.equal(dir .. "simulation-chamber-working.ogg", s.sound.filename)
    assert.are.equal(dir .. "simulation-chamber-idle.ogg", s.idle_sound.filename)
    assert.are.equal(0.7, s.sound.volume)
    assert.are.equal(0.7, s.idle_sound.volume)
  end)

  it("tints only the band and larva layers", function()
    local biter, explosive = Species.ALL[1], Payloads.ALL[1]
    local icons = Graphics.loaded_larva(biter, explosive)
    assert.are.equal(5, #icons)
    assert.are.equal(Graphics.icon_path("larva-rocket-base.png"), icons[1].icon)
    assert.is_nil(icons[1].tint)
    local layers =
      { "larva-rocket-band-rear.png", "larva-rocket-band-front.png", "larva-rocket-larva.png" }
    for i, file in ipairs(layers) do
      assert.are.equal(Graphics.icon_path(file), icons[i + 1].icon)
      assert.are.same(biter.tint, icons[i + 1].tint)
    end
    assert.are.equal(explosive.icon, icons[5].icon)
    assert.are.equal(0.25, icons[5].scale)
    assert.are.same({ 8, 8 }, icons[5].shift)
    assert.is_nil(icons[5].tint)
  end)

  it("names files in two folders", function()
    assert.are.equal(
      "__abominable-ordnance__/graphics/icons/stasis-ward.png",
      Graphics.icon_path("stasis-ward.png")
    )
    assert.are.equal(
      "__abominable-ordnance__/graphics/technology/stasis-ward.png",
      Graphics.tech_path("stasis-ward.png")
    )
  end)

  it("rejects an unknown machine", function()
    assert.has_error(function()
      Graphics.machine("furnace", 3)
    end)
  end)
end)
