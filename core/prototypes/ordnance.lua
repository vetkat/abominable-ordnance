-- Builds every prototype of slice 2 as plain tables. data.lua passes the
-- result to data:extend. This module reads no game globals: only its
-- parameters and other core modules.
local Balance = require("core.balance")
local Common = require("core.prototypes.common")
local Names = require("core.names")
local Payloads = require("core.payloads")
local Species = require("core.species")

local Ordnance = {}

Ordnance.INCUBATOR_TINT = { r = 0.7, g = 0.85, b = 0.6, a = 1 }
Ordnance.CHAMBER_TINT = { r = 0.85, g = 0.6, b = 0.5, a = 1 }

local function larva_icon(species)
  return Common.icon("__base__/graphics/icons/medium-" .. species.name .. ".png", species.tint)
end

-- An item that spoils into one script effect per item. numbers has stack
-- and spoil_ticks.
local function spoiling(name, icons, numbers, effect_id)
  local p = Common.item(name, icons, "intermediate-product", numbers.stack)
  p.spoil_ticks = numbers.spoil_ticks
  p.spoil_to_trigger_result = Common.spoil_trigger(effect_id, 1)
  return p
end

-- A recipe with one fresh result that the recycler must not undo.
local function fresh_recipe(name, category, time, ingredients, result)
  return Common.no_recycling(
    Common.recipe(
      name,
      { category },
      time,
      ingredients,
      { { type = "item", name = result, amount = 1, reset_freshness_on_craft = true } }
    )
  )
end

-- A larva icon with the payload icon in its corner.
local function loaded_icon(species, payload)
  local icons = larva_icon(species)
  icons[#icons + 1] = { icon = payload.icon, icon_size = 64, scale = 0.25, shift = { 8, 8 } }
  return icons
end

local function ordnance_loading(recipes)
  return Common.technology({
    name = Names.ORDNANCE_TECH,
    icons = Common.icon("__base__/graphics/icons/explosive-rocket.png", Ordnance.CHAMBER_TINT),
    prerequisites = { Names.TECH, "explosive-rocketry" },
    count = Balance.ordnance_research.count,
    time = Balance.ordnance_research.time,
    packs = {
      "automation-science-pack",
      "logistic-science-pack",
      "military-science-pack",
      "chemical-science-pack",
    },
    unlocks = Common.names(recipes),
  })
end

-- Larvae, the incubator and their recipes. Returns the prototypes and
-- the recipes.
local function incubation(graphics)
  local out = { { type = "recipe-category", name = Names.INCUBATION } }
  local recipes = {}
  for _, species in ipairs(Species.ALL) do
    out[#out + 1] = spoiling(species.larva, larva_icon(species), Balance.larva, species.effect_id)
    recipes[#recipes + 1] = fresh_recipe(
      "ao-incubate-" .. species.name,
      Names.INCUBATION,
      Balance.incubate.time,
      { { type = "item", name = species.egg, amount = Balance.incubate.eggs } },
      species.larva
    )
  end
  local r = Balance.incubator.recipe
  local item, recipe, machine = Common.machine_kit({
    name = Names.INCUBATOR,
    icon = "__base__/graphics/icons/centrifuge.png",
    tint = Ordnance.INCUBATOR_TINT,
    categories = { Names.INCUBATION },
    graphics = graphics,
    numbers = Balance.incubator,
    ingredients = {
      { type = "item", name = "steel-plate", amount = r.steel },
      { type = "item", name = "electronic-circuit", amount = r.circuit },
      { type = "item", name = "pipe", amount = r.pipe },
    },
  })
  recipes[#recipes + 1] = recipe
  out[#out + 1] = item
  out[#out + 1] = machine
  return out, recipes
end

-- Loaded larvae, the chamber, their recipes and their technology.
-- Returns the prototypes and the recipes.
local function loading(graphics)
  local out = { { type = "recipe-category", name = Names.LOADING } }
  local recipes = {}
  for _, species in ipairs(Species.ALL) do
    for _, payload in ipairs(Payloads.ALL) do
      local name = Payloads.loaded_name(species, payload)
      out[#out + 1] = spoiling(
        name,
        loaded_icon(species, payload),
        Balance.loaded,
        Payloads.effect_id(species, payload)
      )
      recipes[#recipes + 1] =
        fresh_recipe(Payloads.load_recipe(species, payload), Names.LOADING, Balance.load.time, {
          { type = "item", name = species.larva, amount = 1 },
          { type = "item", name = payload.item, amount = 1 },
        }, name)
    end
  end
  local r = Balance.chamber.recipe
  local item, recipe, machine = Common.machine_kit({
    name = Names.CHAMBER,
    icon = "__base__/graphics/icons/assembling-machine-3.png",
    tint = Ordnance.CHAMBER_TINT,
    categories = { Names.LOADING },
    graphics = graphics,
    numbers = Balance.chamber,
    ingredients = {
      { type = "item", name = "steel-plate", amount = r.steel },
      { type = "item", name = "advanced-circuit", amount = r.advanced },
      { type = "item", name = "iron-gear-wheel", amount = r.gear },
    },
  })
  recipes[#recipes + 1] = recipe
  out[#out + 1] = item
  out[#out + 1] = machine
  out[#out + 1] = ordnance_loading(recipes)
  return out, recipes
end

local function append(out, list)
  for _, p in ipairs(list) do
    out[#out + 1] = p
  end
end

-- Returns the prototypes and the names of the recipes that Monster
-- husbandry unlocks. opts.incubator and opts.chamber hold the
-- graphics_set and working_sound to copy.
function Ordnance.prototypes(opts)
  local out = {}
  local incubation_protos, husbandry = incubation(opts.incubator)
  local loading_protos, loading_recipes = loading(opts.chamber)
  for _, list in ipairs({ incubation_protos, husbandry, loading_protos, loading_recipes }) do
    append(out, list)
  end
  return out, Common.names(husbandry)
end

return Ordnance
