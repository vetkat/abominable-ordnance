-- Builds the larva launcher, its guns, the larva flare and remote, and
-- their research, as plain tables. data.lua passes the result to
-- data:extend. This module reads no game globals: only its parameters
-- and other core modules.
local Balance = require("core.balance")
local Common = require("core.prototypes.common")
local Graphics = require("core.prototypes.graphics")
local Launcher = require("core.launcher")
local Names = require("core.names")

local LauncherPrototypes = {}

-- The tint of the remote and flare icons, which have no art of their own.
LauncherPrototypes.TINT = { r = 0.8, g = 0.6, b = 0.45, a = 1 }

local PACKS = {
  "automation-science-pack",
  "logistic-science-pack",
  "military-science-pack",
  "chemical-science-pack",
}

-- The vanilla turret fields the launcher copies. The launcher has its
-- own picture, which shows the base and the rocket pods in one sprite, so
-- it copies no base or barrel field.
local TURRET_LOOKS = {
  "cannon_base_shift",
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
  "circuit_connector",
  "circuit_wire_max_distance",
  "alert_when_attacking",
  "open_sound",
  "close_sound",
  "mined_sound",
  "damaged_trigger_effect",
}
-- The vanilla cannon's attack fields the hidden gun copies, so that a
-- shot sounds and looks like an artillery shot.
local CANNON_LOOKS = {
  "sound",
  "projectile_center",
  "projectile_creation_parameters",
  "projectile_creation_distance",
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
-- The remote has a recipe, so it does not copy the vanilla flags: an
-- only-in-cursor item would vanish when the cursor clears.
local REMOTE_LOOKS = { "inventory_move_sound", "pick_sound", "drop_sound", "radius_color" }

local function icons(path)
  return Common.icon(path, LauncherPrototypes.TINT)
end

local function launcher_icons()
  return Common.icon(Graphics.icon_path("larva-launcher.png"))
end

-- The hidden gun of one level: its range and its fire rate.
local function gun(level, cannon)
  local b = Balance.launcher
  local p = Common.item(Launcher.gun(level), launcher_icons(), "gun", 1)
  p.type = "gun"
  p.hidden = true
  local a = Common.pick(cannon, CANNON_LOOKS)
  a.type = "projectile"
  a.ammo_category = Names.AMMO
  a.cooldown = b.cooldown
  a.range = Launcher.range(level)
  a.min_range = b.min_range
  p.attack_parameters = a
  return p
end

-- The turret of one level. Levels above 0 are hidden, and the launcher
-- item builds their ghosts. No level is a fast replace or an upgrade of
-- another: the script swaps them.
local function turret(level, looks, space_age)
  local b = Balance.launcher
  local p = Common.pick(looks, TURRET_LOOKS)
  p.cannon_base_pictures = Graphics.launcher(Graphics.SIZE.launcher)
  p.type = "artillery-turret"
  p.name = Launcher.name(level)
  p.icons = launcher_icons()
  p.flags = { "placeable-neutral", "placeable-player", "player-creation" }
  p.minable = { mining_time = b.mining_time, result = Names.LAUNCHER }
  p.max_health = b.max_health
  p.gun = Launcher.gun(level)
  p.inventory_size = 1
  p.ammo_stack_limit = b.ammo
  p.automated_ammo_count = b.ammo
  p.manual_range_modifier = b.manual_range_modifier
  if space_age then
    -- Space Age gives the vanilla turret this in a later stage, so the
    -- copy would miss it.
    p.heating_energy = b.heating_energy
  end
  if level > 0 then
    p.hidden = true
    p.placeable_by = { item = Names.LAUNCHER, count = 1 }
  end
  return p
end

local function launcher_kit()
  local b = Balance.launcher
  local r = b.recipe
  local item = Common.item(Names.LAUNCHER, launcher_icons(), "defensive-structure", b.stack)
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
  p.hidden = true
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
  item.flags = { "not-stackable" }
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
    icons = Graphics.tech_icon("larva-rockets.png"),
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
    icons = launcher_icons(),
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

-- The ammo category to give the vanilla artillery flare, or nil to leave
-- it as it is. A flare without a category calls every artillery turret,
-- the larva launcher too. So the vanilla flare gets the artillery shell
-- category, unless another mod already set one. has_shell is true when
-- that category exists.
function LauncherPrototypes.vanilla_flare_category(vanilla, has_shell)
  if vanilla and has_shell and not vanilla.shot_category then
    return "artillery-shell"
  end
  return nil
end

-- Returns the prototypes. The launcher copies the looks of vanilla
-- artillery. These options hold the vanilla prototypes:
--   turret: the artillery turret.
--   flare: the artillery flare.
--   remote: the artillery targeting remote.
--   cannon: the attack of the artillery wagon cannon.
-- The option levels lists the launcher levels to build. The option
-- space_age is true when Space Age is active.
function LauncherPrototypes.prototypes(opts)
  local out = {}
  for _, level in ipairs(opts.levels) do
    out[#out + 1] = gun(level, opts.cannon)
    out[#out + 1] = turret(level, opts.turret, opts.space_age)
  end
  local item, recipe = launcher_kit()
  local kit, kit_recipe = remote_kit(opts.remote)
  Common.append(out, { item, recipe, flare(opts.flare), kit, kit_recipe, rockets_tech() })
  local speed = {
    { type = "gun-speed", ammo_category = Names.AMMO, modifier = Balance.upgrade_research.speed },
  }
  for level = 1, Balance.launcher.max_level do
    out[#out + 1] = upgrade(Names.SPEED_TECH, level, speed)
    -- Range techs have no effect in the game. shell/launcher.lua reads
    -- them and swaps the launchers to the matching level.
    out[#out + 1] = upgrade(Names.RANGE_TECH, level, {})
  end
  return out
end

return LauncherPrototypes
