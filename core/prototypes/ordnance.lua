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
  p.spoil_to_trigger_result = Common.spoil_trigger(species.larva_effect_id, 1)
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

local function incubator(opts)
  local icons = Common.icon("__base__/graphics/icons/centrifuge.png", Ordnance.INCUBATOR_TINT)
  local b = Balance.incubator
  local item = Common.item(Names.INCUBATOR, icons, "production-machine", b.stack)
  item.place_result = Names.INCUBATOR
  local recipe = Common.recipe(Names.INCUBATOR, { "crafting" }, b.recipe.time, {
    { type = "item", name = "steel-plate", amount = b.recipe.steel },
    { type = "item", name = "electronic-circuit", amount = b.recipe.circuit },
    { type = "item", name = "pipe", amount = b.recipe.pipe },
  }, { { type = "item", name = Names.INCUBATOR, amount = 1 } })
  local machine = Common.machine({
    name = Names.INCUBATOR,
    icons = icons,
    categories = { Names.INCUBATION },
    graphics = opts.incubator,
    tint = Ordnance.INCUBATOR_TINT,
    numbers = b,
  })
  return item, recipe, machine
end

-- The recipes that Monster husbandry unlocks for this slice.
function Ordnance.husbandry_unlocks()
  local names = {}
  for _, species in ipairs(Species.ALL) do
    names[#names + 1] = "ao-incubate-" .. species.name
  end
  names[#names + 1] = Names.INCUBATOR
  return names
end

-- opts.incubator holds the graphics_set and working_sound to copy.
function Ordnance.prototypes(opts)
  local out = { { type = "recipe-category", name = Names.INCUBATION } }
  for _, species in ipairs(Species.ALL) do
    out[#out + 1] = larva(species)
    out[#out + 1] = incubate(species)
  end
  local item, recipe, machine = incubator(opts)
  out[#out + 1] = item
  out[#out + 1] = recipe
  out[#out + 1] = machine
  return out
end

return Ordnance
