local Names = require("core.names")
local Tamed = require("shell.tamed")

test("the feral force is at war with the natives, players and the tamed force", function()
  local feral = game.forces[Names.FERAL]
  assert(feral, "no feral force")
  for _, name in ipairs({ "enemy", "player", Names.TAMED }) do
    assert(not feral.get_cease_fire(name), "the feral force spares " .. name)
    assert(not game.forces[name].get_cease_fire(feral), name .. " spares the feral force")
  end
end)

test("a second setup keeps the tamed and the feral force at war", function()
  Tamed.ensure()
  Tamed.ensure()
  local feral = game.forces[Names.FERAL]
  assert(not feral.get_cease_fire(Names.TAMED), "the feral force spares the tamed force")
  local tamed = game.forces[Names.TAMED]
  assert(not tamed.get_cease_fire(feral), "the tamed force spares the feral force")
end)

test("a force made later is at war with the feral force", function()
  local other = game.forces["ao-feral-test-force"] or game.create_force("ao-feral-test-force")
  after_ticks(1, function()
    local feral = game.forces[Names.FERAL]
    assert(not feral.get_cease_fire(other) and not other.get_cease_fire(feral), "no war")
  end)
end)

test("the force limit guard allows a force below 64 forces only", function()
  assert(Tamed.can_create(63), "63 forces should leave room")
  assert(not Tamed.can_create(64), "64 forces should be full")
end)
