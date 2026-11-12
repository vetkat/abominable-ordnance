-- In-game smoke tests. factorio-test runs them in the headless server,
-- once with the base game only and once with Space Age.

test("the mod is active", function()
  assert(script.active_mods["abominable-ordnance"], "abominable-ordnance is not active")
end)

test("the game is version 2.1", function()
  local version = script.active_mods["base"]
  assert(version:match("^2%.1%."), "base is " .. version)
end)
