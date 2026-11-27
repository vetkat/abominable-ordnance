-- Prototype helpers that more than one builder uses. This module reads no
-- game globals: only its parameters.
local Common = {}

-- A deep copy of a value. Plain values come back as they are.
function Common.copy(value)
  if type(value) ~= "table" then
    return value
  end
  local copy = {}
  for k, v in pairs(value) do
    copy[k] = Common.copy(v)
  end
  return copy
end

-- One 64 px icon layer. tint is optional.
function Common.icon(path, tint)
  return { { icon = path, icon_size = 64, tint = tint } }
end

function Common.item(name, icons, subgroup, stack)
  return {
    type = "item",
    name = name,
    icons = icons,
    subgroup = subgroup,
    order = "z[ao]-" .. name,
    stack_size = stack,
  }
end

function Common.recipe(name, categories, time, ingredients, results)
  return {
    type = "recipe",
    name = name,
    categories = categories,
    enabled = false,
    energy_required = time,
    ingredients = ingredients,
    results = results,
  }
end

-- Space Age's recycler must not turn monster items back into their
-- ingredients.
function Common.no_recycling(r)
  r.auto_recycle = false
  return r
end

-- A spoil result that runs a script effect once per per_trigger items.
function Common.spoil_trigger(effect_id, per_trigger)
  return {
    items_per_trigger = per_trigger,
    trigger = {
      type = "direct",
      action_delivery = {
        type = "instant",
        source_effects = { { type = "script", effect_id = effect_id } },
      },
    },
  }
end

-- An electric machine with no modules. spec has name, icons, categories,
-- graphics ({ graphics_set, working_sound }) and numbers. The numbers are
-- crafting_speed, energy_usage, pollution, max_health and mining_time.
-- size is the footprint in tiles (default 3), and corpse names the
-- remnants. Without a corpse, the machine leaves none. The machine uses
-- the graphics as given.
function Common.machine(spec)
  local n = spec.numbers
  local size = spec.size or 3
  local c, s = size / 2 - 0.3, size / 2
  return {
    type = "assembling-machine",
    name = spec.name,
    icons = spec.icons,
    flags = { "placeable-neutral", "placeable-player", "player-creation" },
    minable = { mining_time = n.mining_time, result = spec.name },
    max_health = n.max_health,
    corpse = spec.corpse,
    collision_box = { { -c, -c }, { c, c } },
    selection_box = { { -s, -s }, { s, s } },
    tile_width = size,
    tile_height = size,
    crafting_categories = spec.categories,
    crafting_speed = n.crafting_speed,
    energy_source = {
      type = "electric",
      usage_priority = "secondary-input",
      emissions_per_minute = { pollution = n.pollution },
    },
    energy_usage = n.energy_usage,
    module_slots = 0,
    allowed_effects = {},
    graphics_set = spec.graphics.graphics_set,
    working_sound = spec.graphics.working_sound,
  }
end

-- The item that places a machine.
function Common.placeable(name, icons, stack)
  local p = Common.item(name, icons, "production-machine", stack)
  p.place_result = name
  return p
end

-- A machine with its item and its recipe. The spec has the fields of
-- Common.machine, but its icon is one path. The ingredients feed the
-- machine's own recipe. The numbers also give the craft time
-- (recipe.time) and the item's stack size (stack).
function Common.machine_kit(spec)
  local n = spec.numbers
  local icons = Common.icon(spec.icon)
  local recipe = Common.recipe(
    spec.name,
    { "crafting" },
    n.recipe.time,
    spec.ingredients,
    { { type = "item", name = spec.name, amount = 1 } }
  )
  local machine = Common.machine({
    name = spec.name,
    icons = icons,
    categories = spec.categories,
    graphics = spec.graphics,
    size = spec.size,
    corpse = spec.corpse,
    numbers = n,
  })
  return Common.placeable(spec.name, icons, n.stack), recipe, machine
end

-- A technology that unlocks the named recipes. spec has name, icons,
-- prerequisites, count, time, packs (a list of science pack names) and
-- unlocks (a list of recipe names).
function Common.technology(spec)
  local effects = {}
  for _, name in ipairs(spec.unlocks) do
    effects[#effects + 1] = { type = "unlock-recipe", recipe = name }
  end
  local ingredients = {}
  for _, pack in ipairs(spec.packs) do
    ingredients[#ingredients + 1] = { pack, 1 }
  end
  return {
    type = "technology",
    name = spec.name,
    icons = spec.icons,
    prerequisites = spec.prerequisites,
    effects = effects,
    unit = { count = spec.count, time = spec.time, ingredients = ingredients },
  }
end

-- The names of a list of recipes.
function Common.names(recipes)
  local names = {}
  for i, r in ipairs(recipes) do
    names[i] = r.name
  end
  return names
end

-- A deep copy of the named fields of t. A field that t lacks stays out.
-- The copy shares no table with t, so the caller can change it freely.
function Common.pick(t, fields)
  local copy = {}
  for _, field in ipairs(fields) do
    copy[field] = Common.copy(t[field])
  end
  return copy
end

-- Adds every item of list to the end of out. It changes out, which the
-- caller made.
function Common.append(out, list)
  for _, p in ipairs(list) do
    out[#out + 1] = p
  end
end

return Common
