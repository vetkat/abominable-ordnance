-- Builds every prototype of slice 1 as plain tables. data.lua passes the
-- result to data:extend. This module reads no game globals: only its
-- parameters and other core modules.
local Balance = require("core.balance")
local Names = require("core.names")
local Species = require("core.species")

local Lifecycle = {}

Lifecycle.POD_TINT = { r = 0.85, g = 0.55, b = 0.75, a = 1 }
local FEEDS = {
  { name = Names.MONSTER_CHOW, tint = { r = 0.8, g = 0.4, b = 0.3, a = 1 } },
  { name = Names.SPITTER_CHOW, tint = { r = 0.6, g = 0.9, b = 0.3, a = 1 } },
}

-- Returns a copy of a graphics table. Every sprite that is not a shadow,
-- a light or a glow gets the tint.
local function tinted(value, tint)
  if type(value) ~= "table" then
    return value
  end
  local copy = {}
  for k, v in pairs(value) do
    copy[k] = tinted(v, tint)
  end
  local sprite = copy.filename or copy.filenames or copy.stripes
  if sprite and not (copy.draw_as_shadow or copy.draw_as_light or copy.draw_as_glow) then
    copy.tint = tint
  end
  return copy
end

local function icon(path, tint)
  return { { icon = path, icon_size = 64, tint = tint } }
end

local function item(name, path, tint, subgroup, stack)
  return {
    type = "item",
    name = name,
    icons = icon(path, tint),
    subgroup = subgroup,
    order = "z[ao]-" .. name,
    stack_size = stack,
  }
end

local function hatch_trigger(effect_id)
  return {
    items_per_trigger = Balance.hatch_ratio,
    trigger = {
      type = "direct",
      action_delivery = {
        type = "instant",
        source_effects = { { type = "script", effect_id = effect_id } },
      },
    },
  }
end

local function egg(species)
  local p = item(
    species.egg,
    "__base__/graphics/icons/small-" .. species.name .. ".png",
    species.tint,
    "intermediate-product",
    Balance.egg_stack
  )
  p.spoil_ticks = Balance.egg_spoil_ticks
  p.spoil_to_trigger_result = hatch_trigger(species.effect_id)
  return p
end

local function recipe(name, categories, time, ingredients, results)
  return {
    type = "recipe",
    name = name,
    categories = categories,
    enabled = false,
    energy_required = time,
    ingredients = ingredients,
    results = results,
  }
end

-- Space Age's recycler must not turn eggs back into their ingredients.
local function no_recycling(r)
  r.auto_recycle = false
  return r
end

local function breed(species)
  local b = Balance.breed
  return no_recycling(recipe("ao-breed-" .. species.name, { Names.CATEGORY }, b.time, {
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
  }))
end

local function feed_recipes()
  local m, s = Balance.monster_chow, Balance.spitter_chow
  return {
    recipe(Names.MONSTER_CHOW, { "chemistry" }, m.time, {
      { type = "item", name = "coal", amount = m.coal },
      { type = "item", name = "sulfur", amount = m.sulfur },
      { type = "fluid", name = "water", amount = m.water },
    }, { { type = "item", name = Names.MONSTER_CHOW, amount = m.result } }),
    recipe(Names.SPITTER_CHOW, { "chemistry" }, s.time, {
      { type = "item", name = Names.MONSTER_CHOW, amount = s.chow },
      { type = "fluid", name = "sulfuric-acid", amount = s.acid },
    }, { { type = "item", name = Names.SPITTER_CHOW, amount = s.result } }),
  }
end

local function pod(opts)
  local b = Balance.pod
  return {
    type = "assembling-machine",
    name = Names.POD,
    icons = icon("__base__/graphics/icons/chemical-plant.png", Lifecycle.POD_TINT),
    flags = { "placeable-neutral", "placeable-player", "player-creation" },
    minable = { mining_time = b.mining_time, result = Names.POD },
    max_health = b.max_health,
    corpse = "medium-remnants",
    collision_box = { { -1.2, -1.2 }, { 1.2, 1.2 } },
    selection_box = { { -1.5, -1.5 }, { 1.5, 1.5 } },
    crafting_categories = { Names.CATEGORY },
    crafting_speed = b.crafting_speed,
    energy_source = {
      type = "electric",
      usage_priority = "secondary-input",
      emissions_per_minute = { pollution = b.pollution },
    },
    energy_usage = b.energy_usage,
    module_slots = 0,
    allowed_effects = {},
    graphics_set = tinted(opts.graphics_set, Lifecycle.POD_TINT),
    working_sound = opts.working_sound,
  }
end

local function pod_item_and_recipe()
  local r = Balance.pod.recipe
  local pod_item = item(
    Names.POD,
    "__base__/graphics/icons/chemical-plant.png",
    Lifecycle.POD_TINT,
    "production-machine",
    Balance.pod.stack
  )
  pod_item.place_result = Names.POD
  return pod_item,
    recipe(Names.POD, { "crafting" }, r.time, {
      { type = "item", name = "iron-plate", amount = r.iron },
      { type = "item", name = "steel-plate", amount = r.steel },
      { type = "item", name = "pipe", amount = r.pipe },
      { type = "item", name = "electronic-circuit", amount = r.circuit },
    }, { { type = "item", name = Names.POD, amount = 1 } })
end

local function adopt(species)
  return no_recycling(recipe(Names.ADOPT, { Names.CATEGORY }, Balance.adopt.time, {
    { type = "item", name = species.adopts, amount = 1 },
    { type = "item", name = Names.MONSTER_CHOW, amount = Balance.adopt.chow },
  }, { { type = "item", name = species.egg, amount = 1 } }))
end

local function technology(recipes)
  local effects = {}
  for _, r in ipairs(recipes) do
    effects[#effects + 1] = { type = "unlock-recipe", recipe = r.name }
  end
  return {
    type = "technology",
    name = Names.TECH,
    icons = icon("__base__/graphics/icons/small-biter.png", Lifecycle.POD_TINT),
    prerequisites = { "military-science-pack", "chemical-science-pack" },
    effects = effects,
    unit = {
      count = Balance.research.count,
      time = Balance.research.time,
      ingredients = {
        { "automation-science-pack", 1 },
        { "logistic-science-pack", 1 },
        { "military-science-pack", 1 },
        { "chemical-science-pack", 1 },
      },
    },
  }
end

function Lifecycle.prototypes(opts)
  local out = { { type = "recipe-category", name = Names.CATEGORY } }
  local recipes = feed_recipes()
  for _, feed in ipairs(FEEDS) do
    out[#out + 1] = item(
      feed.name,
      "__base__/graphics/icons/coal.png",
      feed.tint,
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
  local pod_item, pod_recipe = pod_item_and_recipe()
  out[#out + 1] = pod_item
  out[#out + 1] = pod(opts)
  recipes[#recipes + 1] = pod_recipe
  for _, r in ipairs(recipes) do
    out[#out + 1] = r
  end
  out[#out + 1] = technology(recipes)
  return out
end

return Lifecycle
