-- In-game smoke tests. factorio-test runs them in the headless server,
-- once with the base game only and once with Space Age.

test("the mod is active", function()
  assert(script.active_mods["abominable-ordnance"], "abominable-ordnance is not active")
end)

test("the game is version 2.1", function()
  local version = script.active_mods["base"]
  assert(version:match("^2%.1%."), "base is " .. version)
end)

-- Each run leaves out the other run's tag (tools/ingame.sh), so these two
-- tests check that the run really has, or lacks, Space Age.
tags("base")
test("Space Age is off in the base run", function()
  assert(not script.active_mods["space-age"], "space-age is active")
end)

tags("space-age")
test("Space Age is on in the Space Age run", function()
  assert(script.active_mods["space-age"], "space-age is not active")
end)
