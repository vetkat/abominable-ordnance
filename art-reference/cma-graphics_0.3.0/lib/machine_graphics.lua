-- CMA Graphics: turn the generated sprite tables into Factorio animations.
--
--   local MG = require("__cma-graphics__/lib/machine_graphics")
--   local G = MG("field-emitter", {variant = "mk2", direction = "north", animation_speed = 0.5})
--
-- opts.variant    tier of a family ("mk1", "mk2", ...), if the machine has variants
-- opts.direction  "north" / "east" / "south" / "west", if the machine was rendered per direction
-- opts.animation_speed (default 0.75), opts.scale (default 0.5 = native size; e.g. 0.5 * 2/3 to
--                 squeeze a 3x3 machine onto 2x2 - smaller stays crisp, larger goes soft)
--
-- G.working   layered Animation: base + additive emission (draw_as_glow) + shadow
-- G.idle      first frame + shadow, repeated to the same frame count (burner-generator & co. need it)
-- G.base, G.emission, G.shadow, G.idle_base   individual layers (e.g. for working_visualisations)
-- G.frozen    Space Age frozen_patch Sprite (nil if the machine has none)
-- G.tint      recipe-tint layer: greyscale tintable surfaces (nil if none) - working_visualisations
--             with apply_recipe_tint = "primary"
-- G.icon      64x64 icon path (G.icon_big: 512x512)
-- G.sets      every render-set tag the machine has (e.g. {"mk1-north", "mk1-east", ...})
--
-- Emission layers are rendered so the game can tint them where noted in the README (neutral white
-- glow => module tint / recipe tint via apply_tint / apply_recipe_tint).
local MOD = "__cma-graphics__/"

return function(name, opts)
  opts = opts or {}
  local all = require("__cma-graphics__/lib/sprites/" .. name)
  local parts = {}
  if opts.variant then parts[#parts + 1] = opts.variant end
  if opts.direction then parts[#parts + 1] = opts.direction end
  local tag = #parts > 0 and table.concat(parts, "-") or nil
  local S = (tag and all[tag]) or (not tag and all.main and all) or nil
  local sets = {}
  if not all.main then for k in pairs(all) do sets[#sets + 1] = k end table.sort(sets) end
  assert(S and S.main, "cma-graphics: no sprite set '" .. tostring(tag) .. "' for " .. name ..
                       (#sets > 0 and (" - available: " .. table.concat(sets, ", ")) or ""))
  local prefix = tag and (name .. "-" .. tag) or name
  local ent = MOD .. "graphics/entity/" .. name .. "/"
  local speed = opts.animation_speed or 0.75
  local scale = opts.scale or 0.5
  local k = scale / 0.5
  local n = S.main.frame_count

  local function shift(m) return {m.shift[1] * k, m.shift[2] * k} end
  local function sheet(file, m, extra)
    local l = {filename = ent .. file, width = m.width, height = m.height, shift = shift(m), scale = scale,
               frame_count = m.frame_count, line_length = m.line_length, animation_speed = speed}
    for key, v in pairs(extra or {}) do l[key] = v end
    return l
  end

  local G = {sets = sets}
  G.base = sheet(prefix .. "-hr-animation.png", S.main)
  G.emission = sheet(prefix .. "-hr-emission.png", S.emission, {draw_as_glow = true, blend_mode = "additive"})
  G.shadow = {filename = ent .. prefix .. "-hr-shadow.png", width = S.shadow.width, height = S.shadow.height,
              shift = shift(S.shadow), scale = scale, draw_as_shadow = true,
              frame_count = 1, repeat_count = n, animation_speed = speed}
  G.idle_base = {filename = ent .. prefix .. "-hr-idle.png", width = S.idle.width, height = S.idle.height,
                 shift = shift(S.idle), scale = scale, frame_count = 1, repeat_count = n, animation_speed = speed}
  if S.frozen then
    G.frozen = {filename = ent .. prefix .. "-hr-frozen.png", width = S.frozen.width, height = S.frozen.height,
                shift = shift(S.frozen), scale = scale}
  end
  if S.tint then           -- recipe-tint layer (greyscale; use with apply_recipe_tint)
    G.tint = sheet(prefix .. "-hr-tint.png", S.tint)
  end
  G.working = {layers = {G.base, G.emission, G.shadow}}
  G.idle = {layers = {G.idle_base, G.shadow}}
  local stem = MOD .. "graphics/icons/" .. name .. (opts.variant and ("-" .. opts.variant) or "")
  G.icon = stem .. ".png"
  G.icon_big = stem .. "-big.png"
  return G
end
