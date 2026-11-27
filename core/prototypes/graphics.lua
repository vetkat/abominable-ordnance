-- The art of design version 1: sheet values, looks, sounds and icon paths.
-- The values are for the size the artist drew each building at. The
-- builders fit them to the footprint with one factor, size / drawn. This
-- module reads no game globals: only its parameters.
local Names = require("core.names")

local Graphics = {}

local MOD = "__abominable-ordnance__/"
local ENTITY = MOD .. "graphics/entity/"

-- The footprint in tiles of each building. The prototypes and their art
-- both read it, so the two cannot drift apart.
Graphics.SIZE = { ["breeding-pod"] = 5, incubator = 4, ["loading-chamber"] = 4, launcher = 3 }

function Graphics.icon_path(file)
  return MOD .. "graphics/icons/" .. file
end

function Graphics.tech_path(file)
  return MOD .. "graphics/technology/" .. file
end

-- The icons of a technology: its 256 px art.
function Graphics.tech_icon(file)
  return { { icon = Graphics.tech_path(file), icon_size = 256 } }
end

-- A small icon in a corner of another icon. shift is { 8, 8 } for the
-- bottom right and { -8, -8 } for the top left.
function Graphics.badge(icon, shift)
  return { icon = icon, icon_size = 64, scale = 0.25, shift = shift }
end

-- One sheet at its drawn size. frames is the frame count, line the line
-- length, and shift is in tiles.
local function sheet(file, w, h, frames, line, speed, shift)
  return {
    file = file,
    w = w,
    h = h,
    frames = frames,
    line = line,
    speed = speed,
    shift = shift or { 0, 0 },
  }
end

local POD_SHIFT = { 0, -0.5 }
local INCUBATOR_SHIFT = { 2.5 / 64, 2.5 / 64 }

-- Each machine has a drawn size, the sheets of its animation (the second
-- is the shadow) and its working visualisations.
local MACHINES = {
  ["breeding-pod"] = {
    drawn = 7,
    sheet = sheet("breeding-pod/pathogen-lab-animation.png", 500, 500, 60, 8, 0.15, POD_SHIFT),
    shadow = sheet("breeding-pod/pathogen-lab-shadow.png", 800, 700, 1, 1, 0.15, POD_SHIFT),
    repeat_shadow = 60,
    visualisations = {
      {
        sheet = sheet("breeding-pod/pathogen-lab-emission.png", 500, 500, 60, 8, 0.15, POD_SHIFT),
        glow = true,
        additive = true,
        fadeout = true,
      },
    },
  },
  incubator = {
    drawn = 4,
    sheet = sheet("incubator/oxidizer-base.png", 275, 313, 60, 8, 0.3, INCUBATOR_SHIFT),
    shadow = sheet("incubator/oxidizer-shadow.png", 372, 280, 1, 1, 0.3, { 51 / 64, 31 / 64 }),
    repeat_shadow = 60,
    visualisations = {
      {
        sheet = sheet("incubator/oxidizer-emission.png", 280, 320, 60, 9, 0.3),
        glow = true,
        additive = true,
        fadeout = true,
      },
    },
  },
  ["loading-chamber"] = {
    drawn = 6,
    sheet = sheet("loading-chamber/simulation-chamber-base.png", 512, 512, 1, 1),
    shadow = sheet("loading-chamber/simulation-chamber-shadow.png", 512, 512, 1, 1),
    visualisations = {
      {
        sheet = sheet(
          "loading-chamber/simulation-chamber-screen-animation.png",
          64,
          64,
          255,
          32,
          1,
          { -2, -1.75 }
        ),
        glow = true,
      },
      { sheet = sheet("loading-chamber/simulation-chamber-layer4.png", 512, 512, 1, 1) },
      {
        sheet = sheet("loading-chamber/simulation-chamber-glow.png", 512, 512, 1, 1),
        glow = true,
        additive = true,
      },
    },
  },
}

-- An animation layer for sheet s, fitted by the factor k.
local function layer(s, k)
  return {
    filename = ENTITY .. s.file,
    width = s.w,
    height = s.h,
    frame_count = s.frames,
    line_length = s.line,
    animation_speed = s.speed,
    scale = 0.5 * k,
    shift = { s.shift[1] * k, s.shift[2] * k },
  }
end

-- The graphics_set of a machine at size tiles. An unknown name is a
-- mistake in the mod's own code, so it raises an error.
function Graphics.machine(name, size)
  local m = MACHINES[name]
  if not m then
    error("graphics: no machine named " .. tostring(name))
  end
  local k = size / m.drawn
  local shadow = layer(m.shadow, k)
  shadow.draw_as_shadow = true
  shadow.repeat_count = m.repeat_shadow
  local visualisations = {}
  for i, v in ipairs(m.visualisations) do
    local a = layer(v.sheet, k)
    a.draw_as_glow = v.glow
    a.blend_mode = v.additive and "additive" or nil
    visualisations[i] = { fadeout = v.fadeout, animation = a }
  end
  return {
    animation = { layers = { layer(m.sheet, k), shadow } },
    working_visualisations = visualisations,
  }
end

-- The launcher art is drawn for 4x4 at scale 0.3. Each of its 64 frames
-- shows the whole turret.
local LAUNCHER_DRAWN = 4
local LAUNCHER_SCALE = 0.3
local LAUNCHER_SHADOW_SHIFT = { 2, 0 }

local function turret_layer(file, k)
  return {
    filename = ENTITY .. "larva-launcher/" .. file,
    width = 512,
    height = 512,
    direction_count = 64,
    line_length = 8,
    scale = LAUNCHER_SCALE * k,
  }
end

-- The cannon_base_pictures of the launcher at size tiles.
function Graphics.launcher(size)
  local k = size / LAUNCHER_DRAWN
  local shadow = turret_layer("rocket-turret-attack-shadow.png", k)
  shadow.draw_as_shadow = true
  shadow.shift = { LAUNCHER_SHADOW_SHIFT[1] * k, LAUNCHER_SHADOW_SHIFT[2] * k }
  return { layers = { turret_layer("rocket-turret-attack.png", k), shadow } }
end

function Graphics.chamber_sound()
  local dir = MOD .. "sound/loading-chamber/"
  return {
    sound = { filename = dir .. "simulation-chamber-working.ogg", volume = 0.7 },
    idle_sound = { filename = dir .. "simulation-chamber-idle.ogg", volume = 0.7 },
  }
end

-- The loading chamber's remnants at size tiles. The fields follow the
-- vanilla big-remnants.
function Graphics.remnants(size)
  local s = size / 2
  return {
    type = "corpse",
    name = "ao-loading-chamber-remnants",
    localised_name = { "entity-name." .. Names.CHAMBER },
    icon = Graphics.icon_path("loading-chamber.png"),
    hidden_in_factoriopedia = true,
    flags = { "placeable-neutral", "not-on-map" },
    subgroup = "generic-remnants",
    order = "z-ao",
    selection_box = { { -s, -s }, { s, s } },
    tile_width = size,
    tile_height = size,
    selectable_in_game = false,
    time_before_removed = 60 * 60 * 15,
    expires = false,
    final_render_layer = "remnants",
    remove_on_tile_placement = false,
    animation = {
      {
        filename = ENTITY .. "loading-chamber/simulation-chamber-remnants.png",
        width = 512,
        height = 512,
        frame_count = 1,
        direction_count = 1,
        scale = 0.5 * size / MACHINES["loading-chamber"].drawn,
      },
    },
  }
end

-- The loaded larva: the rocket, its two bands and the larva in the
-- species' colour, and the payload badge in the bottom right corner.
function Graphics.loaded_larva(species, payload)
  local function icon(file, tint)
    return { icon = Graphics.icon_path(file), icon_size = 64, tint = tint }
  end
  return {
    icon("larva-rocket-base.png"),
    icon("larva-rocket-band-rear.png", species.tint),
    icon("larva-rocket-band-front.png", species.tint),
    icon("larva-rocket-larva.png", species.tint),
    Graphics.badge(payload.icon, { 8, 8 }),
  }
end

return Graphics
