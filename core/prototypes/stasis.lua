-- Builds the stasis wards as plain tables. data.lua passes the result to
-- data:extend. This module reads no game globals: only its parameters
-- and other core modules.
--
-- A ward kind is the plain data that tells one ward from another: its
-- names, its factor, its tint, its recipe and its research. The builder
-- reads a kind and never changes it.
local Balance = require("core.balance")
local Common = require("core.prototypes.common")
local Names = require("core.names")
local Payloads = require("core.payloads")
local Species = require("core.species")

local Stasis = {}

Stasis.SUBGROUP = "ao-stasis"
Stasis.WARD_ICON = "__base__/graphics/icons/plastic-bar.png"
Stasis.WARD_TINT = { r = 0.55, g = 0.8, b = 1, a = 1 }
-- A colder blue than the base ward, so the two icons differ at a glance.
Stasis.CRYO_TINT = { r = 0.3, g = 0.55, b = 1, a = 1 }

local PACKS = {
  "automation-science-pack",
  "logistic-science-pack",
  "military-science-pack",
  "chemical-science-pack",
}

local CRYO_PACKS = Common.copy(PACKS)
CRYO_PACKS[#CRYO_PACKS + 1] = "space-science-pack"
CRYO_PACKS[#CRYO_PACKS + 1] = "cryogenic-science-pack"

-- The ward recipe fields that a kind may set beyond its ingredients.
local WARD_RECIPE_FIELDS =
  { "surface_conditions", "main_product", "auto_recycle", "allow_productivity", "allow_quality" }

local function item(name, amount)
  return { type = "item", name = name, amount = amount }
end

local function fluid(name, amount)
  return { type = "fluid", name = name, amount = amount }
end

-- The key of a prototype in a set of facts, as "type/name".
function Stasis.key(type, name)
  return type .. "/" .. name
end

-- The base ward of slice 5, in both modes.
local function base_kind()
  local w = Balance.stasis.ward
  return {
    name = Names.WARD,
    factor = Balance.stasis.factor,
    pack_time = Balance.stasis.pack_time,
    warded = Names.WARDED,
    pack = Names.PACK,
    unpack = Names.UNPACK,
    tint = Stasis.WARD_TINT,
    stack = w.stack,
    recipe = {
      categories = { "crafting" },
      time = w.time,
      ingredients = {
        item("plastic-bar", w.plastic),
        item("steel-plate", w.steel),
        item("electronic-circuit", w.circuit),
      },
      results = { item(Names.WARD, 1) },
    },
    research = {
      name = Names.STASIS_TECH,
      prerequisites = { Names.ORDNANCE_TECH },
      count = Balance.stasis.research.count,
      time = Balance.stasis.research.time,
      packs = PACKS,
    },
    -- The prototypes of other mods that the kind needs. The builder does
    -- not read this. Stasis.kinds drops a kind whose needs are missing.
    -- The base ward needs none: data.lua asserts its vanilla ingredients.
    needs = {},
  }
end

Stasis.BASE = base_kind()

-- The cryo ward of Space Age. A cryogenic plant on Aquilo makes it from
-- lithium plates and cold fluoroketone, and gives hot fluoroketone back
-- into Aquilo's loop. The pressure condition keeps the recipe on
-- Aquilo. The plant takes quality modules, so the recipe allows no
-- quality and no recycling: a ward made with quality and recycled would
-- give lithium plates a second roll. The recipe needs the pressure of
-- Aquilo, which the data stage reads from the planet. Without a
-- pressure, the kind falls back to the balance value.
function Stasis.cryo_kind(pressure)
  local c = Balance.cryo
  pressure = pressure or c.pressure
  return {
    name = Names.CRYO_WARD,
    factor = c.factor,
    pack_time = c.pack_time,
    warded = Names.CRYO_WARDED,
    pack = Names.CRYO_PACK,
    unpack = Names.CRYO_UNPACK,
    tint = Stasis.CRYO_TINT,
    stack = c.ward.stack,
    recipe = {
      categories = { "cryogenics" },
      time = c.ward.time,
      ingredients = {
        item("lithium-plate", c.ward.lithium),
        fluid("fluoroketone-cold", c.ward.cold),
      },
      results = { item(Names.CRYO_WARD, 1), fluid("fluoroketone-hot", c.ward.hot) },
      surface_conditions = { { property = "pressure", min = pressure, max = pressure } },
      main_product = Names.CRYO_WARD,
      auto_recycle = false,
      allow_productivity = false,
      allow_quality = false,
    },
    research = {
      name = Names.CRYO_TECH,
      prerequisites = { Names.STASIS_TECH, "cryogenic-science-pack" },
      count = c.research.count,
      time = c.research.time,
      packs = CRYO_PACKS,
    },
    needs = {
      { type = "item", name = "lithium-plate" },
      { type = "fluid", name = "fluoroketone-cold" },
      { type = "fluid", name = "fluoroketone-hot" },
      { type = "recipe-category", name = "cryogenics" },
      { type = "technology", name = "cryogenic-science-pack" },
      { type = "item", name = "space-science-pack" },
      { type = "item", name = "cryogenic-science-pack" },
      { type = "assembling-machine", name = "cryogenic-plant" },
      { type = "planet", name = "aquilo" },
    },
  }
end

Stasis.CRYO = Stasis.cryo_kind()

-- Picks the kinds to build from the facts of the data stage. The field
-- space_age is true when Space Age is on. The field has is a set of
-- "type/name" keys for the prototypes that exist. The field pressure is
-- the pressure of Aquilo, and may be nil.
--
-- Returns the kinds and the keys that the cryo kind needs but has lacks.
-- The base kind is always in the list. The cryo kind joins it with Space
-- Age when nothing is missing.
function Stasis.kinds(facts)
  local kinds = { Stasis.BASE }
  if not facts.space_age then
    return kinds, {}
  end
  local has = facts.has or {}
  local missing = {}
  for _, need in ipairs(Stasis.CRYO.needs) do
    local key = Stasis.key(need.type, need.name)
    if not has[key] then
      missing[#missing + 1] = key
    end
  end
  if #missing == 0 then
    kinds[#kinds + 1] = Stasis.cryo_kind(facts.pressure)
  end
  return kinds, missing
end

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

function Stasis.warded_name(kind, name)
  return kind.warded .. suffix(name)
end

function Stasis.pack_recipe(kind, name)
  return kind.pack .. suffix(name)
end

function Stasis.unpack_recipe(kind, name)
  return kind.unpack .. suffix(name)
end

local function ward_icons(kind)
  return Common.icon(Stasis.WARD_ICON, kind.tint)
end

-- A copy of an item's icons with the kind's ward icon in the corner.
local function with_ward(icons, kind)
  local out = Common.copy(icons)
  out[#out + 1] = {
    icon = Stasis.WARD_ICON,
    icon_size = 64,
    scale = 0.25,
    shift = { 8, 8 },
    tint = kind.tint,
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

-- Returns a copy of a prototype list in which every item that spoils has
-- an explicit weight. The weight is the rocket lift weight over the stack
-- size, which is the engine's default. Without it, Space Age derives a
-- weight from the item's recipe. A warded item has another recipe, so it
-- would weigh something else. A weight that a prototype sets stays. The
-- input list and its prototypes stay as they are.
function Stasis.weighted(list, lift_weight)
  local out = {}
  for i, p in ipairs(list) do
    if p.spoil_ticks and not p.weight then
      p = Common.copy(p)
      p.weight = lift_weight / p.stack_size
    end
    out[i] = p
  end
  return out
end

-- A warded item is a new plain item. It never copies the source, so a
-- larva rocket's ammo fields stay out.
local function warded(source, kind)
  local p = Common.item(
    Stasis.warded_name(kind, source.name),
    with_ward(source.icons, kind),
    Stasis.SUBGROUP,
    source.stack_size
  )
  p.spoil_ticks = source.spoil_ticks * kind.factor
  p.spoil_to_trigger_result = Common.copy(source.spoil_to_trigger_result)
  p.weight = source.weight
  p.auto_recycle = false
  return p
end

-- Pack and unpack sort by their warded item's order, pack first.
local function pack(source, ward, kind)
  local r = locked(
    Common.recipe(
      Stasis.pack_recipe(kind, source.name),
      { "crafting" },
      kind.pack_time,
      { item(source.name, 1), item(kind.name, 1) },
      { item(ward.name, 1) }
    )
  )
  r.order = ward.order .. "-a"
  return r
end

local function unpack(source, ward, kind)
  local r = locked(
    Common.recipe(
      Stasis.unpack_recipe(kind, source.name),
      { "crafting" },
      kind.pack_time,
      { item(ward.name, 1) },
      { item(source.name, 1), item(kind.name, 1) }
    )
  )
  r.order = ward.order .. "-b"
  r.main_product = source.name
  r.icons = with_ward(source.icons, kind)
  return r
end

-- The subgroup for every stasis prototype, of every kind.
local function subgroup()
  return {
    type = "item-subgroup",
    name = Stasis.SUBGROUP,
    group = "intermediate-products",
    order = "z[ao]-stasis",
  }
end

-- A kind's ward item and the recipe that makes it.
local function ward_kit(kind)
  local k = kind.recipe
  local recipe = Common.recipe(
    kind.name,
    Common.copy(k.categories),
    k.time,
    Common.copy(k.ingredients),
    Common.copy(k.results)
  )
  recipe.subgroup = Stasis.SUBGROUP
  for field, value in pairs(Common.pick(k, WARD_RECIPE_FIELDS)) do
    recipe[field] = value
  end
  local ward_item = Common.item(kind.name, ward_icons(kind), Stasis.SUBGROUP, kind.stack)
  recipe.order = ward_item.order
  return ward_item, recipe
end

-- One kind's ward, its warded items, their recipes and its research.
-- by_name indexes the lifecycle items. It raises an error for a
-- lifecycle item that by_name lacks, because the pack and unpack
-- recipes need it.
local function kind_prototypes(kind, by_name)
  local ward_item, ward_recipe = ward_kit(kind)
  local out = { ward_item, ward_recipe }
  local unlocks = { ward_recipe.name }
  for _, name in ipairs(Stasis.lifecycle_names()) do
    local source = by_name[name]
    if not source then
      error("stasis: the sources lack the lifecycle item " .. name)
    end
    local w = warded(source, kind)
    local p, u = pack(source, w, kind), unpack(source, w, kind)
    Common.append(out, { w, p, u })
    Common.append(unlocks, { p.name, u.name })
  end
  local research = kind.research
  out[#out + 1] = Common.technology({
    name = research.name,
    icons = ward_icons(kind),
    prerequisites = Common.copy(research.prerequisites),
    count = research.count,
    time = research.time,
    packs = research.packs,
    unlocks = unlocks,
  })
  return out
end

-- Returns the stasis prototypes of every kind in kinds, with the
-- subgroup once. sources is a list of prototypes that holds the
-- lifecycle items. Lifecycle.prototypes and Ordnance.prototypes
-- return such lists.
function Stasis.prototypes(sources, kinds)
  if not kinds then
    error("stasis: Stasis.prototypes needs a list of kinds")
  end
  local by_name = {}
  for _, p in ipairs(sources) do
    if p.spoil_ticks then
      by_name[p.name] = p
    end
  end
  local out = { subgroup() }
  for _, kind in ipairs(kinds) do
    Common.append(out, kind_prototypes(kind, by_name))
  end
  return out
end

return Stasis
