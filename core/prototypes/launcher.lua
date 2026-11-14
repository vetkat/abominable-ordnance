-- Builds the larva launcher, its guns, the larva flare and remote, and
-- their research, as plain tables. data.lua passes the result to
-- data:extend. This module reads no game globals: only its parameters
-- and other core modules.
local Balance = require("core.balance")
local Common = require("core.prototypes.common")
local Launcher = require("core.launcher")
local Names = require("core.names")

local LauncherPrototypes = {}

LauncherPrototypes.TINT = { r = 0.8, g = 0.6, b = 0.45, a = 1 }

local PACKS = {
  "automation-science-pack",
  "logistic-science-pack",
  "military-science-pack",
  "chemical-science-pack",
}

-- The vanilla turret fields the launcher copies. The pictures get the
-- tint, the rest stays as it is.
local PICTURES = { "base_picture", "cannon_barrel_pictures", "cannon_base_pictures" }
local TURRET_LOOKS = {
  "base_picture_render_layer",
  "cannon_base_shift",
  "cannon_barrel_recoil_shiftings",
  "cannon_barrel_recoil_shiftings_load_correction_matrix",
  "cannon_barrel_light_direction",
  "cannon_parking_frame_count",
  "cannon_parking_speed",
  "rotating_sound",
  "turret_rotation_speed",
  "turn_after_shooting_cooldown",
  "collision_box",
  "selection_box",
  "drawing_box_vertical_extension",
  "corpse",
  "dying_explosion",
  "resistances",
  "water_reflection",
}
local FLARE_LOOKS = {
  "pictures",
  "shadows",
  "life_time",
  "map_color",
  "initial_height",
  "initial_vertical_speed",
  "initial_frame_speed",
  "shots_per_flare",
  "early_death_ticks",
  "render_layer",
  "render_layer_when_on_ground",
  "regular_trigger_effect",
  "regular_trigger_effect_frequency",
  "movement_modifier",
  "movement_modifier_when_on_ground",
  "creation_shift",
  "selection_priority",
  "flags",
}
local REMOTE_LOOKS = { "flags", "inventory_move_sound", "pick_sound", "drop_sound", "radius_color" }

local function icons(path)
  return Common.icon(path, LauncherPrototypes.TINT)
end

local LAUNCHER_ICON = "__base__/graphics/icons/artillery-turret.png"

-- The hidden gun of one level: its range and its fire rate.
local function gun(level)
  local b = Balance.launcher
  local p = Common.item(Launcher.gun(level), icons(LAUNCHER_ICON), "gun", 1)
  p.type = "gun"
  p.hidden = true
  p.attack_parameters = {
    type = "projectile",
    ammo_category = Names.AMMO,
    cooldown = b.cooldown,
    range = Launcher.range(level),
    min_range = b.min_range,
    projectile_creation_distance = 1.6,
  }
  return p
end

-- The turret of one level. Levels above 0 are hidden, and the launcher
-- item builds their ghosts. No level is a fast replace or an upgrade of
-- another: the script swaps them.
local function turret(level, looks)
  local b = Balance.launcher
  local p = Common.pick(looks, TURRET_LOOKS)
  for _, field in ipairs(PICTURES) do
    p[field] = Common.tinted(looks[field], LauncherPrototypes.TINT)
  end
  p.type = "artillery-turret"
  p.name = Launcher.name(level)
  p.icons = icons(LAUNCHER_ICON)
  p.flags = { "placeable-neutral", "placeable-player", "player-creation" }
  p.minable = { mining_time = b.mining_time, result = Names.LAUNCHER }
  p.max_health = b.max_health
  p.gun = Launcher.gun(level)
  p.inventory_size = 1
  p.ammo_stack_limit = b.ammo
  p.automated_ammo_count = b.ammo
  p.manual_range_modifier = b.manual_range_modifier
  if level > 0 then
    p.hidden = true
    p.placeable_by = { item = Names.LAUNCHER, count = 1 }
  end
  return p
end

local function launcher_kit()
  local b = Balance.launcher
  local r = b.recipe
  local item = Common.item(Names.LAUNCHER, icons(LAUNCHER_ICON), "defensive-structure", b.stack)
  item.place_result = Launcher.name(0)
  local recipe = Common.recipe(Names.LAUNCHER, { "crafting" }, r.time, {
    { type = "item", name = "steel-plate", amount = r.steel },
    { type = "item", name = "iron-gear-wheel", amount = r.gear },
    { type = "item", name = "advanced-circuit", amount = r.advanced },
    { type = "item", name = "pipe", amount = r.pipe },
  }, { { type = "item", name = Names.LAUNCHER, amount = 1 } })
  return item, recipe
end

-- The larva flare. It looks like the vanilla flare, and only larva
-- launchers fire at it.
local function flare(looks)
  local p = Common.pick(looks, FLARE_LOOKS)
  p.type = "artillery-flare"
  p.name = Names.FLARE
  p.icons = icons("__base__/graphics/icons/artillery-targeting-remote.png")
  p.shot_category = Names.AMMO
  return p
end

local function remote_kit(looks)
  local r = Balance.targeting_remote
  local item = Common.item(
    Names.REMOTE,
    icons("__base__/graphics/icons/artillery-targeting-remote.png"),
    "defensive-structure",
    1
  )
  for k, v in pairs(Common.pick(looks, REMOTE_LOOKS)) do
    item[k] = v
  end
  item.type = "capsule"
  item.capsule_action = { type = "artillery-remote", flare = Names.FLARE }
  local recipe = Common.recipe(Names.REMOTE, { "crafting" }, r.time, {
    { type = "item", name = "electronic-circuit", amount = r.circuit },
    { type = "item", name = "radar", amount = r.radar },
    { type = "item", name = "coal", amount = r.coal },
    { type = "item", name = "sulfur", amount = r.sulfur },
  }, { { type = "item", name = Names.REMOTE, amount = 1 } })
  return item, recipe
end

local function rockets_tech()
  return Common.technology({
    name = Names.ROCKETS_TECH,
    icons = icons(LAUNCHER_ICON),
    prerequisites = { Names.ORDNANCE_TECH, "rocketry" },
    count = Balance.rockets_research.count,
    time = Balance.rockets_research.time,
    packs = PACKS,
    unlocks = { Names.LAUNCHER, Names.REMOTE },
  })
end

-- One research of an upgrade chain. The first needs Larva rockets, each
-- later one the level before it. effects replaces the unlocks.
local function upgrade(prefix, level, effects)
  local u = Balance.upgrade_research
  local tech = Common.technology({
    name = prefix .. level,
    icons = icons(LAUNCHER_ICON),
    prerequisites = { level == 1 and Names.ROCKETS_TECH or prefix .. (level - 1) },
    count = u.counts[level],
    time = u.time,
    packs = PACKS,
    unlocks = {},
  })
  tech.effects = effects
  tech.upgrade = true
  return tech
end

-- Returns the prototypes. opts.turret, opts.flare and opts.remote are the
-- vanilla artillery turret, flare and remote. The launcher copies their
-- looks. opts.levels lists the launcher levels to build.
function LauncherPrototypes.prototypes(opts)
  local out = {}
  for _, level in ipairs(opts.levels) do
    out[#out + 1] = gun(level)
    out[#out + 1] = turret(level, opts.turret)
  end
  local item, recipe = launcher_kit()
  local kit, kit_recipe = remote_kit(opts.remote)
  Common.append(out, { item, recipe, flare(opts.flare), kit, kit_recipe, rockets_tech() })
  local speed = {
    { type = "gun-speed", ammo_category = Names.AMMO, modifier = Balance.upgrade_research.speed },
  }
  for level = 1, Balance.launcher.max_level do
    out[#out + 1] = upgrade(Names.SPEED_TECH, level, speed)
  end
  return out
end

return LauncherPrototypes
