-- Builds every prototype of slice 1 as plain tables. data.lua passes the
-- result to data:extend. This module reads no game globals: only its
-- parameters and other core modules.
local Balance = require("core.balance")
local Common = require("core.prototypes.common")
local Names = require("core.names")
local Species = require("core.species")

local Lifecycle = {}

Lifecycle.POD_TINT = { r = 0.85, g = 0.55, b = 0.75, a = 1 }
local FEEDS = {
  { name = Names.MONSTER_CHOW, tint = { r = 0.8, g = 0.4, b = 0.3, a = 1 } },
  { name = Names.SPITTER_CHOW, tint = { r = 0.6, g = 0.9, b = 0.3, a = 1 } },
}

local function egg(species)
  local p = Common.item(
    species.egg,
    Common.icon("__base__/graphics/icons/small-" .. species.name .. ".png", species.tint),
    "intermediate-product",
    Balance.egg_stack
  )
  p.spoil_ticks = Balance.egg_spoil_ticks
  p.spoil_to_trigger_result = Common.spoil_trigger(species.effect_id, Balance.hatch_ratio)
  return p
end

local function breed(species)
  local b = Balance.breed
  return Common.no_recycling(
    Common.recipe("ao-breed-" .. species.name, { Names.CATEGORY }, b.time, {
      { type = "item", name = species.egg, amount = 1, ignored_by_stats = 1 },
      { type = "item", name = species.feed, amount = b.chow },
    }, {
      {
        type = "item",
        name = species.egg,
        amount = b.result,
        ignored_by_stats = 1,
        ignored_by_productivity = 1,
        reset_freshness_on_craft = true,
      },
    })
  )
end

local function feed_recipes()
  local m, s = Balance.monster_chow, Balance.spitter_chow
  return {
    Common.recipe(Names.MONSTER_CHOW, { "chemistry" }, m.time, {
      { type = "item", name = "coal", amount = m.coal },
      { type = "item", name = "sulfur", amount = m.sulfur },
      { type = "fluid", name = "water", amount = m.water },
    }, { { type = "item", name = Names.MONSTER_CHOW, amount = m.result } }),
    Common.recipe(Names.SPITTER_CHOW, { "chemistry" }, s.time, {
      { type = "item", name = Names.MONSTER_CHOW, amount = s.chow },
      { type = "fluid", name = "sulfuric-acid", amount = s.acid },
    }, { { type = "item", name = Names.SPITTER_CHOW, amount = s.result } }),
  }
end

-- The pod's item, recipe and machine.
local function pod(graphics)
  local r = Balance.pod.recipe
  return Common.machine_kit({
    name = Names.POD,
    icon = "__base__/graphics/icons/chemical-plant.png",
    tint = Lifecycle.POD_TINT,
    categories = { Names.CATEGORY },
    graphics = graphics,
    numbers = Balance.pod,
    ingredients = {
      { type = "item", name = "iron-plate", amount = r.iron },
      { type = "item", name = "steel-plate", amount = r.steel },
      { type = "item", name = "pipe", amount = r.pipe },
      { type = "item", name = "electronic-circuit", amount = r.circuit },
    },
  })
end

local function adopt(species)
  return Common.no_recycling(Common.recipe(Names.ADOPT, { Names.CATEGORY }, Balance.adopt.time, {
    { type = "item", name = species.adopts, amount = 1 },
    { type = "item", name = Names.MONSTER_CHOW, amount = Balance.adopt.chow },
  }, { { type = "item", name = species.egg, amount = 1 } }))
end

-- opts.pod holds the graphics_set and working_sound to copy.
-- opts.extra_unlocks names more recipes for Monster husbandry.
function Lifecycle.prototypes(opts)
  local out = { { type = "recipe-category", name = Names.CATEGORY } }
  local recipes = feed_recipes()
  for _, feed in ipairs(FEEDS) do
    out[#out + 1] = Common.item(
      feed.name,
      Common.icon("__base__/graphics/icons/coal.png", feed.tint),
      "intermediate-product",
      Balance.chow_stack
    )
  end
  for _, species in ipairs(Species.ALL) do
    out[#out + 1] = egg(species)
    recipes[#recipes + 1] = breed(species)
    if opts.space_age and species.adopts then
      recipes[#recipes + 1] = adopt(species)
    end
  end
  local pod_item, pod_recipe, pod_machine = pod(opts.pod)
  out[#out + 1] = pod_item
  out[#out + 1] = pod_machine
  recipes[#recipes + 1] = pod_recipe
  local unlocks = Common.names(recipes)
  for _, name in ipairs(opts.extra_unlocks or {}) do
    unlocks[#unlocks + 1] = name
  end
  for _, r in ipairs(recipes) do
    out[#out + 1] = r
  end
  out[#out + 1] = Common.technology({
    name = Names.TECH,
    icons = Common.icon("__base__/graphics/icons/small-biter.png", Lifecycle.POD_TINT),
    prerequisites = { "military-science-pack", "chemical-science-pack" },
    count = Balance.research.count,
    time = Balance.research.time,
    packs = {
      "automation-science-pack",
      "logistic-science-pack",
      "military-science-pack",
      "chemical-science-pack",
    },
    unlocks = unlocks,
  })
  return out
end

return Lifecycle
