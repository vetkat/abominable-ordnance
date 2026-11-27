-- Builds every prototype of slice 2 as plain tables. data.lua passes the
-- result to data:extend. This module reads no game globals: only its
-- parameters and other core modules.
local Balance = require("core.balance")
local Common = require("core.prototypes.common")
local Graphics = require("core.prototypes.graphics")
local Names = require("core.names")
local Payloads = require("core.payloads")
local Species = require("core.species")

local Ordnance = {}

-- The fields of the vanilla artillery projectile that a larva rocket
-- copies: how it looks in flight and on the map.
local PROJECTILE_LOOKS =
  { "picture", "shadow", "chart_picture", "map_color", "height_from_ground", "rotatable" }

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

-- A larva rocket: the loaded larva as ammo for the larva launcher. It
-- still spoils into its loaded monster.
local function rocket(species, payload)
  local p = spoiling(
    Payloads.loaded_name(species, payload),
    Graphics.loaded_larva(species, payload),
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
    Common.icon(Graphics.icon_path("larva-rocket-base.png")),
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
    icons = Common.icon(Graphics.tech_path("ordnance-loading.png"), nil, 256),
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

-- Larvae, the incubator and their recipes. sound and corpse come from
-- vanilla prototypes, and either can be nil. Returns the prototypes and
-- the recipes.
local function incubation(sound, corpse)
  local out = { { type = "recipe-category", name = Names.INCUBATION } }
  local recipes = {}
  for _, species in ipairs(Species.ALL) do
    local icons = Common.icon(Graphics.icon_path("larva-" .. species.name .. ".png"))
    out[#out + 1] = spoiling(species.larva, icons, Balance.larva, species.effect_id)
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
    icon = Graphics.icon_path("incubator.png"),
    size = 4,
    corpse = corpse,
    categories = { Names.INCUBATION },
    graphics = { graphics_set = Graphics.machine("incubator", 4), working_sound = sound },
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

-- Larva rockets, their projectiles, the casing, the chamber with its
-- remnants, their recipes and their technology. Returns the prototypes
-- and the recipes.
local function loading(projectile_looks)
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
  local remnants = Graphics.remnants(4)
  local item, recipe, machine = Common.machine_kit({
    name = Names.CHAMBER,
    icon = Graphics.icon_path("loading-chamber.png"),
    size = 4,
    corpse = remnants.name,
    categories = { Names.LOADING },
    graphics = {
      graphics_set = Graphics.machine("loading-chamber", 4),
      working_sound = Graphics.chamber_sound(),
    },
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
  out[#out + 1] = remnants
  out[#out + 1] = ordnance_loading(recipes)
  return out, recipes
end

-- A look-alike copies a vanilla effect. It shows the same picture and
-- deals no damage of its own: shell/damage.lua deals the damage. Each
-- returns nil when another mod removed the vanilla prototype.

-- A trigger field holds one table or a list of them. Returns a list.
local function as_list(x)
  if x == nil then
    return {}
  end
  if x.type then
    return { x }
  end
  return x
end

-- The effects of the cloud's created_effect that only show something.
local LOOKS = { ["create-smoke"] = true, ["play-sound"] = true }

-- The effects of a list that only show something, or nil when a smoke
-- names a missing entity.
local function looks(effects, entity_exists)
  local out = {}
  for _, e in ipairs(as_list(effects)) do
    if LOOKS[e.type] then
      if e.type == "create-smoke" and not entity_exists(e.entity_name) then
        return nil
      end
      out[#out + 1] = e
    end
  end
  return out
end

-- The instant deliveries of a trigger, with only the effects that show
-- something. Returns nil when a smoke names a missing entity.
local function deliveries(trigger, entity_exists)
  local out = {}
  for _, d in ipairs(as_list(trigger.action_delivery)) do
    if d.type == "instant" then
      local target = looks(d.target_effects, entity_exists)
      local source = looks(d.source_effects, entity_exists)
      if not (target and source) then
        return nil
      end
      if #target + #source > 0 then
        out[#out + 1] = {
          type = "instant",
          target_effects = target[1] and target or nil,
          source_effects = source[1] and source or nil,
        }
      end
    end
  end
  return out
end

-- The cloud's created_effect with only its smoke and sound, or nil when
-- nothing is left or a smoke names a missing entity. Another mod can
-- add a damage effect to the vanilla cloud, and the look-alike deals no
-- damage of its own.
local function cloud_looks(created_effect, entity_exists)
  local out = {}
  for _, trigger in ipairs(as_list(created_effect)) do
    local kept = deliveries(trigger, entity_exists)
    if not kept then
      return nil
    end
    if #kept > 0 then
      local t = Common.copy(trigger)
      t.action_delivery = kept
      out[#out + 1] = t
    end
  end
  return out[1] and out or nil
end

-- The two look-alikes made from the vanilla poison cloud. The cloud
-- keeps the vanilla smoke and sound for as long as its hazard lasts. The
-- puff shows the aura for one second: a few particles, no extra smokes
-- and no sound.
local CLOUD_SHAPE = {
  name = Names.CLOUD,
  duration = Balance.payload_damage.poison.ticks,
  keep_looks = true,
}
local PUFF_SHAPE = {
  name = Names.PUFF,
  duration = 60,
  fields = {
    particle_count = 8,
    particle_spread = { 3, 1.8 },
    fade_away_duration = 30,
    spread_duration = 20,
  },
}

-- A look-alike of the vanilla cloud in a shape. It deals no damage. With
-- keep_looks, its created_effect keeps only the vanilla smoke and sound.
-- Without it, it has no created_effect.
local function cloud(vanilla, entity_exists, shape)
  if not vanilla then
    return nil
  end
  local p = Common.copy(vanilla)
  p.name = shape.name
  p.hidden = true
  p.action = nil
  p.action_cooldown = 0
  p.duration = shape.duration
  p.created_effect = shape.keep_looks and cloud_looks(vanilla.created_effect, entity_exists) or nil
  for key, value in pairs(shape.fields or {}) do
    p[key] = Common.copy(value)
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
-- hold the vanilla poison cloud and the big and small acid puddles as
-- they stand then. Any of them can be nil. The opts also hold
-- entity_exists(name) and damage_exists(name), which read the data
-- stage. The trail puddle keeps the vanilla lifetime.
function Ordnance.lookalikes(opts)
  local out = {}
  out[#out + 1] =
    puddle(opts.pool, Names.POOL, Balance.payload_damage.acid.ticks, opts.damage_exists)
  out[#out + 1] = puddle(opts.puddle, Names.PUDDLE, nil, opts.damage_exists)
  out[#out + 1] = cloud(opts.cloud, opts.entity_exists, CLOUD_SHAPE)
  out[#out + 1] = cloud(opts.cloud, opts.entity_exists, PUFF_SHAPE)
  return out
end

-- Returns the prototypes, and the names of the recipes that Monster
-- husbandry unlocks. The incubator's sound (opts.incubator_sound) and the
-- corpse (opts.corpse) come from vanilla prototypes. Either can be nil.
-- The larva rockets copy the looks of the vanilla artillery projectile
-- in opts.projectile.
function Ordnance.prototypes(opts)
  local out = {}
  local incubation_protos, husbandry = incubation(opts.incubator_sound, opts.corpse)
  local loading_protos, loading_recipes = loading(opts.projectile)
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
