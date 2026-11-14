local M = {}
function M.draw(pos)
  rendering.draw_text({ text = "x", target = pos })
  return prototypes.entity["small-biter"], settings.startup
end
return M
