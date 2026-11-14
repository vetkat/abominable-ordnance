-- Every balance number of slice 1. All values are first guesses.
local MINUTE = 60 * 60

return {
  egg_spoil_ticks = 30 * MINUTE,
  egg_stack = 100,
  chow_stack = 100,
  hatch_ratio = 10,
  hatch_search_radius = 8,
  loot_min = 1,
  loot_max = 3,
  monster_chow = { time = 2, coal = 1, sulfur = 1, water = 20, result = 2 },
  spitter_chow = { time = 2, chow = 1, acid = 10, result = 1 },
  breed = { time = 15, chow = 5, result = 2 },
  adopt = { time = 5, chow = 1 },
  pod = {
    crafting_speed = 1,
    energy_usage = "150kW",
    pollution = 4,
    max_health = 350,
    mining_time = 0.2,
    stack = 10,
    recipe = { time = 5, iron = 10, steel = 5, pipe = 5, circuit = 5 },
  },
  research = { count = 150, time = 30 },
}
