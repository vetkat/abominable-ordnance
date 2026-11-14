-- The control stage. This file is the shell: it talks to the game and
-- calls the pure modules in core/. The mod has no features yet.

-- factorio-test runs the in-game tests. The hook does nothing unless the
-- factorio-test mod is active.
if script.active_mods["factorio-test"] then
  require("__factorio-test__/init")({
    "tests/ingame/smoke_test",
    "tests/ingame/content_test",
  })
end
