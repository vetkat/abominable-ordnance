-- Stub options for the prototype builders in the unit tests.
local Stubs = {}

local function graphics()
  return {
    graphics_set = {
      animation = {
        layers = {
          { filename = "body.png" },
          { filename = "shadow.png", draw_as_shadow = true },
        },
      },
    },
    working_sound = { sound = { filename = "hum.ogg" } },
  }
end

function Stubs.lifecycle_opts(space_age)
  return { space_age = space_age or false, pod = graphics() }
end

function Stubs.ordnance_opts()
  return {
    incubator = graphics(),
    chamber = graphics(),
    projectile = {
      picture = { filename = "shell.png" },
      shadow = { filename = "shell-shadow.png", draw_as_shadow = true },
      map_color = { r = 1, g = 1, b = 0 },
      height_from_ground = 1,
    },
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

return Stubs
