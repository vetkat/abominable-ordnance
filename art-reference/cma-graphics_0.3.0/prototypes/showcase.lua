-- Showcase plumbing: an inventory tab with free, always-enabled recipes so the machines can be
-- tried in-game right away. The entities are working examples of how to use the assets; balance
-- is not the point - copy what you need into your own mod.
data:extend({
  {type = "item-group", name = "cma-graphics", order = "z-cma",
   icon = "__cma-graphics__/graphics/icons/field-emitter-mk3-big.png", icon_size = 512},
})

local S = {}

function S.subgroup(name, order)
  data:extend({{type = "item-subgroup", name = "cma-" .. name, group = "cma-graphics", order = order}})
  return "cma-" .. name
end

-- item + free recipe for a showcase entity
function S.item(entity, icon, subgroup, order)
  data:extend({
    {type = "item", name = entity, icon = icon, icon_size = 64, subgroup = subgroup, order = order,
     place_result = entity, stack_size = 50},
    {type = "recipe", name = entity, enabled = true, energy_required = 0.5, ingredients = {},
     results = {{type = "item", name = entity, amount = 1}}},
  })
end

return S
