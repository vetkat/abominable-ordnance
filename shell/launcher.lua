-- The launcher level and the swap. This module is shell: it reads and
-- writes the game. control.lua calls it, and so do the in-game tests.
local Launcher = require("core.launcher")

local LauncherShell = {}

-- The launcher has one ammo slot (core/prototypes/launcher.lua).
local AMMO = defines.inventory.artillery_turret_ammo

-- The control behaviour settings that a swap copies.
-- True while a swap runs. A swap that falls back to the old level
-- raises a built event for it, and on_built must not swap that launcher
-- again, or the swap would recurse. The flag is false outside a swap, so
-- it holds no state between events and cannot desync.
local swapping = false

local SETTINGS = {
  "circuit_enable_disable",
  "circuit_condition",
  "connect_to_logistic_network",
  "logistic_condition",
  "read_ammo",
}

---@param force LuaForce
function LauncherShell.level(force)
  return Launcher.level(function(name)
    local tech = force.technologies[name]
    return tech ~= nil and tech.researched
  end)
end

-- Everything the new launcher must keep. The record holds each wire as
-- its connector ID and the connector at the other end.
---@param old LuaEntity
local function read(old)
  local wires = {}
  for id, connector in pairs(old.get_wire_connectors(false)) do
    for _, connection in pairs(connector.connections) do
      wires[#wires + 1] = { id = id, target = connection.target }
    end
  end
  local behaviour
  local b = old.get_control_behavior()
  if b then
    ---@cast b LuaArtilleryTurretControlBehavior
    behaviour = {}
    for _, key in ipairs(SETTINGS) do
      behaviour[key] = b[key]
    end
  end
  return {
    name = old.name,
    surface = old.surface,
    position = old.position,
    direction = old.direction,
    force = old.force,
    quality = old.quality,
    health = old.health,
    auto = old.artillery_auto_targeting,
    last_user = old.last_user,
    wires = wires,
    behaviour = behaviour,
  }
end

local function create(state, name)
  return state.surface.create_entity({
    name = name,
    position = state.position,
    direction = state.direction,
    force = state.force,
    quality = state.quality,
    raise_built = true,
  })
end

-- Gives the new launcher the old one's state and the ammo from temp.
---@param new LuaEntity
---@param temp LuaInventory
local function restore(new, state, temp)
  new.health = state.health
  new.artillery_auto_targeting = state.auto
  if state.last_user then
    new.last_user = state.last_user
  end
  new.get_inventory(AMMO)[1].transfer_stack(temp[1])
  for _, wire in ipairs(state.wires) do
    if wire.target.valid then
      local connector = new.get_wire_connector(wire.id, true)
      if connector then
        connector.connect_to(wire.target, false)
      end
    end
  end
  if state.behaviour then
    local b = new.get_or_create_control_behavior()
    ---@cast b LuaArtilleryTurretControlBehavior
    for key, value in pairs(state.behaviour) do
      b[key] = value
    end
  end
end

-- Replaces a launcher with the prototype of another level. The ammo
-- waits in a script inventory, so its spoil timer keeps running. No
-- failure loses the launcher or its ammo (Launcher.after). Returns the
-- new launcher, or nil.
---@param old LuaEntity
---@param name string
function LauncherShell.swap(old, name)
  local state = read(old)
  local temp = game.create_inventory(1)
  local ammo = old.get_inventory(AMMO) --[[@as LuaInventory]]
  temp[1].transfer_stack(ammo[1])
  local new
  swapping = true
  local ok = old.destroy({ raise_destroy = true })
  local step = Launcher.after("destroy", ok)
  while step ~= "finish" and step ~= "stop" do
    if step == "create" then
      new = create(state, name)
    elseif step == "create_old" then
      new = create(state, state.name)
    elseif step == "give_back" then
      ammo[1].transfer_stack(temp[1])
    elseif step == "spill" then
      state.surface.spill_item_stack({
        position = state.position,
        stack = temp[1],
        force = state.force,
        allow_belts = false,
      })
      log("Abominable Ordnance: a larva launcher could not be rebuilt, its ammo lies on the ground")
    end
    step = Launcher.after(step, new ~= nil)
  end
  swapping = false
  if new then
    restore(new, state, temp)
  end
  temp.destroy()
  return new
end

-- Swaps every launcher of a force whose level differs from the force's
-- level. Runs once per research or force event, not every tick.
---@param force LuaForce
function LauncherShell.sync(force)
  local name = Launcher.name(LauncherShell.level(force))
  for _, surface in pairs(game.surfaces) do
    local launchers = surface.find_entities_filtered({ name = Launcher.NAMES, force = force })
    for _, entity in pairs(launchers) do
      if entity.valid and entity.name ~= name then
        LauncherShell.swap(entity, name)
      end
    end
  end
end

-- Swaps one newly built launcher to its force's level. A launcher that
-- already has the right level, such as the one a swap raises, stays.
-- So does a launcher that a swap builds.
---@param entity LuaEntity?
function LauncherShell.on_built(entity)
  if swapping or not (entity and entity.valid and Launcher.level_of(entity.name)) then
    return
  end
  local name = Launcher.name(LauncherShell.level(entity.force --[[@as LuaForce]]))
  if entity.name ~= name then
    LauncherShell.swap(entity, name)
  end
end

return LauncherShell
