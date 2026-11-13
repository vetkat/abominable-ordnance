# Slice 1 Lifecycle Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task-by-task. Steps
> use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A player gets biter and spitter eggs from nests and breeds them
in a breeding pod. When eggs spoil, every 10 eggs hatch one wild monster
of their species.

**Architecture:** Pure modules in `core/` make the game-rule decisions:
the species table, the numbers, the unit pick, the loot drop and the
prototype tables. `data.lua` and `control.lua` are thin shells that read
the game, call the core and write the result. The hatch uses native
spoilage with a `script` trigger effect.

**Tech Stack:** Lua 5.2, Factorio 2.1.24 (base and Space Age), busted and
luacov for unit tests, factorio-test 3.2.0 for in-game tests, luacheck,
Make.

**Spec:** `docs/superpowers/specs/2026-11-13-lifecycle-design.md`

## Global Constraints

- Target Factorio 2.1, with and without Space Age. `info.json` keeps
  `"factorio_version": "2.1"`.
- Every new prototype name starts with `ao-`.
- A module in `core/` never names `game`, `storage`, `script`, `defines`
  or `math.random`. `spec/architecture_spec.lua` checks these names.
  A module in `core/` also never reads the `data`, `mods` or `settings`
  globals. busted runs the builder without them, so a read fails its
  tests.
- Every balance number lives in `core/balance.lua`: spoil times, stack
  sizes, ratios, the loot range, recipe amounts and times, the pod's
  stats and the research cost. Tints, icon sizes and box sizes stay in
  the builder.
- "Both modes" means the base game alone, and the base game with Space
  Age. `make ingame` runs both.
- The mod copies no game files. The prototypes reference graphics and
  icons by `__base__/` or `__space-age__/` paths, with a tint.
- British English in prose and comments.
- Recipes in Factorio 2.1 use `categories = { ... }` (a list), not
  `category`.
- `make fast` must pass before every commit. `make check` must pass
  before every PR.

**Commit routine.** CLAUDE.md sets this order. Run each command as a Bash
call of its own:

1. Run `/ste80-humanizer` in British English on changed prose and
   comments.
2. Run `/simplify` on changed code, with the reviewer count that the task
   names.
3. `git add <the files>`, then `make stamp`, then
   `git commit -m "<message>"`. Never use `git commit -a`, and never put
   paths after `git commit`. End the message with
   `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

**PR routine.** Push the branch. Open a PR whose title is the
Conventional Commit given in the task. End the body with
`🤖 Generated with [Claude Code](https://claude.com/claude-code)`. Run
`gh pr merge --auto --squash`, so GitHub squash merges the PR when the
check `all-checks` passes. Wait for the merge, then run
`git switch main && git pull` before the next branch.

## Review Focus

1. Eggs that spoil on the ground, where nest loot lies, must hatch like
   eggs in a chest. Task 6 tests both places.
2. A spitter egg at evolution 0 must hatch a spitter, never a biter.
   Tasks 5 and 6 test it.
3. A spawner that dies with no killer force, for example by
   `entity.die()`, must drop nothing and raise no error. Task 8 tests it.
4. A typo in a unit name in the species table makes `create_entity` fail
   in a player's game. Task 6 checks that every unit name exists.
5. At evolution 1 and a random number just below 1, the pick must still
   return a unit. Task 5 tests it.

---

## Branches and PRs

| PR | Branch | Tasks | Title | `/simplify` reviewers |
| --- | --- | --- | --- | --- |
| 0 | `docs/lifecycle-spec` (exists) | 0 | `docs: add the slice 1 lifecycle spec and plan` | 1 |
| 1 | `feat/lifecycle-content` | 2, 3, 4 | `feat: add eggs, feeds and the breeding pod` | 4 |
| 2 | `feat/hatching` | 5, 6 | `feat: hatch spoiled eggs by evolution` | 2 |
| 3 | `feat/nest-loot` | 7, 8 | `feat: drop eggs from native spawners` | 2 |

Task 1 is a throwaway probe on its own branch. It runs after PR 0 and
before Task 2. Do the tasks in their number order.

---

### Task 0: Merge the spec and this plan

**Files:** none new. The branch `docs/lifecycle-spec` holds the spec, the
EGM reports and this plan.

- [ ] **Step 1: Commit the review edits**

The plan itself is already committed. If the branch holds uncommitted
edits, follow the commit routine with 1 reviewer (docs only). Message:
`docs: apply the Stage 9 review to the lifecycle plan`.

- [ ] **Step 2: Open and merge PR 0**

Follow the PR routine. Title: `docs: add the slice 1 lifecycle spec and
plan`. The PR changes no mod code, so the changelog rule does not apply.

---

### Task 1: Probe the spoil trigger (throwaway)

This task answers the spec's five probe questions. Its code is never
committed and never pushed.

**Files (throwaway, on branch `probe/spoil-trigger`):**

- Modify: `data.lua`
- Modify: `control.lua`
- Create: `tests/ingame/probe_test.lua`

- [ ] **Step 1: Make the throwaway branch**

```bash
git switch main && git pull && git switch -c probe/spoil-trigger
```

- [ ] **Step 2: Add a probe egg to `data.lua`**

Replace the whole file:

```lua
local trigger = {
  type = "direct",
  action_delivery = {
    type = "instant",
    source_effects = { { type = "script", effect_id = "ao-probe" } },
  },
}
data:extend({
  {
    type = "item",
    name = "ao-probe-egg",
    icon = "__base__/graphics/icons/small-biter.png",
    stack_size = 100,
    spoil_ticks = 60 * 60,
    spoil_to_trigger_result = { items_per_trigger = 10, trigger = trigger },
  },
})
```

Also add `"feature_flags": ["spoiling"]` to `info.json`.

- [ ] **Step 3: Record each trigger event in `control.lua`**

Put this above the factorio-test hook:

```lua
script.on_event(defines.events.on_script_trigger_effect, function(e)
  if e.effect_id ~= "ao-probe" then return end
  storage.probe = storage.probe or {}
  storage.probe[#storage.probe + 1] = {
    tick = e.tick,
    surface = e.surface_index,
    source_position = e.source_position,
    target_position = e.target_position,
    source_entity = e.source_entity and e.source_entity.name,
    target_entity = e.target_entity and e.target_entity.name,
  }
end)
```

- [ ] **Step 4: Write the probe tests**

Each test ends in `error(...)`, so factorio-test prints the finding in
its output. Create `tests/ingame/probe_test.lua`. Add the file to the
list in the factorio-test hook in `control.lua`:
`{ "tests/ingame/smoke_test", "tests/ingame/probe_test" }`.

```lua
local surface = function() return game.surfaces[1] end

local function spoil(stack)
  local ok = pcall(function() stack.spoil() end)
  if ok then return "spoil()" end
  stack.spoil_percent = 1
  return "spoil_percent = 1"
end

local function chest_with(name, count, x)
  local chest = surface().create_entity({
    name = "steel-chest", position = { x, 300 }, force = "player",
  })
  chest.insert({ name = name, count = count })
  return chest
end

local function report(label, extra)
  error(label .. ": " .. serpent.line({ events = storage.probe, extra = extra }))
end

before_each(function() storage.probe = {} end)

test("Q1 Q2 Q3: 10 eggs in a chest", function()
  local chest = chest_with("ao-probe-egg", 10, 300)
  local call = spoil(chest.get_inventory(defines.inventory.chest)[1])
  after_ticks(2, function() report("chest-10", { call = call }) end)
end)

test("Q3: 9 eggs in a chest", function()
  local chest = chest_with("ao-probe-egg", 9, 310)
  spoil(chest.get_inventory(defines.inventory.chest)[1])
  after_ticks(2, function() report("chest-9") end)
end)

test("Q1: 10 eggs on the ground", function()
  surface().spill_item_stack({
    position = { 320, 300 },
    stack = { name = "ao-probe-egg", count = 10 },
    drop_full_stack = true,
  })
  for _, item in pairs(surface().find_entities_filtered({
    name = "item-on-ground", area = { { 315, 295 }, { 325, 305 } },
  })) do
    spoil(item.stack)
  end
  after_ticks(2, function() report("ground-10") end)
end)

test("Q5: a full steel chest", function()
  local chest = chest_with("ao-probe-egg", 4800, 330)
  local inventory = chest.get_inventory(defines.inventory.chest)
  for i = 1, #inventory do spoil(inventory[i]) end
  after_ticks(2, function() report("chest-4800", { events = #storage.probe }) end)
end)

tags("space-age")
test("Q4: Space Age eggs", function()
  local a = chest_with("biter-egg", 25, 340)
  spoil(a.get_inventory(defines.inventory.chest)[1])
  local b = chest_with("pentapod-egg", 1, 360)
  spoil(b.get_inventory(defines.inventory.chest)[1])
  after_ticks(2, function()
    local area = { { 330, 290 }, { 370, 310 } }
    report("space-age", {
      big_biters = surface().count_entities_filtered({ area = area, name = "big-biter" }),
      wrigglers = surface().count_entities_filtered({
        area = area, name = "big-wriggler-pentapod-premature",
      }),
    })
  end)
end)
```

- [ ] **Step 5: Run the probe**

Run: `make ingame`
Expected: every probe test FAILS, and each failure message holds a
`serpent` dump. Copy the dumps and the Q5 test's time from the output.
The test time is not the frame time. It only shows if 4,800 eggs cause
a visible delay.

- [ ] **Step 6: Keep the answers, and act on them**

Save the answers in a scratch file outside the repository. Task 4,
Step 10 adds them to the spec as a section `### Probe results` under
`## Delivery`, with one line per question:

1. The event fields that are set, for a chest and for the ground.
2. The call that forces a spoil: `spoil()` or `spoil_percent = 1`.
3. What 9 eggs do: one event, or none.
4. Big biters from 25 `biter-egg` and wrigglers from 1 `pentapod-egg`.
5. The number of events and the test time (not frame time) for 4,800
   eggs.

Then act on each answer:

| Probe answer | Action |
| --- | --- |
| No position field for eggs in a chest, or none for eggs on the ground | Finish PR 1. Tell the maintainer, and stop before PR 2. |
| The full stack of 10 on the ground gives one event | The ground test in Task 6 expects 1 monster. |
| A stack of 9 gives no event | Loot eggs (1 to 3) never hatch. Tell the maintainer: this is the open question on loot eggs in the spec. Keeping it needs no plan change. A random hatch per egg means stopping to re-plan. |
| A stack of 9 gives one event | Each loot pile hatches one monster. Tell the maintainer, for the same open question. |
| Only one of `source_position` and `target_position` is set | In Task 6, Step 3, read only that field. |
| `spoil()` fails and `spoil_percent = 1` works | In `tests/ingame/helpers.lua` (Task 4, Step 6), use the second body of `Helpers.spoil`. |

- [ ] **Step 7: Delete the throwaway branch**

```bash
git restore . && git clean -fd tests/ingame && git switch main && git branch -D probe/spoil-trigger
```

---

### Task 2: Names, numbers and the species table

**Files:**

- Create: `core/names.lua`
- Create: `core/balance.lua`
- Create: `core/species.lua`
- Create: `spec/core/species_spec.lua`
- Delete: `core/.gitkeep`

**Interfaces:**

- Produces:
   - `Names` (table of strings): `TECH`, `POD`, `CATEGORY`,
     `MONSTER_CHOW`, `SPITTER_CHOW`, `ADOPT`.
   - `Balance` (table of numbers), fields as in Step 3.
   - `Species.ALL`: list of species records, biter first. A record has
     `name`, `egg`, `feed`, `spawner`, `effect_id`, `units`. `units` is a
     list of `{ unit_name, { {evolution, weight}, ... } }`.
   - `Species.by_effect_id(id)` returns a record or nil.
   - `Species.by_spawner(name)` returns a record or nil.

- [ ] **Step 1: Make the branch**

```bash
git switch main && git pull && git switch -c feat/lifecycle-content
```

- [ ] **Step 2: Write the failing test**

Create `spec/core/species_spec.lua`:

```lua
local Species = require("core.species")

describe("the species table", function()
  it("lists the biter first, then the spitter", function()
    assert.are.equal("biter", Species.ALL[1].name)
    assert.are.equal("spitter", Species.ALL[2].name)
  end)

  it("gives each species its own egg, feed, spawner and effect", function()
    local biter, spitter = Species.ALL[1], Species.ALL[2]
    assert.are.equal("ao-biter-egg", biter.egg)
    assert.are.equal("ao-monster-chow", biter.feed)
    assert.are.equal("biter-spawner", biter.spawner)
    assert.are.equal("ao-hatch-biter", biter.effect_id)
    assert.are.equal("ao-spitter-egg", spitter.egg)
    assert.are.equal("ao-spitter-chow", spitter.feed)
    assert.are.equal("spitter-spawner", spitter.spawner)
    assert.are.equal("ao-hatch-spitter", spitter.effect_id)
  end)

  it("lists only the species' own units", function()
    for _, species in ipairs(Species.ALL) do
      for _, unit in ipairs(species.units) do
        assert.truthy(unit[1]:find(species.name, 1, true), unit[1])
      end
    end
  end)

  it("finds a species by effect ID and by spawner", function()
    assert.are.equal("spitter", Species.by_effect_id("ao-hatch-spitter").name)
    assert.are.equal("biter", Species.by_spawner("biter-spawner").name)
    assert.is_nil(Species.by_effect_id("ao-probe"))
    assert.is_nil(Species.by_spawner("gleba-spawner"))
  end)
end)
```

- [ ] **Step 3: Run the test to see it fail**

Run: `make lua`
Expected: FAIL with `module 'core.species' not found`.

- [ ] **Step 4: Write the three modules**

`core/names.lua`:

```lua
-- Prototype names that more than one module uses.
return {
  TECH = "ao-monster-husbandry",
  POD = "ao-breeding-pod",
  CATEGORY = "ao-breeding",
  MONSTER_CHOW = "ao-monster-chow",
  SPITTER_CHOW = "ao-spitter-chow",
  ADOPT = "ao-adopt-biter-egg",
}
```

`core/balance.lua`:

```lua
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
```

`core/species.lua`:

```lua
-- The two species of slice 1. The units and evolution points are each
-- species' own units from the vanilla spawners in Factorio 2.1.24.
local Names = require("core.names")

local Species = {}

Species.ALL = {
  {
    name = "biter",
    egg = "ao-biter-egg",
    feed = Names.MONSTER_CHOW,
    spawner = "biter-spawner",
    effect_id = "ao-hatch-biter",
    units = {
      { "small-biter", { { 0.0, 0.3 }, { 0.6, 0.0 } } },
      { "medium-biter", { { 0.2, 0.0 }, { 0.6, 0.3 }, { 0.7, 0.1 } } },
      { "big-biter", { { 0.5, 0.0 }, { 1.0, 0.4 } } },
      { "behemoth-biter", { { 0.9, 0.0 }, { 1.0, 0.3 } } },
    },
  },
  {
    name = "spitter",
    egg = "ao-spitter-egg",
    feed = Names.SPITTER_CHOW,
    spawner = "spitter-spawner",
    effect_id = "ao-hatch-spitter",
    units = {
      { "small-spitter", { { 0.25, 0.0 }, { 0.5, 0.3 }, { 0.7, 0.0 } } },
      { "medium-spitter", { { 0.4, 0.0 }, { 0.7, 0.3 }, { 0.9, 0.1 } } },
      { "big-spitter", { { 0.5, 0.0 }, { 1.0, 0.4 } } },
      { "behemoth-spitter", { { 0.9, 0.0 }, { 1.0, 0.3 } } },
    },
  },
}

local function find(field, value)
  for _, species in ipairs(Species.ALL) do
    if species[field] == value then return species end
  end
  return nil
end

function Species.by_effect_id(id) return find("effect_id", id) end

function Species.by_spawner(name) return find("spawner", name) end

return Species
```

Delete `core/.gitkeep`: `git rm core/.gitkeep`.

- [ ] **Step 5: Run the test to see it pass**

Run: `make lua`
Expected: PASS. luacheck reports 0 warnings.

No commit yet. Tasks 2, 3 and 4 form PR 1, with one commit at the end
of Task 4, because PR 1 is one squash-merged change.

---

### Task 3: The prototype builder

**Files:**

- Create: `core/prototypes/lifecycle.lua`
- Create: `spec/core/prototypes/lifecycle_spec.lua`

**Interfaces:**

- Consumes: `Names`, `Balance`, `Species.ALL` (Task 2).
- Produces: `Lifecycle.prototypes(opts)` returns a list of prototype
  tables. `opts.space_age` is a boolean. `opts.graphics_set` and
  `opts.working_sound` are the source machine's tables. The function does
  not change `opts`. `Lifecycle.POD_TINT` is the pod's tint.

- [ ] **Step 1: Write the failing test**

Create `spec/core/prototypes/lifecycle_spec.lua`:

```lua
local Lifecycle = require("core.prototypes.lifecycle")

local function stub()
  return {
    space_age = false,
    graphics_set = { animation = { layers = {
      { filename = "body.png" },
      { filename = "shadow.png", draw_as_shadow = true },
    } } },
    working_sound = { sound = { filename = "hum.ogg" } },
  }
end

local function build(space_age)
  local opts = stub()
  opts.space_age = space_age
  local by_name = {}
  for _, p in ipairs(Lifecycle.prototypes(opts)) do
    by_name[p.type .. "/" .. p.name] = p
  end
  return by_name
end

describe("the lifecycle prototypes", function()
  it("make the adopt recipe only with Space Age", function()
    assert.is_nil(build(false)["recipe/ao-adopt-biter-egg"])
    assert.truthy(build(true)["recipe/ao-adopt-biter-egg"])
  end)

  it("tint the pod's own copy of the graphics, but not shadows", function()
    local opts = stub()
    local pod
    for _, p in ipairs(Lifecycle.prototypes(opts)) do
      if p.type == "assembling-machine" then pod = p end
    end
    local layers = pod.graphics_set.animation.layers
    assert.are.same(Lifecycle.POD_TINT, layers[1].tint)
    assert.is_nil(layers[2].tint)
    assert.is_nil(opts.graphics_set.animation.layers[1].tint)
    assert.are.same(opts.working_sound, pod.working_sound)
  end)

  it("give the pod no module or beacon effects", function()
    local pod = build(false)["assembling-machine/ao-breeding-pod"]
    assert.are.equal(0, pod.module_slots)
    assert.are.same({}, pod.allowed_effects)
  end)

  it("give the breeding recipes the flags of pentapod-egg", function()
    for _, name in ipairs({ "ao-breed-biter", "ao-breed-spitter" }) do
      local recipe = build(false)["recipe/" .. name]
      assert.are.equal(1, recipe.ingredients[1].ignored_by_stats)
      local result = recipe.results[1]
      assert.are.equal(1, result.ignored_by_stats)
      assert.are.equal(1, result.ignored_by_productivity)
      assert.is_true(result.reset_freshness_on_craft)
      assert.is_false(recipe.auto_recycle)
    end
    assert.is_false(build(true)["recipe/ao-adopt-biter-egg"].auto_recycle)
  end)

  it("need military and chemical science first", function()
    assert.are.same({ "military-science-pack", "chemical-science-pack" },
      build(false)["technology/ao-monster-husbandry"].prerequisites)
  end)

  it("hatch one monster per 10 eggs through a script trigger", function()
    local egg = build(false)["item/ao-spitter-egg"]
    local result = egg.spoil_to_trigger_result
    assert.are.equal(10, result.items_per_trigger)
    local effect = result.trigger.action_delivery.source_effects[1]
    assert.are.same({ type = "script", effect_id = "ao-hatch-spitter" }, effect)
  end)

  it("use only known items and fluids", function()
    for _, space_age in ipairs({ false, true }) do
      local all = build(space_age)
      local known = {
        ["biter-egg"] = true, coal = true, sulfur = true, water = true,
        ["sulfuric-acid"] = true, ["iron-plate"] = true, ["steel-plate"] = true,
        pipe = true, ["electronic-circuit"] = true,
      }
      for key in pairs(all) do
        local name = key:match("^item/(.+)$")
        if name then known[name] = true end
      end
      for key, p in pairs(all) do
        if key:match("^recipe/") then
          for _, list in ipairs({ p.ingredients, p.results }) do
            for _, entry in ipairs(list) do
              assert.truthy(known[entry.name], key .. " uses " .. entry.name)
            end
          end
        end
      end
    end
  end)

  it("unlock every recipe through Monster husbandry", function()
    local all = build(true)
    local unlocked = {}
    for _, effect in ipairs(all["technology/ao-monster-husbandry"].effects) do
      unlocked[effect.recipe] = true
    end
    for key, p in pairs(all) do
      if key:match("^recipe/") then
        assert.is_false(p.enabled, p.name)
        assert.truthy(unlocked[p.name], p.name)
      end
    end
  end)
end)
```

- [ ] **Step 2: Run the test to see it fail**

Run: `make lua`
Expected: FAIL with `module 'core.prototypes.lifecycle' not found`.

- [ ] **Step 3: Write the builder**

Create `core/prototypes/lifecycle.lua`:

```lua
-- Builds every prototype of slice 1 as plain tables. data.lua passes the
-- result to data:extend. This module reads only its parameters.
local Balance = require("core.balance")
local Names = require("core.names")
local Species = require("core.species")

local Lifecycle = {}

Lifecycle.POD_TINT = { r = 0.85, g = 0.55, b = 0.75, a = 1 }
local EGG_TINT = {
  biter = { r = 0.9, g = 0.75, b = 0.5, a = 1 },
  spitter = { r = 0.6, g = 0.9, b = 0.5, a = 1 },
}
local CHOW_TINT = {
  [Names.MONSTER_CHOW] = { r = 0.8, g = 0.4, b = 0.3, a = 1 },
  [Names.SPITTER_CHOW] = { r = 0.6, g = 0.9, b = 0.3, a = 1 },
}

-- Returns a copy of a graphics table. Every sprite that is not a shadow,
-- a light or a glow gets the tint.
local function tinted(value, tint)
  if type(value) ~= "table" then return value end
  local copy = {}
  for k, v in pairs(value) do copy[k] = tinted(v, tint) end
  local sprite = copy.filename or copy.filenames or copy.stripes
  if sprite and not (copy.draw_as_shadow or copy.draw_as_light or copy.draw_as_glow) then
    copy.tint = tint
  end
  return copy
end

local function icon(path, tint)
  return { { icon = path, icon_size = 64, tint = tint } }
end

local function item(name, path, tint, subgroup, stack)
  return {
    type = "item", name = name, icons = icon(path, tint),
    subgroup = subgroup, order = "z[ao]-" .. name, stack_size = stack,
  }
end

local function hatch_trigger(effect_id)
  return {
    items_per_trigger = Balance.hatch_ratio,
    trigger = {
      type = "direct",
      action_delivery = {
        type = "instant",
        source_effects = { { type = "script", effect_id = effect_id } },
      },
    },
  }
end

local function egg(species)
  local p = item(species.egg, "__base__/graphics/icons/small-" .. species.name .. ".png",
    EGG_TINT[species.name], "intermediate-product", Balance.egg_stack)
  p.spoil_ticks = Balance.egg_spoil_ticks
  p.spoil_to_trigger_result = hatch_trigger(species.effect_id)
  return p
end

local function recipe(name, categories, time, ingredients, results)
  return {
    type = "recipe", name = name, categories = categories, enabled = false,
    energy_required = time, ingredients = ingredients, results = results,
  }
end

-- Space Age's recycler must not turn eggs back into their ingredients.
local function no_recycling(r)
  r.auto_recycle = false
  return r
end

local function breed(species)
  local b = Balance.breed
  return no_recycling(recipe("ao-breed-" .. species.name, { Names.CATEGORY }, b.time, {
    { type = "item", name = species.egg, amount = 1, ignored_by_stats = 1 },
    { type = "item", name = species.feed, amount = b.chow },
  }, {
    { type = "item", name = species.egg, amount = b.result, ignored_by_stats = 1,
      ignored_by_productivity = 1, reset_freshness_on_craft = true },
  }))
end

local function feed_recipes()
  local m, s = Balance.monster_chow, Balance.spitter_chow
  return {
    recipe(Names.MONSTER_CHOW, { "chemistry" }, m.time, {
      { type = "item", name = "coal", amount = m.coal },
      { type = "item", name = "sulfur", amount = m.sulfur },
      { type = "fluid", name = "water", amount = m.water },
    }, { { type = "item", name = Names.MONSTER_CHOW, amount = m.result } }),
    recipe(Names.SPITTER_CHOW, { "chemistry" }, s.time, {
      { type = "item", name = Names.MONSTER_CHOW, amount = s.chow },
      { type = "fluid", name = "sulfuric-acid", amount = s.acid },
    }, { { type = "item", name = Names.SPITTER_CHOW, amount = s.result } }),
  }
end

local function pod(opts)
  local b = Balance.pod
  return {
    type = "assembling-machine", name = Names.POD,
    icons = icon("__base__/graphics/icons/chemical-plant.png", Lifecycle.POD_TINT),
    flags = { "placeable-neutral", "placeable-player", "player-creation" },
    minable = { mining_time = b.mining_time, result = Names.POD },
    max_health = b.max_health,
    corpse = "medium-remnants",
    collision_box = { { -1.2, -1.2 }, { 1.2, 1.2 } },
    selection_box = { { -1.5, -1.5 }, { 1.5, 1.5 } },
    crafting_categories = { Names.CATEGORY },
    crafting_speed = b.crafting_speed,
    energy_source = {
      type = "electric", usage_priority = "secondary-input",
      emissions_per_minute = { pollution = b.pollution },
    },
    energy_usage = b.energy_usage,
    module_slots = 0,
    allowed_effects = {},
    graphics_set = tinted(opts.graphics_set, Lifecycle.POD_TINT),
    working_sound = opts.working_sound,
  }
end

local function pod_item_and_recipe()
  local r = Balance.pod.recipe
  local pod_item = item(Names.POD, "__base__/graphics/icons/chemical-plant.png",
    Lifecycle.POD_TINT, "production-machine", Balance.pod.stack)
  pod_item.place_result = Names.POD
  return pod_item, recipe(Names.POD, { "crafting" }, r.time, {
    { type = "item", name = "iron-plate", amount = r.iron },
    { type = "item", name = "steel-plate", amount = r.steel },
    { type = "item", name = "pipe", amount = r.pipe },
    { type = "item", name = "electronic-circuit", amount = r.circuit },
  }, { { type = "item", name = Names.POD, amount = 1 } })
end

local function adopt()
  return no_recycling(recipe(Names.ADOPT, { Names.CATEGORY }, Balance.adopt.time, {
    { type = "item", name = "biter-egg", amount = 1 },
    { type = "item", name = Names.MONSTER_CHOW, amount = Balance.adopt.chow },
  }, { { type = "item", name = Species.ALL[1].egg, amount = 1 } }))
end

local function technology(recipes)
  local effects = {}
  for _, r in ipairs(recipes) do
    effects[#effects + 1] = { type = "unlock-recipe", recipe = r.name }
  end
  return {
    type = "technology", name = Names.TECH,
    icons = icon("__base__/graphics/icons/small-biter.png", Lifecycle.POD_TINT),
    prerequisites = { "military-science-pack", "chemical-science-pack" },
    effects = effects,
    unit = {
      count = Balance.research.count, time = Balance.research.time,
      ingredients = {
        { "automation-science-pack", 1 }, { "logistic-science-pack", 1 },
        { "military-science-pack", 1 }, { "chemical-science-pack", 1 },
      },
    },
  }
end

function Lifecycle.prototypes(opts)
  local out = { { type = "recipe-category", name = Names.CATEGORY } }
  local recipes = feed_recipes()
  out[#out + 1] = item(Names.MONSTER_CHOW, "__base__/graphics/icons/coal.png",
    CHOW_TINT[Names.MONSTER_CHOW], "intermediate-product", Balance.chow_stack)
  out[#out + 1] = item(Names.SPITTER_CHOW, "__base__/graphics/icons/coal.png",
    CHOW_TINT[Names.SPITTER_CHOW], "intermediate-product", Balance.chow_stack)
  for _, species in ipairs(Species.ALL) do
    out[#out + 1] = egg(species)
    recipes[#recipes + 1] = breed(species)
  end
  local pod_item, pod_recipe = pod_item_and_recipe()
  out[#out + 1] = pod_item
  out[#out + 1] = pod(opts)
  recipes[#recipes + 1] = pod_recipe
  if opts.space_age then recipes[#recipes + 1] = adopt() end
  for _, r in ipairs(recipes) do out[#out + 1] = r end
  out[#out + 1] = technology(recipes)
  return out
end

return Lifecycle
```

- [ ] **Step 4: Run the test to see it pass**

Run: `make lua`
Expected: PASS, and coverage of `core/` at or above 90%.

---

### Task 4: The data-stage shell, locale and in-game content tests (PR 1)

**Files:**

- Modify: `data.lua`
- Modify: `info.json`
- Modify: `locale/en/locale.cfg`
- Modify: `control.lua` (test list only)
- Modify: `spec/locale_spec.lua`
- Modify: `.ste-allow`
- Create: `tests/ingame/helpers.lua`
- Create: `tests/ingame/content_test.lua`
- Modify: `docs/design.md`, `ROADMAP.md`, `CHANGELOG.md`,
  `docs/superpowers/specs/2026-11-13-lifecycle-design.md` (probe results
  from Task 1)

**Interfaces:**

- Consumes: `Lifecycle.prototypes` (Task 3).
- Produces: `tests/ingame/helpers.lua` with `Helpers.spoil(stack)`,
  `Helpers.arena(surface, position)`,
  `Helpers.powered_pod(surface, position)` and
  `Helpers.count_units(surface, position, names)`. Tasks 6 and 8 use it.

- [ ] **Step 1: Write the failing locale test**

In `spec/locale_spec.lua`, add at the top, below the `require` of
`spec.support.locale`:

```lua
local Lifecycle = require("core.prototypes.lifecycle")

local SECTION = {
  item = "item-name",
  recipe = "recipe-name",
  technology = "technology-name",
  ["assembling-machine"] = "entity-name",
}
```

Add this test inside the existing block that reads
`locale/en/locale.cfg` (use that block's `read` helper):

```lua
  it("names every prototype of slice 1", function()
    local text = read("locale/en/locale.cfg")
    local opts = { space_age = true, graphics_set = {}, working_sound = {} }
    for _, p in ipairs(Lifecycle.prototypes(opts)) do
      local section = SECTION[p.type]
      if section then
        assert.truthy(L.value(text, section, p.name), section .. "." .. p.name)
      end
    end
  end)
```

- [ ] **Step 2: Run it to see it fail**

Run: `make lua`
Expected: FAIL with `item-name.ao-monster-chow`.

- [ ] **Step 3: Add the locale entries**

Append to `locale/en/locale.cfg`:

```ini
[item-name]
ao-biter-egg=Biter egg (domesticated)
ao-spitter-egg=Spitter egg (domesticated)
ao-monster-chow=Monster chow
ao-spitter-chow=Spitter chow
ao-breeding-pod=Breeding pod

[entity-name]
ao-breeding-pod=Breeding pod

[recipe-name]
ao-monster-chow=Monster chow
ao-spitter-chow=Spitter chow
ao-breed-biter=Breed biters
ao-breed-spitter=Breed spitters
ao-adopt-biter-egg=Adopt a biter egg
ao-breeding-pod=Breeding pod

[technology-name]
ao-monster-husbandry=Monster husbandry

[technology-description]
ao-monster-husbandry=Breed biters and spitters from eggs. Native nests drop eggs when you destroy them.
```

Add this line to `.ste-allow`, below the `docs/design.md` entry, because
"Breeding pod" is a name:

```text
ing-form | locale/en/locale.cfg | breeding | the name of the breeding pod
```

- [ ] **Step 4: Run it to see it pass**

Run: `make fast`
Expected: PASS.

- [ ] **Step 5: Write the data-stage shell**

Replace `data.lua`:

```lua
-- The data stage. This file is the shell: it reads the game's data and
-- passes it to the pure builder in core/.
local Lifecycle = require("core.prototypes.lifecycle")

local source = mods["space-age"] and data.raw["assembling-machine"]["biochamber"]
  or data.raw["assembling-machine"]["chemical-plant"]

data:extend(Lifecycle.prototypes({
  space_age = mods["space-age"] ~= nil,
  graphics_set = source.graphics_set,
  working_sound = source.working_sound,
}))
```

Add `"feature_flags": ["spoiling"]` to `info.json`, after
`"dependencies"`.

- [ ] **Step 6: Write the in-game test helpers**

Create `tests/ingame/helpers.lua`:

```lua
-- Shared set-up for the in-game tests.
local Helpers = {}

function Helpers.spoil(stack)
  stack.spoil()
end

local function area(position, radius)
  local x, y = position[1], position[2]
  return { { x - radius, y - radius }, { x + radius, y + radius } }
end

-- Generates the chunks around a test position and removes every enemy
-- there, so that native nests cannot change a count.
function Helpers.arena(surface, position)
  surface.request_to_generate_chunks(position, 1)
  surface.force_generate_chunk_requests()
  for _, entity in pairs(surface.find_entities_filtered({
    area = area(position, 24), force = "enemy",
  })) do
    entity.destroy()
  end
end

-- A breeding pod with power from an electric energy interface. The
-- force has Monster husbandry, so the pod's recipes are enabled.
function Helpers.powered_pod(surface, position)
  local x, y = position[1], position[2]
  game.forces.player.technologies["ao-monster-husbandry"].researched = true
  local pod = surface.create_entity({
    name = "ao-breeding-pod", position = { x, y }, force = "player",
  })
  surface.create_entity({
    name = "small-electric-pole", position = { x + 2.5, y }, force = "player",
  })
  surface.create_entity({
    name = "electric-energy-interface", position = { x + 4.5, y }, force = "player",
  })
  return pod
end

function Helpers.count_units(surface, position, names)
  return surface.count_entities_filtered({
    area = area(position, 12), name = names, force = "enemy",
  })
end

return Helpers
```

If the probe found that `spoil()` fails and `spoil_percent = 1` works, the
body of `Helpers.spoil` is `stack.spoil_percent = 1`.

- [ ] **Step 7: Write the failing in-game content test**

Create `tests/ingame/content_test.lua`:

```lua
local Helpers = require("__abominable-ordnance__/tests/ingame/helpers")

local NAMES = {
  item = {
    "ao-biter-egg", "ao-spitter-egg", "ao-monster-chow", "ao-spitter-chow",
    "ao-breeding-pod",
  },
  recipe = {
    "ao-monster-chow", "ao-spitter-chow", "ao-breed-biter", "ao-breed-spitter",
    "ao-breeding-pod",
  },
}

test("the items, pod, recipes and research exist", function()
  for _, name in ipairs(NAMES.item) do assert(prototypes.item[name], name) end
  for _, name in ipairs(NAMES.recipe) do assert(prototypes.recipe[name], name) end
  assert(prototypes.entity["ao-breeding-pod"], "ao-breeding-pod")
  assert(prototypes.technology["ao-monster-husbandry"], "ao-monster-husbandry")
end)

test("a breeding pod makes 2 eggs from 1 egg and 5 chow", function()
  Helpers.arena(game.surfaces[1], { 400, 400 })
  local pod = Helpers.powered_pod(game.surfaces[1], { 400, 400 })
  pod.set_recipe("ao-breed-biter")
  pod.insert({ name = "ao-biter-egg", count = 1 })
  pod.insert({ name = "ao-monster-chow", count = 5 })
  after_ticks(1000, function()
    assert(pod.get_output_inventory().get_item_count("ao-biter-egg") == 2,
      "the pod did not make 2 eggs")
  end)
end)

tags("space-age")
test("the adopt recipe turns a biter-egg into a mod egg", function()
  Helpers.arena(game.surfaces[1], { 420, 400 })
  local pod = Helpers.powered_pod(game.surfaces[1], { 420, 400 })
  pod.set_recipe("ao-adopt-biter-egg")
  pod.insert({ name = "biter-egg", count = 1 })
  pod.insert({ name = "ao-monster-chow", count = 1 })
  after_ticks(400, function()
    assert(pod.get_output_inventory().get_item_count("ao-biter-egg") == 1,
      "the pod did not adopt the egg")
  end)
end)
```

Add `"tests/ingame/content_test"` to the list in the factorio-test hook
in `control.lua`.

- [ ] **Step 8: Run the in-game tests**

Run: `make ingame`
Expected: PASS in both modes.

- [ ] **Step 9: Check the icons in the real game**

The headless server does not load graphics, so `make ingame` cannot find
a wrong icon path. Ask the maintainer to start the game client with the
mod, once without and once with Space Age. They check that the pod, the
eggs and the chow show tinted icons and the pod shows tinted graphics.
Fix any path they report.

- [ ] **Step 10: Update the docs**

1. `docs/design.md`, Monsters table: replace the rows of Biter, Spitter
   and Pentapod with:

   ```markdown
   | Biter | Nauvis | Nest loot and the breeding pod; in Space Age also the captive biter spawner, through the adopt recipe | Fast, cheap melee carrier |
   | Spitter | Nauvis | Nest loot and the breeding pod | Ranged; payload lands at the target |
   | Pentapod | Gleba | Space Age's own pentapod eggs and their biochamber recipe | Tanky, long reach, crosses obstacles |
   ```

2. `docs/design.md`, Technical notes: replace the bullet "Spoiling and
   hatching" with:

   ```markdown
   - **Spoiling and hatching.** Use the 2.1 spoilage system (`spoil_ticks`
     plus a spoil trigger). The trigger runs a `script` effect, and a core
     module picks the unit from the enemy evolution. Without Space Age,
     the mod turns spoilage on itself through the `spoiling` feature flag
     in its info.json.
   ```

3. `ROADMAP.md`, under 1.0.0: replace the first item with:

   ```markdown
   - [ ] Breeding pod (slice 1) and incubator (slice 2) for biters and
     spitters ([design][lifecycle])
   ```

4. `CHANGELOG.md`, under `## [Unreleased]`, below the existing
   `### Added` items:

   ```markdown
   - Biter and spitter eggs, monster chow, spitter chow and the breeding
     pod, unlocked by the Monster husbandry research.
   ```

5. The spec: add `### Probe results` under `## Delivery`, with the answers
   from Task 1.

- [ ] **Step 11: Run all gates**

Run: `make check`
Expected: PASS.

- [ ] **Step 12: Commit and open PR 1**

Follow the commit routine with 4 reviewers. Stage `core/`, `spec/`,
`tests/ingame/`, `data.lua`, `control.lua`, `info.json`, `locale/`,
`.ste-allow`, `docs/design.md`, `ROADMAP.md`, `CHANGELOG.md` and the
spec. Message:
`feat: add eggs, feeds and the breeding pod`. Then follow the PR routine
with that title.

---

### Task 5: The hatch pick

This task writes the pure part of hatching. Its unit tests run without
the game, so they come before the shell in Task 6. It belongs to PR 2.

**Files:**

- Create: `core/hatching.lua`
- Create: `spec/core/hatching_spec.lua`

**Interfaces:**

- Consumes: `Species.by_effect_id` (Task 2).
- Produces:
   - `Hatching.weight(points, evolution)` returns a number.
   - `Hatching.pick(units, evolution, r)` returns a unit name. `r` is in
     [0, 1).
   - `Hatching.hatch(effect_id, evolution, r)` returns a unit name, or nil
     for an effect ID of no species.

- [ ] **Step 1: Make the branch (after the merge of PR 1)**

```bash
git switch main && git pull && git switch -c feat/hatching
```

- [ ] **Step 2: Write the failing test**

Create `spec/core/hatching_spec.lua`:

```lua
local Hatching = require("core.hatching")
local Species = require("core.species")

local MEDIUM_BITER = { { 0.2, 0.0 }, { 0.6, 0.3 }, { 0.7, 0.1 } }

describe("the hatch weight", function()
  it("keeps the first value below the first point", function()
    assert.are.equal(0, Hatching.weight(MEDIUM_BITER, 0.1))
  end)

  it("is linear between two points", function()
    assert.is_near(0.15, Hatching.weight(MEDIUM_BITER, 0.4), 1e-9)
    assert.is_near(0.2, Hatching.weight(MEDIUM_BITER, 0.65), 1e-9)
  end)

  it("keeps the last value beyond the last point", function()
    assert.is_near(0.1, Hatching.weight(MEDIUM_BITER, 0.9), 1e-9)
  end)
end)

describe("the hatch pick", function()
  local biter, spitter = Species.ALL[1], Species.ALL[2]

  it("gives a small biter at evolution 0", function()
    assert.are.equal("small-biter", Hatching.pick(biter.units, 0, 0))
    assert.are.equal("small-biter", Hatching.pick(biter.units, 0, 0.999999))
  end)

  it("gives a small spitter at evolution 0, never a biter", function()
    assert.are.equal("small-spitter", Hatching.pick(spitter.units, 0, 0))
    assert.are.equal("small-spitter", Hatching.pick(spitter.units, 0, 0.999999))
  end)

  it("picks by cumulative weight at evolution 1", function()
    -- Weights at 1: small 0, medium 0.1, big 0.4, behemoth 0.3.
    assert.are.equal("medium-biter", Hatching.pick(biter.units, 1, 0))
    assert.are.equal("big-biter", Hatching.pick(biter.units, 1, 0.5))
    assert.are.equal("behemoth-biter", Hatching.pick(biter.units, 1, 0.999999))
  end)

  it("hatches by effect ID, and nothing for an unknown ID", function()
    assert.are.equal("small-spitter", Hatching.hatch("ao-hatch-spitter", 0, 0.5))
    assert.is_nil(Hatching.hatch("ao-probe", 0, 0.5))
  end)
end)
```

- [ ] **Step 3: Run the test to see it fail**

Run: `make lua`
Expected: FAIL with `module 'core.hatching' not found`.

- [ ] **Step 4: Write the module**

Create `core/hatching.lua`:

```lua
-- Picks the unit that hatches from a spoiled egg, by the vanilla spawner
-- rule. A weight is linear between two points. Before the first point it
-- is the first value, and after the last point the last value. The chance
-- of a unit is its weight over the sum of weights.
local Species = require("core.species")

local Hatching = {}

function Hatching.weight(points, evolution)
  if evolution <= points[1][1] then return points[1][2] end
  for i = 2, #points do
    local a, b = points[i - 1], points[i]
    if evolution <= b[1] then
      return a[2] + (b[2] - a[2]) * (evolution - a[1]) / (b[1] - a[1])
    end
  end
  return points[#points][2]
end

function Hatching.pick(units, evolution, r)
  local weights, total = {}, 0
  for i, unit in ipairs(units) do
    weights[i] = Hatching.weight(unit[2], evolution)
    total = total + weights[i]
  end
  -- Below a species' first spawn point every weight is 0.
  if total <= 0 then return units[1][1] end
  local target, sum = r * total, 0
  for i, unit in ipairs(units) do
    sum = sum + weights[i]
    if target < sum then return unit[1] end
  end
  return units[#units][1]
end

function Hatching.hatch(effect_id, evolution, r)
  local species = Species.by_effect_id(effect_id)
  return species and Hatching.pick(species.units, evolution, r) or nil
end

return Hatching
```

- [ ] **Step 5: Run the test to see it pass**

Run: `make lua`
Expected: PASS.

---

### Task 6: The hatching shell (PR 2)

**Files:**

- Modify: `control.lua`
- Create: `tests/ingame/hatching_test.lua`
- Modify: `CHANGELOG.md`

**Interfaces:**

- Consumes: `Hatching.hatch` (Task 5), `Balance.hatch_search_radius`,
  `Species.ALL`, `Helpers` (Task 4).
- Produces: a `random()` function in `control.lua` that Task 8 also
  uses.

- [ ] **Step 1: Write the failing in-game test**

Create `tests/ingame/hatching_test.lua`:

```lua
local Helpers = require("__abominable-ordnance__/tests/ingame/helpers")
local Species = require("core.species")

local function unit_names(species)
  local names = {}
  for _, unit in ipairs(species.units) do names[#names + 1] = unit[1] end
  return names
end

local surface = function() return game.surfaces[1] end

before_each(function()
  game.forces.enemy.set_evolution_factor(0, surface())
end)

test("every hatch unit exists", function()
  for _, species in ipairs(Species.ALL) do
    for _, name in ipairs(unit_names(species)) do
      assert(prototypes.entity[name], name)
    end
  end
end)

test("10 spitter eggs in a chest hatch one spitter at evolution 0", function()
  local position = { 500, 500 }
  Helpers.arena(surface(), position)
  local chest = surface().create_entity({
    name = "steel-chest", position = position, force = "player",
  })
  chest.insert({ name = "ao-spitter-egg", count = 10 })
  Helpers.spoil(chest.get_inventory(defines.inventory.chest)[1])
  after_ticks(2, function()
    assert(Helpers.count_units(surface(), position, unit_names(Species.ALL[2])) == 1,
      "no spitter hatched")
    assert(Helpers.count_units(surface(), position, unit_names(Species.ALL[1])) == 0,
      "a biter hatched from spitter eggs")
  end)
end)

test("10 biter eggs on the ground hatch one biter", function()
  local position = { 540, 500 }
  Helpers.arena(surface(), position)
  surface().spill_item_stack({
    position = position,
    stack = { name = "ao-biter-egg", count = 10 },
    drop_full_stack = true,
  })
  local items = surface().find_entities_filtered({
    name = "item-on-ground", area = { { 535, 495 }, { 545, 505 } },
  })
  assert(#items == 1, "the eggs did not land as one stack")
  Helpers.spoil(items[1].stack)
  after_ticks(2, function()
    assert(Helpers.count_units(surface(), position, unit_names(Species.ALL[1])) == 1,
      "no biter hatched on the ground")
  end)
end)
```

Add `"tests/ingame/hatching_test"` to the list in the factorio-test
hook in `control.lua`.

- [ ] **Step 2: Run it to see it fail**

Run: `make ingame MODE=base`
Expected: FAIL with `no spitter hatched`.

- [ ] **Step 3: Write the shell**

Replace the header comment of `control.lua` with:

```lua
-- The control stage. This file is the shell: it reads the game, calls the
-- pure modules in core/ and writes the result to the game.
```

Put this below the header, above the factorio-test hook. If the probe
found only one position field (Task 1, Step 6), read only that field:

```lua
local Balance = require("core.balance")
local Hatching = require("core.hatching")
local Species = require("core.species")

-- A deterministic random number in [0, 1). storage keeps only the seed.
local function random()
  local rng = game.create_random_generator(storage.seed or 1)
  local r = rng()
  storage.seed = rng(1, 2147483647)
  return r
end

script.on_event(defines.events.on_script_trigger_effect, function(event)
  -- Other mods' triggers reach this handler too.
  if not Species.by_effect_id(event.effect_id) then return end
  local surface = game.get_surface(event.surface_index)
  local position = event.source_position or event.target_position
  if not surface or not position or surface.platform then return end
  local evolution = game.forces.enemy.get_evolution_factor(surface)
  local unit = Hatching.hatch(event.effect_id, evolution, random())
  if not unit then return end
  local spot = surface.find_non_colliding_position(unit, position, Balance.hatch_search_radius, 0.5)
  if spot then
    surface.create_entity({ name = unit, position = spot, force = "enemy" })
  end
end)
```

- [ ] **Step 4: Run the tests to see them pass**

Run: `make ingame`
Expected: PASS in both modes.

- [ ] **Step 5: Update the changelog**

In `CHANGELOG.md`, under `## [Unreleased]`, below the existing
`### Added` items:

```markdown
- Eggs hatch when they spoil: every 10 eggs hatch a wild monster of
  their species, sized by enemy evolution.
```

- [ ] **Step 6: Run all gates, commit and open PR 2**

Run: `make check`. Expected: PASS.

Follow the commit routine with 2 reviewers. Stage `core/hatching.lua`,
`spec/core/hatching_spec.lua`, `control.lua`,
`tests/ingame/hatching_test.lua` and `CHANGELOG.md`. Message:
`feat: hatch spoiled eggs by evolution`.

Then follow the PR routine with that title.

---

### Task 7: The loot drop

**Files:**

- Create: `core/loot.lua`
- Create: `spec/core/loot_spec.lua`

**Interfaces:**

- Consumes: `Species.by_spawner` (Task 2), `Balance.loot_min`,
  `Balance.loot_max`.
- Produces: `Loot.drop(spawner_name, researched, r)` returns
  `{ name = egg, count = n }` or nil. `r` is in [0, 1).

- [ ] **Step 1: Make the branch (after the merge of PR 2)**

```bash
git switch main && git pull && git switch -c feat/nest-loot
```

- [ ] **Step 2: Write the failing test**

Create `spec/core/loot_spec.lua`:

```lua
local Loot = require("core.loot")

describe("the nest loot", function()
  it("drops nothing before the research", function()
    assert.is_nil(Loot.drop("biter-spawner", false, 0.5))
  end)

  it("drops nothing from a spawner of no species", function()
    assert.is_nil(Loot.drop("gleba-spawner", true, 0.5))
  end)

  it("drops 1 to 3 eggs of the spawner's species", function()
    assert.are.same({ name = "ao-biter-egg", count = 1 }, Loot.drop("biter-spawner", true, 0))
    assert.are.same({ name = "ao-spitter-egg", count = 2 }, Loot.drop("spitter-spawner", true, 0.5))
    assert.are.same({ name = "ao-biter-egg", count = 3 },
      Loot.drop("biter-spawner", true, 0.999999))
  end)
end)
```

- [ ] **Step 3: Run it to see it fail**

Run: `make lua`
Expected: FAIL with `module 'core.loot' not found`.

- [ ] **Step 4: Write the module**

Create `core/loot.lua`:

```lua
-- Decides what a dead native spawner drops.
local Balance = require("core.balance")
local Species = require("core.species")

local Loot = {}

function Loot.drop(spawner_name, researched, r)
  local species = researched and Species.by_spawner(spawner_name)
  if not species then return nil end
  local span = Balance.loot_max - Balance.loot_min + 1
  return { name = species.egg, count = Balance.loot_min + math.floor(r * span) }
end

return Loot
```

- [ ] **Step 5: Run it to see it pass**

Run: `make lua`
Expected: PASS.

---

### Task 8: The loot shell (PR 3)

**Files:**

- Modify: `control.lua`
- Create: `tests/ingame/loot_test.lua`
- Modify: `CHANGELOG.md`, `ROADMAP.md`

**Interfaces:**

- Consumes: `Loot.drop` (Task 7), `Names.TECH`, `random()` (Task 6).

- [ ] **Step 1: Write the failing in-game test**

Create `tests/ingame/loot_test.lua`:

```lua
local surface = function() return game.surfaces[1] end

local function eggs_near(position)
  local x, y = position[1], position[2]
  local count = 0
  for _, item in pairs(surface().find_entities_filtered({
    name = "item-on-ground", area = { { x - 6, y - 6 }, { x + 6, y + 6 } },
  })) do
    if item.stack.name == "ao-biter-egg" then count = count + item.stack.count end
  end
  return count
end

local Helpers = require("__abominable-ordnance__/tests/ingame/helpers")

local function spawner(position)
  Helpers.arena(surface(), position)
  return surface().create_entity({
    name = "biter-spawner", position = position, force = "enemy",
  })
end

local function research(done)
  game.forces.player.technologies["ao-monster-husbandry"].researched = done
end

test("a spawner killed after the research drops 1 to 3 eggs", function()
  research(true)
  local position = { 600, 600 }
  spawner(position).die(game.forces.player)
  local n = eggs_near(position)
  assert(n >= 1 and n <= 3, "dropped " .. n .. " eggs")
end)

test("a spawner killed before the research drops none", function()
  research(false)
  local position = { 620, 600 }
  spawner(position).die(game.forces.player)
  assert(eggs_near(position) == 0, "eggs dropped before the research")
end)

test("a spawner that dies with no force drops none", function()
  research(true)
  local position = { 640, 600 }
  spawner(position).die()
  assert(eggs_near(position) == 0, "eggs dropped with no killer force")
end)
```

Add `"tests/ingame/loot_test"` to the list in the factorio-test hook in
`control.lua`.

- [ ] **Step 2: Run it to see it fail**

Run: `make ingame MODE=base`
Expected: FAIL with `dropped 0 eggs`.

- [ ] **Step 3: Write the shell**

Add to `control.lua`, below the hatching handler:

```lua
local Loot = require("core.loot")
local Names = require("core.names")

script.on_event(defines.events.on_entity_died, function(event)
  local force = event.force
  local tech = force and force.technologies[Names.TECH]
  local entity = event.entity
  local drop = Loot.drop(entity.name, tech ~= nil and tech.researched, random())
  if drop then
    entity.surface.spill_item_stack({
      position = entity.position, stack = drop,
      drop_full_stack = true, enable_looted = true,
    })
  end
end, { { filter = "type", type = "unit-spawner" } })
```

- [ ] **Step 4: Run the tests to see them pass**

Run: `make ingame`
Expected: PASS in both modes.

- [ ] **Step 5: Update the changelog and the roadmap**

`CHANGELOG.md`, under `## [Unreleased]`, below the existing `### Added`
items:

```markdown
- Native biter and spitter spawners drop 1 to 3 eggs when a force with
  Monster husbandry destroys them.
```

`ROADMAP.md`: no item ticks yet. "Breeding pod (slice 1) and incubator
(slice 2)" ticks in slice 2, and "Spoil outcomes" ticks when slice 2 adds
larvae. Add this line directly below the heading `## 1.0.0: design
version 1`, with a blank line on each side:

```markdown
Slice 1 (lifecycle) is done.
```

- [ ] **Step 6: Run all gates, commit and open PR 3**

Run: `make check`. Expected: PASS.

Follow the commit routine with 2 reviewers. Stage `core/loot.lua`,
`spec/core/loot_spec.lua`, `control.lua`, `tests/ingame/loot_test.lua`,
`CHANGELOG.md` and `ROADMAP.md`. Message:
`feat: drop eggs from native spawners`.

Then follow the PR routine with that title.
