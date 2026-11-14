-- Prototype helpers that more than one builder uses. This module reads no
-- game globals: only its parameters.
local Common = {}

-- Returns a copy of a graphics table. Every sprite that is not a shadow,
-- a light or a glow gets the tint.
function Common.tinted(value, tint)
  if type(value) ~= "table" then
    return value
  end
  local copy = {}
  for k, v in pairs(value) do
    copy[k] = Common.tinted(v, tint)
  end
  local sprite = copy.filename or copy.filenames or copy.stripes
  if sprite and not (copy.draw_as_shadow or copy.draw_as_light or copy.draw_as_glow) then
    copy.tint = tint
  end
  return copy
end

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

-- A 3x3 electric machine with no modules. spec has name, icons,
-- categories, graphics ({ graphics_set, working_sound }), tint and
-- numbers (crafting_speed, energy_usage, pollution, max_health,
-- mining_time).
function Common.machine(spec)
  local n = spec.numbers
  return {
    type = "assembling-machine",
    name = spec.name,
    icons = spec.icons,
    flags = { "placeable-neutral", "placeable-player", "player-creation" },
    minable = { mining_time = n.mining_time, result = spec.name },
    max_health = n.max_health,
    corpse = "medium-remnants",
    collision_box = { { -1.2, -1.2 }, { 1.2, 1.2 } },
    selection_box = { { -1.5, -1.5 }, { 1.5, 1.5 } },
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
    graphics_set = Common.tinted(spec.graphics.graphics_set, spec.tint),
    working_sound = spec.graphics.working_sound,
  }
end

-- The item that places a machine.
function Common.placeable(name, icons, stack)
  local p = Common.item(name, icons, "production-machine", stack)
  p.place_result = name
  return p
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

return Common
