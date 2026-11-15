-- Builds the stasis ward of slice 5 as plain tables. data.lua passes the
-- result to data:extend. This module reads no game globals: only its
-- parameters and other core modules.
local Balance = require("core.balance")
local Common = require("core.prototypes.common")
local Names = require("core.names")
local Payloads = require("core.payloads")
local Species = require("core.species")

local Stasis = {}

Stasis.SUBGROUP = "ao-stasis"
Stasis.WARD_ICON = "__base__/graphics/icons/plastic-bar.png"
Stasis.WARD_TINT = { r = 0.55, g = 0.8, b = 1, a = 1 }

local PACKS = {
  "automation-science-pack",
  "logistic-science-pack",
  "military-science-pack",
  "chemical-science-pack",
}

-- The 10 lifecycle items of version 1: the eggs, the larvae and the
-- larva rockets. A version 2 item joins only by a change here.
function Stasis.lifecycle_names()
  local names = {}
  for _, species in ipairs(Species.ALL) do
    names[#names + 1] = species.egg
    names[#names + 1] = species.larva
  end
  for _, species in ipairs(Species.ALL) do
    for _, payload in ipairs(Payloads.ALL) do
      names[#names + 1] = Payloads.loaded_name(species, payload)
    end
  end
  return names
end

local function suffix(name)
  return (name:gsub("^ao%-", ""))
end

function Stasis.warded_name(name)
  return Names.WARDED .. suffix(name)
end

function Stasis.pack_recipe(name)
  return Names.PACK .. suffix(name)
end

function Stasis.unpack_recipe(name)
  return Names.UNPACK .. suffix(name)
end

-- A copy of an item's icons with the ward icon in the corner.
local function with_ward(icons)
  local out = Common.copy(icons)
  out[#out + 1] = {
    icon = Stasis.WARD_ICON,
    icon_size = 64,
    scale = 0.25,
    shift = { 8, 8 },
    tint = Stasis.WARD_TINT,
  }
  return out
end

-- Pack and unpack give no free quality, no free items and no crafting
-- loops, and the recycler must not undo them.
local function locked(r)
  r.allow_quality = false
  r.allow_productivity = false
  r.maximum_productivity = 0
  r.allow_decomposition = false
  r.allow_as_intermediate = false
  r.subgroup = Stasis.SUBGROUP
  return Common.no_recycling(r)
end

-- A warded item is a new plain item. It never copies the source, so a
-- larva rocket's ammo fields stay out.
local function warded(source)
  local p = Common.item(
    Stasis.warded_name(source.name),
    with_ward(source.icons),
    Stasis.SUBGROUP,
    source.stack_size
  )
  p.spoil_ticks = source.spoil_ticks * Balance.stasis.factor
  p.spoil_to_trigger_result = Common.copy(source.spoil_to_trigger_result)
  p.auto_recycle = false
  return p
end

local function item(name, amount)
  return { type = "item", name = name, amount = amount }
end

local function pack(source, ward)
  return locked(
    Common.recipe(
      Stasis.pack_recipe(source.name),
      { "crafting" },
      Balance.stasis.pack_time,
      { item(source.name, 1), item(Names.WARD, 1) },
      { item(ward.name, 1) }
    )
  )
end

local function unpack(source, ward)
  local r = locked(
    Common.recipe(
      Stasis.unpack_recipe(source.name),
      { "crafting" },
      Balance.stasis.pack_time,
      { item(ward.name, 1) },
      { item(source.name, 1), item(Names.WARD, 1) }
    )
  )
  r.main_product = source.name
  r.icons = with_ward(source.icons)
  return r
end

-- The ward itself, its recipe and the subgroup for every stasis
-- prototype.
local function ward_kit()
  local w = Balance.stasis.ward
  local icons = Common.icon(Stasis.WARD_ICON, Stasis.WARD_TINT)
  local subgroup = {
    type = "item-subgroup",
    name = Stasis.SUBGROUP,
    group = "intermediate-products",
    order = "z[ao]-stasis",
  }
  local recipe = Common.recipe(Names.WARD, { "crafting" }, w.time, {
    item("plastic-bar", w.plastic),
    item("steel-plate", w.steel),
    item("electronic-circuit", w.circuit),
  }, { item(Names.WARD, 1) })
  recipe.subgroup = Stasis.SUBGROUP
  return subgroup, Common.item(Names.WARD, icons, Stasis.SUBGROUP, w.stack), recipe
end

-- Returns the stasis prototypes. sources is a list of prototypes that
-- holds the lifecycle items, as Lifecycle.prototypes and
-- Ordnance.prototypes return them. A lifecycle item that sources lack
-- gets no warded version.
function Stasis.prototypes(sources)
  local by_name = {}
  for _, p in ipairs(sources) do
    if p.spoil_ticks then
      by_name[p.name] = p
    end
  end
  local subgroup, ward_item, ward_recipe = ward_kit()
  local out = { subgroup, ward_item, ward_recipe }
  local unlocks = { ward_recipe.name }
  for _, name in ipairs(Stasis.lifecycle_names()) do
    local source = by_name[name]
    if source then
      local w = warded(source)
      local p, u = pack(source, w), unpack(source, w)
      Common.append(out, { w, p, u })
      Common.append(unlocks, { p.name, u.name })
    end
  end
  out[#out + 1] = Common.technology({
    name = Names.STASIS_TECH,
    icons = Common.icon(Stasis.WARD_ICON, Stasis.WARD_TINT),
    prerequisites = { Names.ORDNANCE_TECH },
    count = Balance.stasis.research.count,
    time = Balance.stasis.research.time,
    packs = PACKS,
    unlocks = unlocks,
  })
  return out
end

return Stasis
