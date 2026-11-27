-- Stub options for the prototype builders in the unit tests.
local Stubs = {}

function Stubs.lifecycle_opts(space_age)
  return {
    space_age = space_age or false,
    pod_sound = { sound = { filename = "hum.ogg" } },
    corpse = "medium-remnants",
  }
end

function Stubs.ordnance_opts()
  return {
    incubator_sound = { sound = { filename = "hum.ogg" } },
    corpse = "medium-remnants",
    projectile = {
      picture = { filename = "shell.png" },
      shadow = { filename = "shell-shadow.png", draw_as_shadow = true },
      map_color = { r = 1, g = 1, b = 0 },
      height_from_ground = 1,
      action = { type = "direct", action_delivery = { type = "instant" } },
    },
  }
end

-- Stand-ins for the vanilla poison cloud and the big and small acid
-- puddles, which the look-alikes copy. Every entity and damage type exists.
function Stubs.lookalike_opts()
  return {
    cloud = {
      type = "smoke-with-trigger",
      name = "poison-cloud",
      animation = { filename = "cloud.png" },
      duration = 1200,
      action = { type = "direct" },
      action_cooldown = 30,
      created_effect = {
        {
          type = "cluster",
          action_delivery = {
            type = "instant",
            target_effects = {
              { type = "create-smoke", entity_name = "poison-cloud-visual-dummy" },
            },
          },
        },
      },
    },
    pool = {
      type = "fire",
      name = "acid-splash-fire-spitter-big",
      pictures = { { filename = "pool.png" } },
      damage_per_tick = { amount = 5, type = "acid" },
      on_damage_tick_effect = { type = "direct" },
      created_effect = { type = "direct" },
      on_fuel_added_action = { type = "direct" },
      spawn_entity = "fire-flame-on-tree",
      maximum_spread_count = 100,
      initial_lifetime = 1920,
      maximum_lifetime = 1920,
      lifetime_increase_by = 20,
    },
    puddle = {
      type = "fire",
      name = "acid-splash-fire-spitter-small",
      pictures = { { filename = "puddle.png" } },
      damage_per_tick = { amount = 1, type = "acid" },
      on_damage_tick_effect = { type = "direct" },
      created_effect = { type = "direct" },
      on_fuel_added_action = { type = "direct" },
      spawn_entity = "fire-flame-on-tree",
      maximum_spread_count = 100,
      initial_lifetime = 600,
      maximum_lifetime = 1800,
      lifetime_increase_by = 20,
    },
    entity_exists = function()
      return true
    end,
    damage_exists = function()
      return true
    end,
  }
end

-- Indexes prototypes by "type/name".
function Stubs.by_name(prototypes)
  local by_name = {}
  for _, p in ipairs(prototypes) do
    by_name[p.type .. "/" .. p.name] = p
  end
  return by_name
end

-- Stand-ins for the vanilla artillery turret, flare and remote.
function Stubs.launcher_opts(levels)
  return {
    levels = levels or { 0 },
    turret = {
      base_picture = { layers = { { filename = "base.png" } } },
      cannon_barrel_pictures = { layers = { { filename = "barrel.png" } } },
      cannon_base_pictures = { layers = { { filename = "cannon.png" } } },
      cannon_base_shift = { 0, 0, 0 },
      base_picture_render_layer = "lower-object",
      cannon_barrel_recoil_shiftings = { { x = 0, y = 0, z = 0 } },
      cannon_barrel_recoil_shiftings_load_correction_matrix = { { x = 0, y = 0, z = 0 } },
      cannon_barrel_light_direction = { 0, 0, 1 },
      turret_rotation_speed = 0.001,
      collision_box = { { -1.2, -1.2 }, { 1.2, 1.2 } },
      selection_box = { { -1.5, -1.5 }, { 1.5, 1.5 } },
      rotating_sound = { sound = { filename = "turn.ogg" } },
      circuit_connector = { points = { wire = { red = { 0, 1 } } } },
      circuit_wire_max_distance = 9,
      alert_when_attacking = false,
      open_sound = { filename = "open.ogg" },
      close_sound = { filename = "close.ogg" },
      mined_sound = { filename = "mined.ogg" },
      damaged_trigger_effect = { type = "create-entity", entity_name = "hit" },
    },
    cannon = {
      sound = { filename = "shoot.ogg", volume = 0.7 },
      projectile_center = { -0.15625, -0.07812 },
      projectile_creation_parameters = { { "direction", { 0, 1 } } },
      projectile_creation_distance = 1.6,
    },
    flare = {
      pictures = { { filename = "flare.png" } },
      life_time = 3600,
      map_color = { r = 1, g = 0.5, b = 0 },
      shots_per_flare = 1,
    },
    remote = {
      flags = { "only-in-cursor", "not-stackable", "spawnable", "always-show" },
      pick_sound = { filename = "pick.ogg" },
    },
  }
end

return Stubs
