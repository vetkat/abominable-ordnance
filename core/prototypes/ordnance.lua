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
Ordnance.ROCKET_TINT = { r = 0.8, g = 0.55, b = 0.4, a = 1 }

-- The fields of the vanilla artillery projectile that a larva rocket
-- copies: how it looks in flight and on the map.
local PROJECTILE_LOOKS =
  { "picture", "shadow", "chart_picture", "map_color", "height_from_ground", "rotatable" }

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

-- A larva rocket: the loaded larva as ammo for the larva launcher. It
-- still spoils into its loaded monster.
local function rocket(species, payload)
  local p = spoiling(
    Payloads.loaded_name(species, payload),
    loaded_icon(species, payload),
    Balance.loaded,
    Payloads.effect_id(species, payload)
  )
  p.type = "ammo"
  p.subgroup = "ammo"
  p.ammo_category = Names.AMMO
  p.ammo_type = {
    target_type = "position",
    action = {
      type = "direct",
      action_delivery = {
        type = "artillery",
        projectile = Payloads.projectile_name(species, payload),
        starting_speed = 1,
        direction_deviation = 0,
        range_deviation = 0,
      },
    },
  }
  return p
end

-- The projectile of a larva rocket. Where it lands it shows an
-- explosion and runs the landing effect. The script deals the blast
-- damage, because an area trigger with force "enemy" also hurts the
-- tamed force (probe, fact 6).
local function projectile(species, payload, looks)
  local p = Common.pick(looks, PROJECTILE_LOOKS)
  p.type = "artillery-projectile"
  p.hidden = true
  p.name = Payloads.projectile_name(species, payload)
  p.reveal_map = false
  p.map_color = p.map_color or { r = 1, g = 0.5, b = 0 }
  p.action = {
    type = "direct",
    action_delivery = {
      type = "instant",
      target_effects = {
        { type = "create-entity", entity_name = "grenade-explosion" },
        { type = "script", effect_id = Payloads.land_id(species, payload) },
      },
    },
  }
  return p
end

-- The shared casing that every larva rocket uses up, and its recipe.
local function casing()
  local c = Balance.casing
  local item = Common.item(
    Names.CASING,
    Common.icon("__base__/graphics/icons/rocket.png", Ordnance.ROCKET_TINT),
    "intermediate-product",
    c.stack
  )
  local recipe = Common.recipe(Names.CASING, { "crafting" }, c.time, {
    { type = "item", name = "steel-plate", amount = c.steel },
    { type = "item", name = "explosives", amount = c.explosives },
    { type = "item", name = "electronic-circuit", amount = c.circuit },
  }, { { type = "item", name = Names.CASING, amount = 1 } })
  return item, recipe
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

-- Larva rockets, their projectiles, the casing, the chamber, their
-- recipes and their technology. Returns the prototypes and the recipes.
local function loading(graphics, projectile_looks)
  local out = {
    { type = "recipe-category", name = Names.LOADING },
    { type = "ammo-category", name = Names.AMMO },
  }
  local casing_item, casing_recipe = casing()
  out[#out + 1] = casing_item
  local recipes = { casing_recipe }
  for _, species in ipairs(Species.ALL) do
    for _, payload in ipairs(Payloads.ALL) do
      out[#out + 1] = rocket(species, payload)
      out[#out + 1] = projectile(species, payload, projectile_looks)
      recipes[#recipes + 1] =
        fresh_recipe(Payloads.load_recipe(species, payload), Names.LOADING, Balance.load.time, {
          { type = "item", name = species.larva, amount = 1 },
          { type = "item", name = payload.item, amount = 1 },
          { type = "item", name = Names.CASING, amount = 1 },
        }, Payloads.loaded_name(species, payload))
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

-- A look-alike copies a vanilla effect. It shows the same picture and
-- deals no damage of its own: shell/damage.lua deals the damage. Each
-- returns nil when another mod removed the vanilla prototype.

-- True when every entity_name in a trigger names an entity that exists.
local function names_exist(trigger, entity_exists)
  if type(trigger) ~= "table" then
    return true
  end
  for key, value in pairs(trigger) do
    if key == "entity_name" and not entity_exists(value) then
      return false
    end
    if not names_exist(value, entity_exists) then
      return false
    end
  end
  return true
end

-- The poison cloud, for as long as its hazard lasts. It drops its
-- created_effect when another mod removed an entity that it names.
local function cloud(vanilla, entity_exists)
  if not vanilla then
    return nil
  end
  local p = Common.copy(vanilla)
  p.name = Names.CLOUD
  p.hidden = true
  p.action = nil
  p.action_cooldown = 0
  p.duration = Balance.payload_damage.poison.ticks
  if not names_exist(p.created_effect, entity_exists) then
    p.created_effect = nil
  end
  return p
end

-- An acid puddle that never spreads and never acts. It keeps the
-- vanilla damage type, and it is nil when another mod removed that
-- type. With a lifetime, it lasts exactly that long. Without one, it
-- keeps the vanilla lifetime.
local function puddle(vanilla, name, lifetime, damage_exists)
  local kind = vanilla and vanilla.damage_per_tick and vanilla.damage_per_tick.type
  if not (kind and damage_exists(kind)) then
    return nil
  end
  local p = Common.copy(vanilla)
  p.name = name
  p.hidden = true
  p.damage_per_tick = { amount = 0, type = kind }
  p.on_damage_tick_effect = nil
  p.created_effect = nil
  p.on_fuel_added_action = nil
  p.spawn_entity = nil
  p.maximum_spread_count = 0
  if lifetime then
    p.initial_lifetime = lifetime
    p.maximum_lifetime = lifetime
    p.lifetime_increase_by = 0
  end
  return p
end

-- The look-alikes, in name order, for data-final-fixes.lua. The opts
-- hold the vanilla poison cloud and big acid puddle as they stand then,
-- either of which can be nil. They also hold entity_exists(name) and
-- damage_exists(name), which read the data stage.
function Ordnance.lookalikes(opts)
  local out = {}
  out[#out + 1] =
    puddle(opts.pool, Names.POOL, Balance.payload_damage.acid.ticks, opts.damage_exists)
  out[#out + 1] = cloud(opts.cloud, opts.entity_exists)
  return out
end

-- Returns the prototypes, and the names of the recipes that Monster
-- husbandry unlocks. The opts hold the graphics_set and working_sound
-- to copy for the incubator and the chamber. They also hold the vanilla
-- artillery projectile, whose looks the larva rockets copy.
function Ordnance.prototypes(opts)
  local out = {}
  local incubation_protos, husbandry = incubation(opts.incubator)
  local loading_protos, loading_recipes = loading(opts.chamber, opts.projectile)
  for _, list in ipairs({
    incubation_protos,
    husbandry,
    loading_protos,
    loading_recipes,
  }) do
    Common.append(out, list)
  end
  return out, Common.names(husbandry)
end

return Ordnance
