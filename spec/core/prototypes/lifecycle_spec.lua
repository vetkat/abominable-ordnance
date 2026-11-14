local Lifecycle = require("core.prototypes.lifecycle")
local Stubs = require("spec.support.stubs")

local function build(space_age)
  return Stubs.by_name(Lifecycle.prototypes(Stubs.lifecycle_opts(space_age)))
end

describe("the lifecycle prototypes", function()
  it("make the adopt recipe only with Space Age", function()
    assert.is_nil(build(false)["recipe/ao-adopt-biter-egg"])
    assert.truthy(build(true)["recipe/ao-adopt-biter-egg"])
  end)

  it("tint the pod's own copy of the graphics, but not shadows", function()
    local opts = Stubs.lifecycle_opts()
    local pod = Stubs.by_name(Lifecycle.prototypes(opts))["assembling-machine/ao-breeding-pod"]
    local layers = pod.graphics_set.animation.layers
    assert.are.same(Lifecycle.POD_TINT, layers[1].tint)
    assert.is_nil(layers[2].tint)
    assert.is_nil(opts.pod.graphics_set.animation.layers[1].tint)
    assert.are.same(opts.pod.working_sound, pod.working_sound)
  end)

  it("give the pod no module or beacon effects", function()
    local pod = build(false)["assembling-machine/ao-breeding-pod"]
    assert.are.equal(0, pod.module_slots)
    assert.are.same({}, pod.allowed_effects)
  end)

  it("give the breeding recipes the flags of pentapod-egg", function()
    for _, name in ipairs({ "ao-breed-biter", "ao-breed-spitter" }) do
      local recipe = build(false)["recipe/" .. name]
      assert.are.equal(1, recipe.ingredients[1].ignored_by_stats)
      local result = recipe.results[1]
      assert.are.equal(1, result.ignored_by_stats)
      assert.are.equal(1, result.ignored_by_productivity)
      assert.is_true(result.reset_freshness_on_craft)
      assert.is_false(recipe.auto_recycle)
    end
    assert.is_false(build(true)["recipe/ao-adopt-biter-egg"].auto_recycle)
  end)

  it("need military and chemical science first", function()
    assert.are.same(
      { "military-science-pack", "chemical-science-pack" },
      build(false)["technology/ao-monster-husbandry"].prerequisites
    )
  end)

  it("hatch one monster per 10 eggs through a script trigger", function()
    local egg = build(false)["item/ao-spitter-egg"]
    local result = egg.spoil_to_trigger_result
    assert.are.equal(10, result.items_per_trigger)
    local effect = result.trigger.action_delivery.source_effects[1]
    assert.are.same({ type = "script", effect_id = "ao-hatch-spitter" }, effect)
  end)

  it("use only known items and fluids", function()
    for _, space_age in ipairs({ false, true }) do
      local all = build(space_age)
      local known = {
        ["biter-egg"] = true,
        coal = true,
        sulfur = true,
        water = true,
        ["sulfuric-acid"] = true,
        ["iron-plate"] = true,
        ["steel-plate"] = true,
        pipe = true,
        ["electronic-circuit"] = true,
      }
      for key in pairs(all) do
        local name = key:match("^item/(.+)$")
        if name then
          known[name] = true
        end
      end
      for key, p in pairs(all) do
        if key:match("^recipe/") then
          for _, list in ipairs({ p.ingredients, p.results }) do
            for _, entry in ipairs(list) do
              assert.truthy(known[entry.name], key .. " uses " .. entry.name)
            end
          end
        end
      end
    end
  end)

  it("unlock every recipe through Monster husbandry", function()
    local all = build(true)
    local unlocked = {}
    for _, effect in ipairs(all["technology/ao-monster-husbandry"].effects) do
      unlocked[effect.recipe] = true
    end
    for key, p in pairs(all) do
      if key:match("^recipe/") then
        assert.is_false(p.enabled, p.name)
        assert.truthy(unlocked[p.name], p.name)
      end
    end
  end)
end)
