-- Stub options for the prototype builders in the unit tests.
local Stubs = {}

local function graphics()
  return {
    graphics_set = { animation = { layers = { { filename = "body.png" } } } },
    working_sound = { sound = { filename = "hum.ogg" } },
  }
end

function Stubs.ordnance_opts()
  return { incubator = graphics(), chamber = graphics() }
end

return Stubs
