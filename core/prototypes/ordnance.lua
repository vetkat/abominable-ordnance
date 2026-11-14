-- Builds every prototype of slice 2 as plain tables. data.lua passes the
-- result to data:extend. This module reads no game globals: only its
-- parameters and other core modules.
local Balance = require("core.balance")
local Common = require("core.prototypes.common")
local Names = require("core.names")
local Species = require("core.species")

local Ordnance = {}

Ordnance.INCUBATOR_TINT = { r = 0.7, g = 0.85, b = 0.6, a = 1 }

local function larva_icon(species)
  return Common.icon("__base__/graphics/icons/medium-" .. species.name .. ".png", species.tint)
end

local function larva(species)
  local p =
    Common.item(species.larva, larva_icon(species), "intermediate-product", Balance.larva.stack)
  p.spoil_ticks = Balance.larva.spoil_ticks
  p.spoil_to_trigger_result = Common.spoil_trigger(species.effect_id, 1)
  return p
end

local function incubate(species)
  local b = Balance.incubate
  return Common.no_recycling(
    Common.recipe(
      "ao-incubate-" .. species.name,
      { Names.INCUBATION },
      b.time,
      { { type = "item", name = species.egg, amount = b.eggs } },
      { { type = "item", name = species.larva, amount = 1, reset_freshness_on_craft = true } }
    )
  )
end

-- The incubator's item, recipe and machine.
local function incubator(graphics)
  local b = Balance.incubator
  local icons = Common.icon("__base__/graphics/icons/centrifuge.png", Ordnance.INCUBATOR_TINT)
  local recipe = Common.recipe(Names.INCUBATOR, { "crafting" }, b.recipe.time, {
    { type = "item", name = "steel-plate", amount = b.recipe.steel },
    { type = "item", name = "electronic-circuit", amount = b.recipe.circuit },
    { type = "item", name = "pipe", amount = b.recipe.pipe },
  }, { { type = "item", name = Names.INCUBATOR, amount = 1 } })
  local machine = Common.machine({
    name = Names.INCUBATOR,
    icons = icons,
    categories = { Names.INCUBATION },
    graphics = graphics,
    tint = Ordnance.INCUBATOR_TINT,
    numbers = b,
  })
  return Common.placeable(Names.INCUBATOR, icons, b.stack), recipe, machine
end

-- Returns the prototypes and the names of the recipes that Monster
-- husbandry unlocks. opts.incubator holds the graphics_set and
-- working_sound to copy.
function Ordnance.prototypes(opts)
  local out = { { type = "recipe-category", name = Names.INCUBATION } }
  local husbandry = {}
  for _, species in ipairs(Species.ALL) do
    out[#out + 1] = larva(species)
    husbandry[#husbandry + 1] = incubate(species)
  end
  local item, recipe, machine = incubator(opts.incubator)
  husbandry[#husbandry + 1] = recipe
  out[#out + 1] = item
  out[#out + 1] = machine
  for _, r in ipairs(husbandry) do
    out[#out + 1] = r
  end
  return out, Common.names(husbandry)
end

return Ordnance
