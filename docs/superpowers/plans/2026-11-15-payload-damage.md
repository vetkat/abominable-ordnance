# Payload damage Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task-by-task. Steps
> use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Each payload decides what its landing blast and its death
effect hurt, with its own damage type. Deaths run through a queue. The
script runs poison clouds and acid pools as hazards with a fixed cost
per tick.

**Architecture:** The pure rules live in `core/payloads.lua` (targets,
damage types, death plans) and a new `core/hazards.lua` (the catch-up
count and the per-tick budget of the hazard pass). `core/trail.lua`
gives both passes their batches. A new shell module `shell/damage.lua`
reads the class of a target from its prototype, finds targets, deals
hits, and runs the detonation queue and the hazards. `control.lua` calls
it from the landing, the death and the trail.
`core/prototypes/ordnance.lua` builds look-alike copies of the vanilla
cloud and puddles that show the effect and deal no damage.

**Tech Stack:** Factorio 2.1.24 Lua, busted for the core, factorio-test
for the in-game tests, `make check` for all gates.

**Spec:** `docs/superpowers/specs/2026-11-15-payload-damage-design.md`
(approved 2026-11-15). The review report is
`docs/superpowers/reviews/2026-11-15-payload-damage-review-report.md`.
The maintainer took every default in "Calls for the maintainer".

## Global Constraints

- The target is Factorio 2.1, with and without Space Age.
- Every number lives in `core/balance.lua`, under
  `Balance.payload_damage`. `Balance.blast` keeps 35 damage and a
  3.5-tile radius.
- The target rules: explosive hurts everything. Poison hurts organics.
  Acid hurts everything except rocks. Damage types `explosion`,
  `poison` and `acid`.
- The defaults: poison cloud 20 s, radius 11, 8 damage per 0.5 s. Acid
  pool 15 s, radius 3, 10 damage per 0.5 s. Explosive death 150 damage
  in 4 tiles, one hit. Trail 5 damage in 1 tile per puddle, no
  long-lasting puddle damage. Acid pools put `acid-sticker-big` on
  units and characters.
- Per tick: at most 5 detonations, 10 hazard hits and 50 hazard visits.
- The maintainer wants friendly fire on your base and on tamed
  monsters. The trail never hurts the monster that dropped it.
- A core module never names `game`, `storage`, `script`, `defines`,
  `prototypes`, `rendering`, `helpers`, `remote`, `commands`, `rcon`,
  `settings`, `mods` or `data`. `spec/architecture_spec.lua` enforces
  this.
- No file in `core/`, `shell/` or `control.lua` uses `math.random`.
- All state that changes during play lives in `storage`. The class sets
  in `shell/damage.lua` are the one module-level cache: every client
  builds them from the same prototypes, so they never differ.
- A change to mod code gets a line under Unreleased in `CHANGELOG.md`.
- Commits: `make format`, `git add <files>` (never `-A`), `make stamp`,
  `git commit`, each as its own Bash call. `/ste80-humanizer` (British
  English) and `/simplify` run before `git add`. The PR body has the
  `## Review angles` section with all six angles, and the PR uses
  `gh pr merge --auto --squash`.
- Look up each Factorio API name in `.factorio-api/factorio/library/`.
  Give that path to the search. A search from the repository root skips
  the folder, because git ignores it.
- Never stage the `.factorio-api` symlink.
- In-game tests destroy what they create before they assert and give
  every poll an upper bound. The new file `tests/ingame/damage_test.lua`
  uses the row `y = 4000`, from `x = 4000` on. The landing tests stay in
  `tests/ingame/launcher_test.lua`. The probe uses the row `y = 5000`.

In every step, `BUSTED` stands for
`lua5.2 /usr/lib/luarocks/rocks-5.2/busted/2.3.0-1/bin/busted --lua=lua5.2`.

## Pull requests

| PR | Branch | Tasks |
| --- | --- | --- |
| 1. Target rules and the queue | `feat/payload-targets` | 0, then 1 to 5 |
| 2. Hazards | `feat/payload-hazards` | 6 to 9 |
| 3. Acid extras | `feat/acid-extras` | 10 to 12 |

PR 2 starts from `main` after PR 1 merges. PR 3 starts from `main`
after PR 2 merges. Each PR leaves the mod playable. In PR 1, poison and
acid deaths use the queue and still create the vanilla cloud
and puddles, with the vanilla targets. PR 2 replaces them with
look-alikes and hazards. Until PR 3, the trail keeps its vanilla puddle,
and acid pools do not slow.

Reviewers for `/simplify` and code review, by the table in `CLAUDE.md`:
PR 1 and PR 2 get 4 (they change `control.lua`, `shell/`, `storage`
and the data stage across many files). PR 3 gets 2.

## Task 0: The probe

The spec asks a throwaway probe to settle eight engine facts before the
build, and this plan adds a ninth: the sticker. Each row has a
fallback. The probe runs in a throwaway copy of the mod in your
scratchpad folder, with its own probe test file. It runs in both modes.
Nothing of it goes into the repository.

**Files:**

- Create (scratchpad copy only): `tests/ingame/probe_test.lua`
- Modify (scratchpad copy only): `data.lua`, `control.lua`

- [ ] **Step 1: Copy the mod into the scratchpad**

`$SCRATCH` is your scratchpad folder, and `$REPO` is the worktree of
this branch. Run:

```bash
PROBE="$SCRATCH/ao-damage-probe"
rsync -a --exclude .git --exclude node_modules --exclude .factorio-api --exclude build "$REPO/" "$PROBE/"
ln -s "$REPO/node_modules" "$PROBE/node_modules"
```

`tools/ingame.sh` reads `.factorio-version` and `.factorio-test-version`
from the copy and finds `factorio-test` through the `node_modules` link.

- [ ] **Step 2: Add two look-alikes to the copy's data stage**

Append to `$PROBE/data.lua`:

```lua
-- Probe only: look-alikes of the poison cloud and the big acid puddle.
local cloud = table.deepcopy(data.raw["smoke-with-trigger"]["poison-cloud"])
cloud.name = "ao-probe-cloud"
cloud.action = nil
cloud.action_cooldown = nil
local pool = table.deepcopy(data.raw["fire"]["acid-splash-fire-spitter-big"])
pool.name = "ao-probe-pool"
pool.on_damage_tick_effect = nil
pool.maximum_spread_count = 0
pool.initial_lifetime = 180
pool.maximum_lifetime = 180
pool.lifetime_increase_by = 0
data:extend({ cloud, pool })
```

- [ ] **Step 3: Write the probe test**

Create `$PROBE/tests/ingame/probe_test.lua`:

```lua
local Helpers = require("__abominable-ordnance__/tests/ingame/helpers")
local Names = require("core.names")

local surface = function()
  return game.surfaces[1]
end

local function hurt(entity)
  return not entity.valid or entity.health < entity.max_health
end

-- One row: who deals 10 damage of a kind, who takes it, and if the
-- target lost health. The log line gives the evidence for the plan.
local function row(label, attacker, target, kind)
  local before = target.health
  target.damage(10, attacker, kind or "impact")
  local passed = hurt(target)
  local after = target.valid and target.health or "dead"
  log("probe " .. label .. ": " .. (passed and "PASS" or "FAIL") .. " (" .. before .. " -> " .. after .. ")")
  if target.valid then
    target.destroy()
  end
  return passed
end

local function unit(position, force)
  local u = surface().create_entity({ name = "medium-biter", position = position, force = force })
  u.disabled_by_script = true
  return u
end

local function chest(position, force)
  return surface().create_entity({
    name = "wooden-chest",
    position = position,
    force = force or "player",
  })
end

test("1: the tamed force hurts tamed monsters, the feral force hurts feral ones", function()
  local position = { 5000, 5000 }
  Helpers.arena(surface(), position)
  local a = row("1a tamed on tamed", Names.TAMED, unit(position, Names.TAMED))
  local b = row("1b feral on feral", Names.FERAL, unit(position, Names.FERAL))
  assert(a and b, "row 1 failed, see the log")
end)

test("2: the tamed force hurts the player force", function()
  local position = { 5020, 5000 }
  Helpers.arena(surface(), position)
  assert(row("2 tamed on player chest", Names.TAMED, chest(position)), "row 2 failed")
end)

test("3: the player force hurts a tamed monster", function()
  local position = { 5040, 5000 }
  Helpers.arena(surface(), position)
  assert(row("3 player on tamed", "player", unit(position, Names.TAMED)), "row 3 failed")
end)

test("4: the neutral force hurts players and tamed monsters", function()
  local position = { 5060, 5000 }
  Helpers.arena(surface(), position)
  local a = row("4a neutral on player chest", "neutral", chest(position))
  local b = row("4b neutral on tamed", "neutral", unit(position, Names.TAMED))
  assert(a and b, "row 4 failed, see the log")
end)

test("5: damage still hurts with friendly_fire off", function()
  local position = { 5080, 5000 }
  Helpers.arena(surface(), position)
  local player = game.forces["player"]
  player.friendly_fire = false
  local a = row("5a player on player chest", "player", chest(position))
  local b = row("5b player on player character", "player", Helpers.character(surface(), position))
  player.friendly_fire = true
  assert(a and b, "row 5 failed, see the log")
end)

-- A look-alike next to a native: it must exist, and the native must
-- keep its health for 120 ticks.
local function lookalike(label, name, position)
  Helpers.arena(surface(), position)
  local native = unit({ position[1] + 1, position[2] }, "enemy")
  local effect = surface().create_entity({ name = name, position = position, force = Names.TAMED })
  local shown = effect ~= nil and effect.valid
  after_ticks(120, function()
    local whole = not hurt(native)
    log("probe " .. label .. ": " .. (shown and whole and "PASS" or "FAIL")
      .. " shown=" .. tostring(shown) .. " whole=" .. tostring(whole))
    native.destroy()
    assert(shown and whole, label .. " failed, see the log")
  end)
end

test("6: a cloud look-alike shows and deals no damage", function()
  lookalike("6 cloud", "ao-probe-cloud", { 5100, 5000 })
end)

test("7: a puddle look-alike shows and deals no damage", function()
  lookalike("7 pool", "ao-probe-pool", { 5120, 5000 })
end)

test("8: trees take poison and acid, rocks take explosion damage", function()
  local position = { 5140, 5000 }
  Helpers.arena(surface(), position)
  local function tree()
    return surface().create_entity({ name = "tree-01", position = position })
  end
  local a = row("8a poison on tree", Names.TAMED, tree(), "poison")
  local b = row("8b acid on tree", Names.TAMED, tree(), "acid")
  local rock = surface().create_entity({ name = "big-rock", position = position })
  local c = row("8c explosion on rock", Names.TAMED, rock, "explosion")
  assert(a and b and c, "row 8 failed, see the log")
end)

test("9: create_entity puts the big acid sticker on a unit", function()
  local position = { 5160, 5000 }
  Helpers.arena(surface(), position)
  local native = unit(position, "enemy")
  surface().create_entity({
    name = "acid-sticker-big",
    position = native.position,
    target = native,
    force = Names.TAMED,
  })
  local count = native.stickers and #native.stickers or 0
  log("probe 9 sticker: " .. (count > 0 and "PASS" or "FAIL") .. " stickers=" .. count)
  native.destroy()
  assert(count > 0, "row 9 failed, see the log")
end)
```

In `$PROBE/control.lua`, replace the whole test list in the
`require("__factorio-test__/init")` call with
`{ "tests/ingame/probe_test" }`.

- [ ] **Step 4: Run the probe in both modes**

Run:

```bash
cd "$PROBE" && tools/ingame.sh 2>&1 | tee "$SCRATCH/probe.log"
```

Expected: 9 tests per mode. Each `probe N` log line says PASS or FAIL.

- [ ] **Step 5: Record the outcome**

Write the outcome of each row into this table, with the log line as
evidence. Then delete `$PROBE`. The table stays in this plan.

| # | Fact | Outcome | Evidence |
| --- | --- | --- | --- |
| 1 | `damage` with the tamed force hurts tamed monsters, and with the feral force feral monsters | PASS | `1a tamed on tamed: PASS (75 -> 65)`, `1b feral on feral: PASS (75 -> 65)`; Factorio 2.1.24, same in both modes |
| 2 | `damage` with the tamed force hurts the player force (cease-fire) | PASS | `tamed on player chest: PASS (100 -> 90)`; Factorio 2.1.24, same in both modes |
| 3 | `damage` with a player force hurts a tamed monster (cease-fire) | PASS | `player on tamed: PASS (75 -> 65)`; Factorio 2.1.24, same in both modes |
| 4 | `damage` with the `neutral` force hurts players and tamed monsters | PASS | `neutral on player chest: PASS (100 -> 90)`, `neutral on tamed: PASS (75 -> 65)`; Factorio 2.1.24, same in both modes |
| 5 | `damage` still hurts when the attacker's force has `friendly_fire = false` | FAIL | `player on player chest: FAIL (100 -> 100)`, `player on player character: FAIL (250 -> 250)`; Factorio 2.1.24, same in both modes |
| 6 | A cloud look-alike with no action shows the cloud and deals no damage | PASS | `cloud: PASS shown=true whole=true`; Factorio 2.1.24, same in both modes |
| 7 | A puddle look-alike with no `on_damage_tick_effect`, no spreading and a short lifetime shows and deals no damage | PASS | `pool: PASS shown=true whole=true`; Factorio 2.1.24, same in both modes |
| 8 | Trees take `poison` and `acid` damage, and rocks take `explosion` damage | PASS | `poison on tree: PASS (50 -> 40)`, `acid on tree: PASS (50 -> 40)`, `explosion on rock: PASS (500 -> 490)`; Factorio 2.1.24, same in both modes |
| 9 | `create_entity` with the sticker name, the target and its position puts `acid-sticker-big` on a unit | PASS | `sticker: PASS stickers=1`; Factorio 2.1.24, same in both modes |

- [ ] **Step 6: Apply the fallback of each failed row**

What each row changes in the tasks below, if it fails. Record each
applied fallback as a ruling in the ledger section of this plan.

- **Rows 1 to 5: a force pair that `damage` skips.** Add the rule
  `Forces.attacker(attacker, target)` to `core/forces.lua`, with a
  busted test in `spec/core/forces_spec.lua`. It returns `"enemy"` for
  the failed pair of force names and `attacker` for every other pair.
  In `Damage.hit` (Task 2), pass
  `Forces.attacker(hit.force, target.force.name)` to `target.damage`
  instead of `hit.force`. Those kills then count for the natives, and
  a nest they kill drops no loot. Say so in the changelog of PR 1.
- **Row 6: the cloud look-alike.** In Task 7, build a `trivial-smoke`
  from the cloud's `animation`, `duration`, `cyclic`, `color`,
  `render_layer` and `affected_by_wind`, with `hidden = true`, instead
  of a copy of the `smoke-with-trigger`.
- **Row 7: the puddle look-alike.** In Task 7, skip the pool
  prototype. In Task 8, `Damage.detonate` draws the hazard with
  `rendering.draw_animation` for `plan.hazard.ticks`, with an
  `animation` prototype that Task 7 builds from the vanilla puddle's
  `pictures[1]`.
- **Row 8: resistances.** Keep the code. In the in-game tests of Task 3
  and Task 4, drop the assertion on the entity that resists. Say in the
  changelog of PR 1 that vanilla resistances apply.
- **Row 9: the sticker.** In Task 11, give the pool look-alike an
  `on_damage_tick_effect` with `force = "all"` and only the
  `create-sticker` effect, instead of a sticker from the script.

## Review Focus

- **A player's own character in the blast.** Friendly fire is on, so
  the character takes the damage, and nothing errors. Task 3 pins it
  with a character among the landing targets.
- **An old save without the queue or the hazards.** A configuration
  change must create `storage.detonations` and `storage.hazards`, and
  the first tick after the update must not error. Task 4 and Task 8
  pin it in the game.
- **A hazard whose payload the mod no longer knows.** It must leave the
  table without damage and without an error. Task 8 pins it.
- **A chain of deaths on one spot.** The first death must not run the
  second inside `on_entity_died`, and the queue must empty. Task 4 pins
  it with two explosive monsters.
- **The acid trail next to another tamed monster.** The trail hurts the
  other monster and never its own. Task 11 pins it.

## Decisions the plan makes

The spec leaves these open, or the plan departs from its wording. Each
one is a ruling for the ledger.

1. **A new pure module `core/hazards.lua`.** The spec's architecture
   table lists no core module for the hazard pass, yet it asks for
   busted tests of the catch-up count and the budget. Those need pure
   code. `core/hazards.lua` holds `Hazards.new`, `Hazards.due` and
   `Hazards.plan`. Cost if wrong: one module to fold into
   `core/trail.lua`.
2. **The detonation queue has no cursor.** `storage.detonations` is a
   table keyed by `storage.detonation_counter`. The pass reads up to
   `detonation_batch` keys with `Trail.batch` from the start and
   removes each entry before it runs. New detonations from a chain get
   higher keys and run in a later tick. `Trail.forget` and
   `Trail.start` stay unused here.
3. **Rock before organic.** `Damage.class_of` checks the rock flag
   first, then `breaths-air`. A modded rock that breathes air is a
   rock.
4. **A ninth probe row for the sticker.** The spec relies on
   `create_entity` with a target for the slowdown but has no row for it.
5. **`Damage.hit` takes a force name.** The landing passes
   `launcher.force.name` or `"neutral"`. The detonation and hazard
   passes check `game.forces[name]` first and drop the entry when the
   force no longer exists. A name makes the probe fallback (a force pair rule)
   a one-line change.
6. **A detonation has no cause.** It runs a tick after the death, so
   the monster no longer exists. The spec says this for hazards. The plan
   applies it to the explosive hit too.
7. **Counters start at 0, cursors at nil.** `Setup.on_init` creates
   the two tables and the two counters. The cursors need no setup:
   `nil` means the start of the table, as for the trail cursor.
8. **`Payloads.trail` also returns the payload name.** The trail hit
   needs the payload for its targets and damage type. From PR 3 on,
   `load_monster` no longer stores `entry.trail`, and readers ignore a
   stored one.
9. **A hazard with a lost surface or force leaves at its next due hit.**
   The pure planner does not see the game. The shell removes such a
   hazard when its hit comes up. Until then it costs one visit per
   pass and no search.
10. **The pool look-alike sets both lifetimes.** `initial_lifetime`
    and `maximum_lifetime` get the hazard's ticks, and
    `lifetime_increase_by` is 0. The small trail puddle keeps the
    vanilla numbers.
11. **The tests of the landing stay in `launcher_test.lua`.** They need the
    `fire` helper there. Every other new in-game test goes in
    `tests/ingame/damage_test.lua`.
12. **The feral-kill test reads the loot only.** No eggs after the kill
    shows that the tamed force did not deal it. The plan does not read
    the kill statistics.
13. **The roadmap line gets its tick in PR 3**, when the acid rule is
    complete.
14. **The whole `Balance.payload_damage` table lands in PR 1**, so the
    busted test "every number lives there" runs once and later PRs add
    no numbers.
15. **Poison searches with the organic type list. Explosive and acid
    search everything.** This is the spec's proposal, made exact: a
    payload that hurts buildings searches everything, because a
    building is any other entity.
16. **Hazard tests shorten the hazard.** An in-game test sets
    `end_tick` on the stored hazard, so a 20 s cloud ends in a few
    seconds of game time. The busted tests prove the arithmetic.
17. **The Space Age test creates the demolisher on Nauvis.** If
    `create_entity` returns nil there, the test creates the Vulcanus
    surface with `game.planets["vulcanus"].create_surface()` and uses
    it. Record which one worked.

18. **`Damage.trail` takes the force.** `control.lua` passes
    `FeralShell.force_of(entry)`, so `shell/damage.lua` does not
    depend on `shell/feral.lua`. The trail hit has the monster as its
    cause, because the monster still exists.
19. **The test counts the chest's stickers by name nearby.** A chest
    cannot carry a sticker, so the test counts `acid-sticker-big`
    entities within half a tile instead of reading `chest.stickers`.
20. **The hazard test reads a reference chest.** Three separate hits
    of 10 acid on a reference chest give the full damage after
    resistances. Each hazard's chest must lose at least that much,
    because a summed hit loses a flat resistance only once.

## Ledger rulings made during the build

Add one line per ruling, with its cost if wrong. The failure log of the
functional-core work loop goes here too.

- Row 5 failed: `damage` from a force on its own entities does nothing
  when that force has friendly_fire off. No force of the mod turns it
  off, so this only happens when a scenario or another mod does. Then
  the enemy force deals that hit, as the spec's accepted probe fallback
  says, and the kill counts for the natives. The rule is
  `Forces.attacker(attacker, target, friendly_fire)`. Cost if wrong:
  another force pair also fails in some setup, and its hits do nothing.
- PR 2, Task 7: the in-game test "a poison monster that dies poisons a
  native biter" checks poison damage, so it fails from the Task 7
  commit until Task 8. Cost if wrong: one commit inside the branch fails
  in the game. The squash merge keeps `main` green.
- PR 2, Task 7: `cspell.json` gets the word "alikes", because the spell
  check splits "look-alikes" at the hyphen. Cost if wrong: a stray
  "alikes" passes the spell check.
- PR 2, Task 8: the new in-game tests use `x = 4380` to `x = 4800`. The
  plan's spots 4220, 4260 and 4340 belong to tests of PR 1. Cost if
  wrong: none.
- PR 2, Task 8: the cloud test asserts that the native's health does not
  fall after the end, not that it stays the same. A big biter heals
  0.02 per tick. Cost if wrong: a hit smaller than the healing after the
  end passes. One poison hit is 8, so none does.
- PR 2, Task 8: the hazard pass works like the queue. It creates its
  fields when they are missing. It returns at once for an empty table.
  It replaces a drained table with a fresh one and a nil cursor. Cost
  if wrong: none, because a drained table has no key for the cursor to
  keep.
- PR 2, Task 8: the test of the drained table runs `Damage.run_hazards`
  by hand on a table of its own. The clouds of earlier tests still live
  for 20 s. Cost if wrong: the test does not cover the `on_tick` call,
  which the other hazard tests cover.
- PR 2, Task 8, decision 17: `create_entity` makes the small demolisher
  on Nauvis, and it takes poison damage. The test needs no Vulcanus
  surface.
- PR 2, review fix: `Damage.damage_type(payload, damage_prototypes)` is
  public, so an in-game test can pass a table without the damage type.
  Cost if wrong: one more public name in `shell/damage.lua`.
- PR 2, review fix: `wrap_deaths` in `tests/ingame/damage_test.lua`
  wraps the death event for `kill_by_hit` and for the test of a cause
  that a death handler destroys. Cost if wrong: none.

## Interface sheet

The names that more than one task uses. A task's implementer sees only
their own task, so the exact names are here.

- `Balance.payload_damage`: `explosive = { damage = 150, radius = 4 }`,
  `poison = { damage = 8, radius = 11, ticks = 1200 }`,
  `acid = { damage = 10, radius = 3, ticks = 900 }`,
  `trail = { damage = 5, radius = 1 }`, `hazard_interval = 30`,
  `hazard_hits = 10`, `hazard_visits = 50`, `detonation_batch = 5`.
- `Payloads.CLASSES = { "organic", "rock", "building" }`.
- `Payloads.hits(name, class) -> boolean`.
- `Payloads.damage_type(name) -> string | nil`.
- `Payloads.numbers(name) -> Balance.payload_damage[name] | nil`.
- `Payloads.on_death(names, position, exists) -> plans`. The shape of
  a plan is below.
- `Payloads.trail(names) -> entity_name | nil, payload_name | nil`
  (PR 3). `Payloads.sticker(name) -> string | nil` (PR 3).
- `Names.CLOUD = "ao-poison-cloud"`, `Names.POOL = "ao-acid-pool"`
  (PR 2), `Names.PUDDLE = "ao-acid-puddle"` (PR 3).
- `Hazards.new`, `Hazards.due` and `Hazards.plan`, with the shapes
  below. A new hazard has `last_hit = tick - interval` and
  `end_tick = tick + ticks`.
- A detonation and a hazard, with the shapes below.
- `storage.detonations`, `storage.detonation_counter`,
  `storage.hazards`, `storage.hazard_counter`, `storage.hazard_cursor`.
- `Damage.class_of(entity) -> "organic" | "rock" | "building"`.
- `Damage.targets(surface, position, radius, payload) -> entities`.
- `Damage.hit(hit) -> survivors`, where `hit` has `surface`,
  `position`, `radius`, `payload`, `damage`, `force` (a force name),
  and optional `cause`, `skip` and `sticker`.
- `Damage.queue(surface, position, payloads, force_name)`.
- `Damage.detonate(detonation)`, `Damage.run_detonations()`,
  `Damage.run_hazards(tick)` (PR 2), `Damage.trail(entry, force)`
  (PR 3).
- `Helpers.loaded_entry(surface, position, item, after)` (Task 4).

The shapes:

```lua
-- Payloads.on_death returns a list of plans:
plan = {
  payload = name,
  entities = { create_entity_table },
  hit = { damage, radius } or nil,
  hazard = { ticks } or nil,
}
Hazards.new(surface_index, position, payload, force, tick, ticks, interval) -- hazard
Hazards.due(hazard, tick, interval) -- count
Hazards.plan(hazards, cursor, tick, numbers)
-- returns { hits = { { id, count, last_hit } }, done = { id }, cursor }
detonation = { surface = index, position = { x, y }, payload = name, force = force_name }
hazard = {
  surface = index,
  position = { x, y },
  payload = name,
  force = force_name,
  last_hit = tick,
  end_tick = tick,
}
```

---

## PR 1: target rules, the queue, the water landing and the explosive death

Branch `feat/payload-targets` from `main`. Task 0 runs first. Its
fallbacks, if any, change Tasks 2 to 4 as "Apply the fallback" says.

### Task 1: Numbers, target rules and death plans (core)

**Files:**

- Modify: `core/balance.lua`
- Modify: `core/payloads.lua`
- Modify: `core/forces.lua`
- Modify: `spec/core/payloads_spec.lua`
- Modify: `spec/core/forces_spec.lua`

**Interfaces:**

- Consumes: `Balance.acid_spread` (slice 2), `Species.ALL`.
- Produces: `Balance.payload_damage`, `Payloads.CLASSES`,
  `Payloads.hits`, `Payloads.damage_type`, `Payloads.numbers`, and
  `Payloads.on_death` with the plan shape from the interface sheet.
  `Forces.blast_hits` goes.

- [ ] **Step 1: Write the failing tests**

In `spec/core/payloads_spec.lua`, replace the whole
`describe("the payload effects", ...)` block with:

```lua
describe("the target rules", function()
  it("let explosive hurt every class", function()
    for _, class in ipairs(Payloads.CLASSES) do
      assert.is_true(Payloads.hits("explosive", class), class)
    end
  end)

  it("let poison hurt organics only", function()
    assert.is_true(Payloads.hits("poison", "organic"))
    assert.is_false(Payloads.hits("poison", "rock"))
    assert.is_false(Payloads.hits("poison", "building"))
  end)

  it("let acid hurt everything except rocks", function()
    assert.is_true(Payloads.hits("acid", "organic"))
    assert.is_true(Payloads.hits("acid", "building"))
    assert.is_false(Payloads.hits("acid", "rock"))
  end)

  it("hurt nothing for an unknown payload or class", function()
    assert.is_false(Payloads.hits("glitter", "organic"))
    assert.is_false(Payloads.hits("explosive", "cloud"))
  end)

  it("give each payload its own damage type", function()
    assert.are.equal("explosion", Payloads.damage_type("explosive"))
    assert.are.equal("acid", Payloads.damage_type("acid"))
    assert.are.equal("poison", Payloads.damage_type("poison"))
    assert.is_nil(Payloads.damage_type("glitter"))
  end)
end)

describe("the payload numbers", function()
  it("all live in Balance.payload_damage", function()
    local d = Balance.payload_damage
    for _, name in ipairs({ "explosive", "poison", "acid", "trail" }) do
      assert.is_number(d[name].damage, name)
      assert.is_number(d[name].radius, name)
    end
    assert.is_number(d.poison.ticks)
    assert.is_number(d.acid.ticks)
    for _, key in ipairs({ "hazard_interval", "hazard_hits", "hazard_visits", "detonation_batch" }) do
      assert.is_number(d[key], key)
    end
  end)

  it("come from Payloads.numbers by payload name", function()
    assert.are.equal(Balance.payload_damage.acid, Payloads.numbers("acid"))
    assert.is_nil(Payloads.numbers("glitter"))
    assert.is_nil(Payloads.numbers("hazard_hits"))
  end)
end)

describe("the death plans", function()
  local p = { x = 10, y = 20 }
  local function all()
    return true
  end

  it("show an explosion and deal one hit for an explosive payload", function()
    assert.are.same({
      {
        payload = "explosive",
        entities = { { name = "big-explosion", position = p } },
        hit = { damage = 150, radius = 4 },
      },
    }, Payloads.on_death({ "explosive" }, p, all))
  end)

  it("leave a vanilla poison cloud for a poison payload", function()
    assert.are.same(
      { { payload = "poison", entities = { { name = "poison-cloud", position = p } } } },
      Payloads.on_death({ "poison" }, p, all)
    )
  end)

  it("spread five vanilla acid puddles for an acid payload", function()
    local d = Balance.acid_spread
    local plan = Payloads.on_death({ "acid" }, p, all)[1]
    assert.are.equal("acid", plan.payload)
    assert.is_nil(plan.hit)
    local spots = {}
    for _, e in ipairs(plan.entities) do
      assert.are.equal("acid-splash-fire-spitter-big", e.name)
      spots[#spots + 1] = (e.position.x - 10) / d .. "," .. (e.position.y - 20) / d
    end
    table.sort(spots)
    assert.are.same({ "-1,0", "0,-1", "0,0", "0,1", "1,0" }, spots)
  end)

  it("give each entity its own position table", function()
    local entity = Payloads.on_death({ "explosive" }, p, all)[1].entities[1]
    assert.are_not.equal(p, entity.position)
  end)

  it("skip an unknown payload", function()
    assert.are.same({}, Payloads.on_death({ "glitter" }, p, all))
  end)

  it("keep the hit when the explosion's prototype is missing", function()
    local function no_explosion(name)
      return name ~= "big-explosion"
    end
    local plan = Payloads.on_death({ "explosive" }, p, no_explosion)[1]
    assert.are.same({}, plan.entities)
    assert.are.same({ damage = 150, radius = 4 }, plan.hit)
  end)

  it("give one plan per payload, in order", function()
    local plans = Payloads.on_death({ "poison", "explosive" }, p, all)
    assert.are.same({ "poison", "explosive" }, { plans[1].payload, plans[2].payload })
  end)

  it("give acid a trail and no other payload one", function()
    assert.are.equal("acid-splash-fire-spitter-small", Payloads.trail({ "acid" }))
    assert.are.equal("acid-splash-fire-spitter-small", Payloads.trail({ "poison", "acid" }))
    assert.is_nil(Payloads.trail({ "poison" }))
  end)
end)
```

In `spec/core/forces_spec.lua`, delete the two tests "let the landing
blast hit only forces at war, never the tamed force" and the test that
starts "count only the natives".

- [ ] **Step 2: Run the tests to watch them fail**

Run: `BUSTED spec/core/payloads_spec.lua spec/core/forces_spec.lua`

Expected: FAIL. `Payloads.CLASSES` is nil, `Payloads.hits` is nil, and
the death plans have the old shape. The forces spec passes.

- [ ] **Step 3: Write the code**

In `core/balance.lua`, add after `blast = { damage = 35, radius = 3.5 },`:

```lua
  payload_damage = {
    explosive = { damage = 150, radius = 4 },
    poison = { damage = 8, radius = 11, ticks = 1200 },
    acid = { damage = 10, radius = 3, ticks = 900 },
    trail = { damage = 5, radius = 1 },
    hazard_interval = 30,
    hazard_hits = 10,
    hazard_visits = 50,
    detonation_batch = 5,
  },
```

In `core/payloads.lua`, replace `Payloads.ALL` with:

```lua
-- The target classes of a payload. shell/damage.lua reads the class of
-- an entity from its prototype.
Payloads.CLASSES = { "organic", "rock", "building" }

Payloads.ALL = {
  {
    name = "explosive",
    item = "explosive-rocket",
    icon = "__base__/graphics/icons/explosive-rocket.png",
    targets = { organic = true, rock = true, building = true },
    damage_type = "explosion",
    -- The explosion shows a picture. The script deals one hit.
    death = { entity = "big-explosion", hit = true },
  },
  {
    name = "acid",
    item = "sulfuric-acid-barrel",
    icon = "__base__/graphics/icons/fluid/sulfuric-acid.png",
    targets = { organic = true, building = true },
    damage_type = "acid",
    -- One puddle hurts only what stands in it, so the death spreads five.
    death = { entity = "acid-splash-fire-spitter-big", spread = true },
    trail = "acid-splash-fire-spitter-small",
  },
  {
    name = "poison",
    item = "poison-capsule",
    icon = "__base__/graphics/icons/poison-capsule.png",
    targets = { organic = true },
    damage_type = "poison",
    death = { entity = "poison-cloud" },
  },
}
```

Replace everything from `-- The death spot and, for a spread effect`
to the end of `Payloads.on_death` with:

```lua
-- True when the payload hurts a target of this class. An unknown
-- payload or class hurts nothing.
function Payloads.hits(name, class)
  local payload = BY_NAME[name]
  return payload ~= nil and payload.targets[class] == true
end

-- The damage type of a payload, or nil for an unknown one.
function Payloads.damage_type(name)
  local payload = BY_NAME[name]
  return payload and payload.damage_type or nil
end

-- The numbers of a payload in Balance.payload_damage, or nil for an
-- unknown one.
function Payloads.numbers(name)
  return BY_NAME[name] and Balance.payload_damage[name] or nil
end

-- The death spot and, for a spread effect, four spots around it.
local SPREAD = { { 0, 0 }, { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }

-- The create_entity tables of one death effect, without force or cause.
-- An entity whose prototype fails exists(name) stays out.
local function entities(death, position, exists)
  local out = {}
  if not exists(death.entity) then
    return out
  end
  for _, o in ipairs(death.spread and SPREAD or { { 0, 0 } }) do
    local d = Balance.acid_spread
    out[#out + 1] = {
      name = death.entity,
      position = { x = position.x + o[1] * d, y = position.y + o[2] * d },
    }
  end
  return out
end

-- One plan per payload of a monster that dies at a position. A plan
-- names the payload, lists the entities to create, and carries the
-- script hit (hit) when the payload has one. A missing prototype takes
-- the entities out, never the damage. An unknown payload gives no plan.
function Payloads.on_death(names, position, exists)
  local out = {}
  for _, name in ipairs(names) do
    local payload = BY_NAME[name]
    if payload then
      local plan = { payload = name, entities = entities(payload.death, position, exists) }
      if payload.death.hit then
        local n = Balance.payload_damage[name]
        plan.hit = { damage = n.damage, radius = n.radius }
      end
      out[#out + 1] = plan
    end
  end
  return out
end
```

`Payloads.trail` stays as it is.

In `core/forces.lua`, delete `Forces.blast_hits` and its comment.

- [ ] **Step 4: Run the tests to watch them pass**

Run: `BUSTED spec/core/payloads_spec.lua spec/core/forces_spec.lua`

Expected: PASS, 0 failures.

- [ ] **Step 5: Commit**

Run `/ste80-humanizer` on the new comments and `/simplify` (1
reviewer), then each as its own command:

```bash
make format
git add core/balance.lua core/payloads.lua core/forces.lua spec/core/payloads_spec.lua spec/core/forces_spec.lua
make stamp
git commit -m "feat: give each payload its targets, damage type and death plan"
```

`make fast` fails at this commit, because `control.lua` still calls
`Forces.blast_hits` and reads `death.name`. Task 3 fixes the first and
Task 4 the second. If the hook refuses the commit, fold Task 1 into the
commit of Task 3.

### Task 2: Target classes and hits (shell)

**Files:**

- Create: `shell/damage.lua`
- Create: `tests/ingame/damage_test.lua`
- Modify: `control.lua` (the test list only)

**Interfaces:**

- Consumes: `Payloads.hits`, `Payloads.damage_type` (Task 1).
- Produces: `Damage.class_of`, `Damage.targets` and `Damage.hit` from
  the interface sheet. Task 3 and Task 4 build on them.

- [ ] **Step 1: Write the failing in-game test**

Create `tests/ingame/damage_test.lua`:

```lua
local Damage = require("shell.damage")
local Helpers = require("__abominable-ordnance__/tests/ingame/helpers")

local surface = function()
  return game.surfaces[1]
end

test("the class of a biter, a tree, a rock and a chest", function()
  local position = { 4000, 4000 }
  Helpers.arena(surface(), position)
  local things = {
    { "small-biter", "organic", "enemy" },
    { "tree-01", "organic" },
    { "big-rock", "rock" },
    { "wooden-chest", "building", "player" },
  }
  for i, thing in ipairs(things) do
    local entity = surface().create_entity({
      name = thing[1],
      position = { position[1] + 4 * i, position[2] },
      force = thing[3],
    })
    local class = Damage.class_of(entity)
    entity.destroy()
    assert(class == thing[2], thing[1] .. " is " .. class)
  end
end)

test("a poison hit hurts a biter and not a chest beside it", function()
  local position = { 4020, 4000 }
  Helpers.arena(surface(), position)
  local native = surface().create_entity({
    name = "medium-biter",
    position = { position[1] + 1, position[2] },
    force = "enemy",
  })
  native.disabled_by_script = true
  local chest = Helpers.chest(surface(), { position[1] - 1, position[2] })
  local survivors = Damage.hit({
    surface = surface(),
    position = { x = position[1], y = position[2] },
    radius = 3,
    payload = "poison",
    damage = 10,
    force = "ao-tamed",
  })
  local native_hurt = native.health < native.max_health
  local chest_whole = chest.health == chest.max_health
  native.destroy()
  chest.destroy()
  assert(native_hurt, "the native is untouched")
  assert(chest_whole, "the chest is hurt")
  assert(#survivors == 1, #survivors .. " survivors")
end)

test("a hit spares the entity it is told to skip", function()
  local position = { 4040, 4000 }
  Helpers.arena(surface(), position)
  local native = surface().create_entity({
    name = "medium-biter",
    position = position,
    force = "enemy",
  })
  native.disabled_by_script = true
  Damage.hit({
    surface = surface(),
    position = native.position,
    radius = 2,
    payload = "acid",
    damage = 10,
    force = "ao-tamed",
    skip = native,
  })
  local whole = native.health == native.max_health
  native.destroy()
  assert(whole, "the skipped native is hurt")
end)
```

In `control.lua`, add `"tests/ingame/damage_test",` to the test list
after `"tests/ingame/feral_test",`.

- [ ] **Step 2: Run the in-game tests to watch them fail**

Run: `tools/ingame.sh base`

Expected: FAIL with `module shell.damage not found`.

- [ ] **Step 3: Write the module**

Create `shell/damage.lua`:

```lua
-- Deals the payload damage in the game: the class of a target, the
-- targets of a payload in an area, one hit, and the detonation queue.
-- This module is shell: it reads and writes the game. control.lua calls
-- it, and so do the in-game tests. The rules live in core/payloads.lua.
local Balance = require("core.balance")
local Payloads = require("core.payloads")
local Trail = require("core.trail")

local Damage = {}

local function entity_exists(name)
  return prototypes.entity[name] ~= nil
end

-- The class sets, built once per load from the prototypes. Every client
-- builds the same sets from the same prototypes, and nothing changes
-- them after the build, so this cache never differs between clients.
local classes

-- The organic names, the rock names and the sorted types of the
-- organic prototypes. A rock is a simple-entity with the rock flag of
-- the deconstruction filter. An organic breathes air.
local function build_classes()
  local organic, rock, types, seen = {}, {}, {}, {}
  for name, proto in pairs(prototypes.entity) do
    if proto.type == "simple-entity" and proto.count_as_rock_for_filtered_deconstruction then
      rock[name] = true
    elseif proto.has_flag("breaths-air") then
      organic[name] = true
      if not seen[proto.type] then
        seen[proto.type] = true
        types[#types + 1] = proto.type
      end
    end
  end
  table.sort(types)
  return { organic = organic, rock = rock, organic_types = types }
end

local function class_sets()
  classes = classes or build_classes()
  return classes
end

-- The target class of an entity: organic, rock or building.
---@param entity LuaEntity
function Damage.class_of(entity)
  local c = class_sets()
  if c.rock[entity.name] then
    return "rock"
  end
  if c.organic[entity.name] then
    return "organic"
  end
  return "building"
end

-- The type filter of a payload's search, or nil to search everything.
-- A payload that hurts buildings searches everything, because a
-- building is any other entity. The others search their classes' types.
local function search_types(payload)
  if Payloads.hits(payload, "building") then
    return nil
  end
  local types = {}
  if Payloads.hits(payload, "organic") then
    for _, t in ipairs(class_sets().organic_types) do
      types[#types + 1] = t
    end
  end
  if Payloads.hits(payload, "rock") then
    types[#types + 1] = "simple-entity"
  end
  return types
end

-- The entities with health within radius of a position that the
-- payload hurts.
function Damage.targets(surface, position, radius, payload)
  local types = search_types(payload)
  if types and #types == 0 then
    return {}
  end
  local out = {}
  local found = surface.find_entities_filtered({
    position = position,
    radius = radius,
    type = types,
  })
  for _, entity in pairs(found) do
    if entity.valid and entity.is_entity_with_health and Payloads.hits(payload, Damage.class_of(entity)) then
      out[#out + 1] = entity
    end
  end
  return out
end

-- One hit of a payload. hit has surface, position, radius, payload,
-- damage and force (a force name). It may have cause (the entity that
-- set it off) and skip (an entity the hit spares). It checks each
-- target before the hit, because an earlier target's death can take a
-- later one with it. Returns the targets that still exist after the
-- hit.
function Damage.hit(hit)
  local kind = Payloads.damage_type(hit.payload)
  local survivors = {}
  for _, target in ipairs(Damage.targets(hit.surface, hit.position, hit.radius, hit.payload)) do
    if target.valid and target ~= hit.skip then
      target.damage(hit.damage, hit.force, kind, nil, hit.cause)
      if target.valid then
        survivors[#survivors + 1] = target
      end
    end
  end
  return survivors
end

return Damage
```

`Balance` and `Trail` serve Task 4. If luacheck flags them as unused
at this commit, add them in Task 4 instead.

- [ ] **Step 4: Run the tests to watch them pass**

Run: `tools/ingame.sh base`

Expected: the three new tests pass. The launcher tests still pass,
because `control.lua` still uses the slice 3 blast.

Run: `make lua`

Expected: luacheck, StyLua, LuaLS and busted pass.

- [ ] **Step 5: Commit**

Run `/ste80-humanizer` on the new comments and `/simplify` (2
reviewers), then each as its own command:

```bash
make format
git add shell/damage.lua tests/ingame/damage_test.lua control.lua
make stamp
git commit -m "feat: add the target classes and the payload hit"
```

### Task 3: The landing blast follows the payload (control stage)

**Files:**

- Modify: `control.lua` (`blast`, `land`, the requires)
- Modify: `core/forces.lua`
- Modify: `spec/core/forces_spec.lua`
- Modify: `tests/ingame/launcher_test.lua`

**Interfaces:**

- Consumes: `Damage.hit` (Task 2), `Payloads.decode_land` (slice 3),
  `Balance.blast`.
- Produces: `blast(surface, position, launcher, payload)` in
  `control.lua`. `Forces.blast_hits` goes.

- [ ] **Step 1: Write the failing in-game tests**

In `tests/ingame/launcher_test.lua`, replace the test "the blast hurts
a native and a rival force, and not a tamed monster, a player chest or
a rock" and the test "the blast of a rocket without a launcher hurts
only the natives" with:

```lua
-- Polls each tick, up to limit ticks, until at least count tamed
-- units stand near a spot. Then it calls finish(hatched). The monster
-- hatches in the tick of the landing. Its own bites and its payload
-- come later, so at that tick only the blast hurt the targets.
local function once_landed(to, count, limit, finish)
  if #tamed_units(to) >= count or limit <= 0 then
    finish(#tamed_units(to) >= count)
    return
  end
  after_ticks(1, function()
    once_landed(to, count, limit - 1, finish)
  end)
end

-- The targets of a landing blast around a spot, by name. Each one is
-- within 3.5 tiles of the spot.
local function blast_targets(to)
  local t = {
    native = surface().create_entity({
      name = "medium-biter",
      position = { to[1] + 1, to[2] },
      force = "enemy",
    }),
    tamed = surface().create_entity({
      name = "medium-biter",
      position = { to[1] - 1, to[2] },
      force = Names.TAMED,
    }),
    chest = surface().create_entity({
      name = "wooden-chest",
      position = { to[1], to[2] + 1.5 },
      force = "player",
    }),
    character = Helpers.character(surface(), { to[1] + 1.5, to[2] + 1.5 }),
    tree = surface().create_entity({ name = "tree-01", position = { to[1] - 1.5, to[2] + 1.5 } }),
    rock = surface().create_entity({ name = "big-rock", position = { to[1], to[2] - 2 } }),
  }
  t.native.disabled_by_script = true
  t.tamed.disabled_by_script = true
  return t
end

-- Reads which targets lost health, then removes the targets, the
-- hatched monsters and the launcher, so a failed assert leaves nothing.
local function settle(to, targets, launcher)
  local hurt = {}
  for name, entity in pairs(targets) do
    hurt[name] = not entity.valid or entity.health < entity.max_health
    if entity.valid then
      entity.destroy()
    end
  end
  for _, unit in ipairs(tamed_units(to)) do
    unit.destroy()
  end
  if launcher and launcher.valid then
    launcher.destroy()
  end
  return hurt
end

-- Fires a rocket from a launcher at a row and checks which of the
-- blast targets took damage against rule, a table of name = boolean.
local function landing(y, projectile, rule)
  local from, to = { 1100, y }, { 1120, y }
  Helpers.arena(surface(), to)
  local launcher = surface().create_entity({
    name = Names.LAUNCHER,
    position = from,
    force = "player",
  })
  local targets = blast_targets(to)
  fire(from, to, projectile, launcher)
  -- The pre-placed tamed monster plus the hatched one.
  once_landed(to, 2, 300, function(hatched)
    local hurt = settle(to, targets, launcher)
    assert(hatched, "the monster did not hatch within 300 ticks")
    for name, hit in pairs(rule) do
      assert(hurt[name] == hit, name .. (hit and " is untouched" or " is hurt"))
    end
  end)
end

test("an explosive landing hurts a native, a chest, a character, a tamed monster, a tree and a rock", function()
  landing(760, "ao-larva-projectile-biter-explosive", {
    native = true,
    tamed = true,
    chest = true,
    character = true,
    tree = true,
    rock = true,
  })
end)

test("a poison landing hurts a native, a character, a tamed monster and a tree, not a chest or a rock", function()
  landing(1220, "ao-larva-projectile-biter-poison", {
    native = true,
    tamed = true,
    character = true,
    tree = true,
    chest = false,
    rock = false,
  })
end)

test("an acid landing hurts a native, a chest, a character, a tamed monster and a tree, not a rock", function()
  landing(1260, "ao-larva-projectile-spitter-acid", {
    native = true,
    tamed = true,
    chest = true,
    character = true,
    tree = true,
    rock = false,
  })
end)

test("the blast of a rocket without a launcher still follows the payload", function()
  local from, to = { 1100, 780 }, { 1120, 780 }
  Helpers.arena(surface(), to)
  local targets = {
    native = surface().create_entity({
      name = "medium-biter",
      position = { to[1] + 1, to[2] },
      force = "enemy",
    }),
    chest = surface().create_entity({
      name = "wooden-chest",
      position = { to[1], to[2] + 1.5 },
      force = "player",
    }),
    rival = rival_chest({ to[1] - 1.5, to[2] + 1.5 }),
  }
  targets.native.disabled_by_script = true
  fire(from, to, "ao-larva-projectile-spitter-acid")
  once_landed(to, 1, 300, function(hatched)
    local hurt = settle(to, targets, nil)
    assert(hatched, "the monster did not hatch within 300 ticks")
    assert(hurt.native, "the native is untouched")
    assert(hurt.chest, "the player chest is untouched")
    assert(hurt.rival, "the rival chest is untouched")
  end)
end)
```

The rows 1220 and 1260 are free: the flare pair at 1140 reaches 1146.

- [ ] **Step 2: Run the in-game tests to watch them fail**

Run: `tools/ingame.sh base`

Expected: FAIL. The explosive landing leaves the chest, the character,
the tamed monster, the tree and the rock untouched. The no-launcher
test leaves the chest and the rival untouched.

- [ ] **Step 3: Write the code**

In `control.lua`, add the require after `local Setup = ...`:

```lua
local Damage = require("shell.damage")
```

Replace the function `blast` and its comment with:

```lua
-- The landing blast. It follows the rocket's payload: the payload's
-- targets and damage type, with the slice 3 amount and radius. The
-- launcher's force deals it and the launcher is the cause, so kills
-- count for it. With no launcher, the neutral force deals it.
local function blast(surface, position, launcher, payload)
  local live = launcher and launcher.valid and launcher or nil
  Damage.hit({
    surface = surface,
    position = position,
    radius = Balance.blast.radius,
    payload = payload.name,
    damage = Balance.blast.damage,
    force = live and live.force.name or "neutral",
    cause = live,
  })
end
```

In `land`, change the call to `blast(surface, position,
event.source_entity, payload)`.

In `core/forces.lua`, delete `Forces.blast_hits` and its comment. In
`spec/core/forces_spec.lua`, delete the tests "let the landing blast
hit only forces at war, never the tamed force" and the test that starts
"count only the natives". If `Forces` is now unused in
`control.lua`, luacheck says so: it stays in use by `nest_loot`.

- [ ] **Step 4: Run the tests to watch them pass**

Run: `tools/ingame.sh base`

Expected: the four landing tests pass, and the rest of the launcher
tests still pass.

Run: `make lua`

Expected: PASS.

- [ ] **Step 5: Commit**

Run `/ste80-humanizer` on the changed comments and `/simplify` (2
reviewers), then each as its own command:

```bash
make format
git add control.lua core/forces.lua spec/core/forces_spec.lua tests/ingame/launcher_test.lua
make stamp
git commit -m "feat: let the landing blast follow the payload's targets"
```

### Task 4: The detonation queue, the water landing and the explosive death

**Files:**

- Modify: `shell/damage.lua`
- Modify: `shell/setup.lua`
- Modify: `control.lua` (`land`, `set_off`, the `on_tick` handler)
- Modify: `tests/ingame/helpers.lua`
- Modify: `tests/ingame/damage_test.lua`
- Modify: `tests/ingame/launcher_test.lua` (the water test)
- Modify: `tests/ingame/ordnance_test.lua`
- Modify: `tests/ingame/feral_test.lua`

**Interfaces:**

- Consumes: `Payloads.on_death` plans (Task 1), `Damage.hit` (Task 2),
  `Trail.batch`, `FeralShell.force_of`.
- Produces: `Damage.queue`, `Damage.detonate`,
  `Damage.run_detonations`, `storage.detonations`,
  `storage.detonation_counter`, `Helpers.loaded_entry`.

- [ ] **Step 1: Write the failing in-game tests**

In `tests/ingame/helpers.lua`, add before `return Helpers`:

```lua
-- Hatches one small loaded biter at a position and passes its entry
-- to after(entry) a tick later. Evolution 0 makes it a small biter.
-- The unit stands still, so a test controls what happens to it.
function Helpers.loaded_entry(surface, position, item, after)
  Helpers.arena(surface, position, 40)
  game.forces["enemy"].set_evolution_factor(0, surface)
  Helpers.spoil(Helpers.spill(surface, position, item, 1))
  after_ticks(1, function()
    local units = Helpers.find_units(surface, position, { force = Names.TAMED })
    assert(#units == 1, #units .. " tamed units")
    local entry = storage.loaded[units[1].unit_number]
    assert(entry, "no loaded entry")
    entry.unit.disabled_by_script = true
    after(entry)
  end)
end
```

In `tests/ingame/feral_test.lua`, replace the body of the local
function `with_entry` with one call:

```lua
local function with_entry(position, item, after)
  Helpers.loaded_entry(surface(), position, item, after)
end
```

In `tests/ingame/damage_test.lua`, add these requires after
`local Damage = ...`:

```lua
local FeralShell = require("shell.feral")
local Names = require("core.names")
local Setup = require("shell.setup")
```

Append to the file:

```lua
local function hurt(entity)
  return not entity.valid or entity.health < entity.max_health
end

local function distance(a, b)
  local dx, dy = a.x - b.x, a.y - b.y
  return math.sqrt(dx * dx + dy * dy)
end

local function with_entry(position, item, after)
  Helpers.loaded_entry(surface(), position, item, after)
end

test("an explosive death hurts the same targets as its landing, once", function()
  with_entry({ 4060, 4000 }, "ao-biter-larva-explosive", function(entry)
    local p = entry.unit.position
    local targets = {
      native = surface().create_entity({
        name = "medium-biter",
        position = { p.x + 2, p.y },
        force = "enemy",
      }),
      chest = surface().create_entity({
        name = "steel-chest",
        position = { p.x, p.y + 2 },
        force = "player",
      }),
      tamed = surface().create_entity({
        name = "medium-biter",
        position = { p.x - 2, p.y },
        force = Names.TAMED,
      }),
      tree = surface().create_entity({ name = "tree-01", position = { p.x - 2, p.y + 2 } }),
      rock = surface().create_entity({ name = "big-rock", position = { p.x, p.y - 2.5 } }),
    }
    targets.native.disabled_by_script = true
    targets.tamed.disabled_by_script = true
    entry.unit.die()
    after_ticks(2, function()
      local first = {}
      for name, entity in pairs(targets) do
        first[name] = hurt(entity)
      end
      local chest_health = targets.chest.valid and targets.chest.health
      after_ticks(60, function()
        local once = targets.chest.valid and targets.chest.health == chest_health
        for _, entity in pairs(targets) do
          if entity.valid then
            entity.destroy()
          end
        end
        for name in pairs(targets) do
          assert(first[name], name .. " is untouched")
        end
        assert(once, "the chest took a second hit")
      end)
    end)
  end)
end)

test("the first of two explosive monsters kills the second through the queue", function()
  local position = { 4100, 4000 }
  Helpers.arena(surface(), position, 40)
  game.forces["enemy"].set_evolution_factor(0, surface())
  Helpers.spoil(Helpers.spill(surface(), position, "ao-biter-larva-explosive", 1))
  Helpers.spoil(Helpers.spill(surface(), { position[1] + 2.5, position[2] }, "ao-biter-larva-explosive", 1))
  after_ticks(1, function()
    local units = Helpers.find_units(surface(), position, { force = Names.TAMED })
    assert(#units == 2, #units .. " tamed units")
    table.sort(units, function(a, b)
      return a.position.x < b.position.x
    end)
    local first, second = units[1], units[2]
    first.disabled_by_script = true
    second.disabled_by_script = true
    -- Only the second death reaches the chest.
    local chest = Helpers.chest(surface(), { second.position.x + 3.5, second.position.y })
    local radius = Balance.payload_damage.explosive.radius
    assert(distance(first.position, chest.position) > radius, "precondition: the chest is in range of the first")
    assert(distance(first.position, second.position) <= radius, "precondition: the second is out of range")
    local ids = { first.unit_number, second.unit_number }
    first.die()
    after_ticks(3, function()
      local second_gone = not second.valid
      local chest_hurt = hurt(chest)
      local queue_empty = next(storage.detonations) == nil
      local entries_left = storage.loaded[ids[1]] ~= nil or storage.loaded[ids[2]] ~= nil
      if chest.valid then
        chest.destroy()
      end
      if second.valid then
        second.destroy()
      end
      assert(second_gone, "the first death did not kill the second monster")
      assert(chest_hurt, "the second death did not run")
      assert(queue_empty, "the queue still holds a detonation")
      assert(not entries_left, "a loaded entry is still there")
    end)
  end)
end)

test("a detonation for a force that a merge removed leaves the queue and deals no damage", function()
  local position = { 4140, 4000 }
  Helpers.arena(surface(), position)
  local gone = game.forces["ao-damage-gone"] or game.create_force("ao-damage-gone")
  local chest = Helpers.chest(surface(), { position[1] + 1, position[2] })
  Damage.queue(surface(), { x = position[1], y = position[2] }, { "explosive" }, gone.name)
  game.merge_forces(gone, "player")
  after_ticks(3, function()
    local whole = chest.valid and chest.health == chest.max_health
    local empty = next(storage.detonations) == nil
    chest.destroy()
    assert(whole, "the chest took damage from a gone force")
    assert(empty, "the detonation is still in the queue")
  end)
end)

test("a feral monster's explosive death kills a nest and drops no eggs", function()
  with_entry({ 4180, 4000 }, "ao-biter-larva-explosive", function(entry)
    FeralShell.go_feral(entry, game.tick)
    local p = entry.unit.position
    local spawner = surface().create_entity({
      name = "biter-spawner",
      position = { p.x + 3, p.y },
      force = "enemy",
    })
    spawner.disabled_by_script = true
    spawner.health = 10
    local spot = { spawner.position.x, spawner.position.y }
    entry.unit.die()
    after_ticks(3, function()
      local dead = not spawner.valid
      local eggs = Helpers.count_items(surface(), spot, "ao-biter-egg")
      if spawner.valid then
        spawner.destroy()
      end
      assert(dead, "the nest survived")
      assert(eggs == 0, eggs .. " eggs dropped")
    end)
  end)
end)

test("a configuration change creates the queue", function()
  local detonations, counter = storage.detonations, storage.detonation_counter
  storage.detonations = nil
  storage.detonation_counter = nil
  Setup.on_configuration_changed()
  local created = storage.detonations ~= nil and storage.detonation_counter == 0
  storage.detonations, storage.detonation_counter = detonations, counter
  assert(created, "the queue is missing after a configuration change")
end)
```

Add `local Balance = require("core.balance")` at the top of the file,
in alphabetical order with the other requires.

In `tests/ingame/launcher_test.lua`, replace the test "a larva rocket
that lands in water sets off its payload there" with:

```lua
test("a larva rocket that lands in water sets off its payload through the queue", function()
  local from, to = { 1100, 820 }, { 1130, 820 }
  Helpers.arena(surface(), to)
  local tiles = {}
  for x = -10, 10 do
    for y = -10, 10 do
      tiles[#tiles + 1] = { name = "deepwater", position = { to[1] + x, to[2] + y } }
    end
  end
  surface().set_tiles(tiles)
  local counter = storage.detonation_counter
  fire(from, to, "ao-larva-projectile-biter-poison")
  after_ticks(120, function()
    local queued = storage.detonation_counter - counter
    local clouds = surface().find_entities_filtered({
      position = to,
      radius = 6,
      name = "poison-cloud",
    })
    local force = clouds[1] and clouds[1].force.name
    for _, cloud in pairs(clouds) do
      cloud.destroy()
    end
    assert(#tamed_units(to) == 0, "a monster hatched in the water")
    assert(queued == 1, queued .. " detonations queued")
    assert(force == Names.TAMED, "the cloud belongs to " .. tostring(force))
  end)
end)
```

In `tests/ingame/ordnance_test.lua`, in the test "every payload effect
entity exists", change `payload.death.name` to `payload.death.entity`.

- [ ] **Step 2: Run the in-game tests to watch them fail**

Run: `tools/ingame.sh base`

Expected: FAIL. "an explosive death" fails with
`attempt to index field 'detonations' (a nil value)` or leaves the
chest untouched. The water test counts 0 detonations.

- [ ] **Step 3: Write the code**

In `shell/setup.lua`, replace `Setup.on_init` with:

```lua
function Setup.on_init()
  storage.loaded = storage.loaded or {}
  storage.trails = storage.trails or {}
  storage.detonations = storage.detonations or {}
  storage.detonation_counter = storage.detonation_counter or 0
  Tamed.ensure()
end
```

In `shell/damage.lua`, add before `return Damage`:

```lua
-- Adds one detonation per payload to the queue. force is a force name.
function Damage.queue(surface, position, payloads, force)
  for _, payload in ipairs(payloads) do
    storage.detonation_counter = storage.detonation_counter + 1
    storage.detonations[storage.detonation_counter] = {
      surface = surface.index,
      position = { x = position.x, y = position.y },
      payload = payload,
      force = force,
    }
  end
end

-- Runs one detonation: the death effect of one payload. A detonation
-- whose surface or force is gone does nothing. A hit has no cause,
-- because the monster no longer exists.
function Damage.detonate(d)
  local surface = game.get_surface(d.surface)
  if not (surface and game.forces[d.force]) then
    return
  end
  for _, plan in ipairs(Payloads.on_death({ d.payload }, d.position, entity_exists)) do
    for _, entity in ipairs(plan.entities) do
      entity.force = d.force
      surface.create_entity(entity)
    end
    if plan.hit then
      Damage.hit({
        surface = surface,
        position = d.position,
        radius = plan.hit.radius,
        payload = plan.payload,
        damage = plan.hit.damage,
        force = d.force,
      })
    end
  end
end

-- Runs up to detonation_batch detonations. Each one leaves the queue
-- before it runs, so a detonation that kills more loaded monsters only
-- adds to the queue and never recurses.
function Damage.run_detonations()
  local ids = Trail.batch(storage.detonations, nil, Balance.payload_damage.detonation_batch)
  for _, id in ipairs(ids) do
    local d = storage.detonations[id]
    storage.detonations[id] = nil
    Damage.detonate(d)
  end
end
```

In `control.lua`, replace the end of `land` (from the `for _, effect`
loop) with:

```lua
  -- No free spot, for example water: the payload goes off through the
  -- queue, as the death effect of the monster that could not appear.
  Damage.queue(surface, position, { payload.name }, Names.TAMED)
```

Replace `set_off` and its comment with:

```lua
-- A loaded monster sets off its payloads where it dies. Each one goes
-- into the detonation queue, so a death that kills more loaded monsters
-- never recurses.
local function set_off(entity)
  local entry = storage.loaded[entity.unit_number]
  if not entry then
    return
  end
  Damage.queue(entity.surface, entity.position, entry.payloads, FeralShell.force_of(entry))
end
```

In the `on_tick` handler, add `Damage.run_detonations()` as the first
line, before `trail_tick(event.tick)`.

Delete the local function `entity_exists` from `control.lua` if
nothing else uses it. `spawn` still calls `Hatching.available(units,
entity_exists)`, so it stays.

- [ ] **Step 4: Run the tests to watch them pass**

Run: `make fast`

Expected: every gate passes.

Run: `make ingame`

Expected: every in-game test passes in both modes. The ordnance test
"an explosive monster that dies blows up the natives' chest" still
passes: the hit lands in the tick after the death, within its
`after_ticks(2)`.

- [ ] **Step 5: Commit**

Run `/ste80-humanizer` on the changed comments and `/simplify` (4
reviewers), then each as its own command:

```bash
make format
git add shell/damage.lua shell/setup.lua control.lua tests/ingame/helpers.lua tests/ingame/damage_test.lua tests/ingame/launcher_test.lua tests/ingame/ordnance_test.lua tests/ingame/feral_test.lua
make stamp
git commit -m "feat: run payload deaths through a detonation queue"
```

### Task 5: Architecture doc, changelog and PR 1

**Files:**

- Modify: `docs/architecture.md`
- Modify: `CHANGELOG.md`

**Interfaces:**

- Consumes: Tasks 1 to 4.
- Produces: PR 1.

- [ ] **Step 1: Update the architecture example**

In `docs/architecture.md`, in "The shell", replace the sentence that
starts "The full code is" and the two code blocks after it. The new
text has a sentence, a code block, a sentence and a code block.

The first sentence: "The full code is `Payloads.on_death` in
`core/payloads.lua` and `Damage.detonate` in `shell/damage.lua`. The
core returns one plan per payload as data:"

The first code block:

```lua
-- core: a pure function
function Payloads.on_death(names, position, exists)
  -- Returns one plan per payload: the entities to create, and the hit
  -- or the hazard for the shell to deal.
end
```

The second sentence: "The shell reads the detonation from `storage`,
calls the core, adds the force, creates the entities and deals the
hit:"

The second code block:

```lua
-- shell: shell/damage.lua
for _, plan in ipairs(Payloads.on_death({ d.payload }, d.position, entity_exists)) do
  for _, entity in ipairs(plan.entities) do
    entity.force = d.force
    surface.create_entity(entity)
  end
  if plan.hit then
    Damage.hit({ surface = surface, position = d.position, payload = plan.payload, ... })
  end
end
```

In the same section, extend the example list of `shell/` with
`shell/damage.lua`: "for example the force setup in `shell/tamed.lua`
and the payload damage in `shell/damage.lua`".

`spec/docs_spec.lua` reads only the "never names" paragraph, so the
change needs no test change. Run `BUSTED spec/docs_spec.lua` to
check it.

- [ ] **Step 2: Write the changelog**

Under `## [Unreleased]` in `CHANGELOG.md`, add a `### Changed` section
above `### Fixed` (create the heading if it does not exist):

```markdown
### Changed

- Each payload decides what its landing blast and its death effect
  hurt, with its own damage type. Explosive hurts everything, rocks
  included. Poison hurts living things only. Acid hurts everything
  except rocks. Your own buildings, your character and tamed monsters
  count too, so an explosive death next to your wall damages the wall.
- An explosive death is one hit of 150 explosion damage in a 4-tile
  radius. A rocket that lands in water sets its payload off in the same
  way. Vanilla resistances still apply.
- Deaths run through a queue of at most 5 per tick, so a chain of
  deaths never stalls the game.
```

If a probe row fell back to the `enemy` force, add: "Kills of
(the failed pair) count for the natives and drop no nest loot."

- [ ] **Step 3: Run everything**

Run: `make check`

Expected: PASS in both modes.

- [ ] **Step 4: Commit**

Run `/ste80-humanizer` on the changed prose, then each as its own
command:

```bash
git add docs/architecture.md CHANGELOG.md
make stamp
git commit -m "docs: describe the death plans and the payload targets"
```

- [ ] **Step 5: Review, push and open PR 1**

Run `/simplify` with 4 reviewers on the branch. Then run the code
review angles from `CLAUDE.md`: multiplayer safety (`control.lua`,
`shell/`, `storage`), save compatibility (the new `storage` fields),
mod compatibility (a modded creature without `breaths-air`, a removed
`big-explosion`), performance (the `on_tick` queue), test quality
(`spec/`, `tests/`). Fix every Critical and Important finding with a
test that fails first. Review again, for at most 3 rounds.

```bash
git push -u origin feat/payload-targets
```

```bash
gh pr create --title "feat: let payload damage follow the payload" --body-file <body file>
```

The body has `## What changes`, the probe table's outcome in one line
per failed row, and `## Review angles` with one verdict per angle:

```markdown
## Review angles

- Multiplayer safety: pass
- Save compatibility: pass
- Mod compatibility: pass
- Performance (UPS): pass
- Test quality: pass
- Security: n/a
```

End the body with
`🤖 Generated with [Claude Code](https://claude.com/claude-code)`.

```bash
gh pr merge --auto --squash
```

Wait for `all-checks` to pass and the PR to merge before PR 2 starts
from `main`.

---

## PR 2: hazards

Branch `feat/payload-hazards` from `main` after PR 1 merges. Read the
ledger rulings of PR 1 first: a probe fallback can change `Damage.hit`.

### Task 6: The hazard rules (core)

**Files:**

- Create: `core/hazards.lua`
- Create: `spec/core/hazards_spec.lua`

**Interfaces:**

- Consumes: `Trail.batch`.
- Produces: `Hazards.new`, `Hazards.due` and `Hazards.plan` from the
  interface sheet. Task 8 calls them.

- [ ] **Step 1: Write the failing tests**

Create `spec/core/hazards_spec.lua`:

```lua
local Hazards = require("core.hazards")

-- Small budgets, so a test can hit them with a few hazards.
local N = { hazard_interval = 30, hazard_hits = 2, hazard_visits = 3 }

-- n hazards, each due at tick 100 unless last_hit says otherwise.
local function hazards(n, last_hit)
  local t = {}
  for i = 1, n do
    t[i] = { last_hit = last_hit or 70, end_tick = 1000 }
  end
  return t
end

describe("a new hazard", function()
  it("has its first hit due at once and ends after its ticks", function()
    local p = { x = 1, y = 2 }
    local h = Hazards.new(1, p, "poison", "ao-tamed", 100, 1200, 30)
    assert.are.same({
      surface = 1,
      position = { x = 1, y = 2 },
      payload = "poison",
      force = "ao-tamed",
      last_hit = 70,
      end_tick = 1300,
    }, h)
    assert.are_not.equal(p, h.position)
    assert.are.equal(1, Hazards.due(h, 100, 30))
  end)
end)

describe("the due hits", function()
  local h = { last_hit = 100, end_tick = 400 }

  it("count no hit before a whole interval", function()
    assert.are.equal(0, Hazards.due(h, 129, 30))
  end)

  it("count one hit after one interval", function()
    assert.are.equal(1, Hazards.due(h, 130, 30))
  end)

  it("catch up on every whole interval of a late visit", function()
    assert.are.equal(3, Hazards.due(h, 195, 30))
  end)

  it("stop counting at the end tick", function()
    assert.are.equal(10, Hazards.due(h, 5000, 30))
  end)
end)

describe("the hazard pass", function()
  it("hits each due hazard and moves its last hit", function()
    local plan = Hazards.plan(hazards(2), nil, 100, N)
    assert.are.same({
      { id = 1, count = 1, last_hit = 100 },
      { id = 2, count = 1, last_hit = 100 },
    }, plan.hits)
    assert.are.same({}, plan.done)
    assert.is_nil(plan.cursor)
  end)

  it("stops at hazard_hits and resumes at the first hazard it did not hit", function()
    local t = hazards(3)
    local first = Hazards.plan(t, nil, 100, N)
    assert.are.equal(2, #first.hits)
    assert.are.equal(3, first.cursor)
    for _, h in ipairs(first.hits) do
      t[h.id].last_hit = h.last_hit
    end
    local second = Hazards.plan(t, first.cursor, 101, N)
    assert.are.same({ { id = 3, count = 1, last_hit = 100 } }, second.hits)
    assert.is_nil(second.cursor)
  end)

  it("stops at hazard_visits, also with no hit", function()
    local plan = Hazards.plan(hazards(5, 90), nil, 100, N)
    assert.are.same({}, plan.hits)
    assert.are.equal(4, plan.cursor)
  end)

  it("never visits a hazard twice in one tick", function()
    local wide = { hazard_interval = 30, hazard_hits = 10, hazard_visits = 10 }
    local plan = Hazards.plan(hazards(2), 2, 100, wide)
    assert.are.same({ { id = 2, count = 1, last_hit = 100 } }, plan.hits)
    assert.is_nil(plan.cursor)
  end)

  it("deals the last hits of a hazard past its end, then lets it go", function()
    local t = { { last_hit = 940, end_tick = 1000 } }
    local plan = Hazards.plan(t, nil, 1010, N)
    assert.are.same({ { id = 1, count = 2, last_hit = 1000 } }, plan.hits)
    assert.are.same({ 1 }, plan.done)
  end)

  it("lets a finished hazard go without a hit", function()
    local t = { { last_hit = 1000, end_tick = 1000 } }
    local plan = Hazards.plan(t, nil, 1005, N)
    assert.are.same({}, plan.hits)
    assert.are.same({ 1 }, plan.done)
  end)

  it("does nothing for no hazards", function()
    assert.are.same({ hits = {}, done = {} }, Hazards.plan({}, nil, 100, N))
  end)
end)
```

- [ ] **Step 2: Run the tests to watch them fail**

Run: `BUSTED spec/core/hazards_spec.lua`

Expected: FAIL with `module 'core.hazards' not found`.

- [ ] **Step 3: Write the module**

Create `core/hazards.lua`:

```lua
-- The rules of the hazard pass: a new hazard, the hits that are due, and
-- the visits and hits of one tick within the budget. Pure: it reads only
-- its parameters. shell/damage.lua deals the hits.
local Trail = require("core.trail")

local Hazards = {}

-- A hazard of a payload at a position. Its first hit is due at tick,
-- and it ends ticks later. force is a force name.
function Hazards.new(surface, position, payload, force, tick, ticks, interval)
  return {
    surface = surface,
    position = { x = position.x, y = position.y },
    payload = payload,
    force = force,
    last_hit = tick - interval,
    end_tick = tick + ticks,
  }
end

-- The whole intervals since the hazard's last hit, up to its end tick.
function Hazards.due(hazard, tick, interval)
  local now = math.min(tick, hazard.end_tick)
  return math.max(math.floor((now - hazard.last_hit) / interval), 0)
end

-- One tick of the pass. It visits at most hazard_visits hazards from the
-- cursor on and deals at most hazard_hits hits. A visit with a due hit
-- sums the due intervals into one hit. Returns the hits, the hazards
-- that end, and the cursor for the next tick. When the hits run out,
-- the cursor is the first hazard that did not get its hit.
function Hazards.plan(hazards, cursor, tick, numbers)
  local interval = numbers.hazard_interval
  local ids, next_cursor = Trail.batch(hazards, cursor, numbers.hazard_visits)
  local out = { hits = {}, done = {}, cursor = next_cursor }
  for _, id in ipairs(ids) do
    local hazard = hazards[id]
    local count = Hazards.due(hazard, tick, interval)
    if count > 0 then
      if #out.hits == numbers.hazard_hits then
        out.cursor = id
        return out
      end
      out.hits[#out.hits + 1] = {
        id = id,
        count = count,
        last_hit = hazard.last_hit + count * interval,
      }
    end
    if tick >= hazard.end_tick then
      out.done[#out.done + 1] = id
    end
  end
  return out
end

return Hazards
```

- [ ] **Step 4: Run the tests to watch them pass**

Run: `BUSTED spec/core/hazards_spec.lua spec/architecture_spec.lua`

Expected: PASS, 0 failures. The architecture spec finds no game global
in `core/hazards.lua`.

- [ ] **Step 5: Commit**

Run `/ste80-humanizer` on the new comments and `/simplify` (2
reviewers), then each as its own command:

```bash
make format
git add core/hazards.lua spec/core/hazards_spec.lua
make stamp
git commit -m "feat: add the hazard rules"
```

### Task 7: The look-alikes and the hazard plans (core and data stage)

**Files:**

- Modify: `core/names.lua`
- Modify: `core/payloads.lua`
- Modify: `core/prototypes/ordnance.lua`
- Modify: `data.lua`
- Modify: `spec/support/stubs.lua`
- Modify: `spec/core/payloads_spec.lua`
- Modify: `spec/core/prototypes/ordnance_spec.lua`
- Modify: `tests/ingame/ordnance_test.lua`
- Modify: `tests/ingame/launcher_test.lua`
- Modify: `tests/ingame/feral_test.lua`

**Interfaces:**

- Consumes: `Balance.payload_damage` (Task 1), `Common.copy`.
- Produces: `Names.CLOUD`, `Names.POOL`, the prototypes
  `smoke-with-trigger/ao-poison-cloud` and `fire/ao-acid-pool`, and a
  `hazard = { ticks }` in the poison and acid death plans.

- [ ] **Step 1: Write the failing tests**

In `spec/support/stubs.lua`, add two fields to the table that
`Stubs.ordnance_opts` returns, after `projectile = { ... },`:

```lua
    cloud = {
      type = "smoke-with-trigger",
      name = "poison-cloud",
      animation = { filename = "cloud.png" },
      duration = 1200,
      action = { type = "direct" },
      action_cooldown = 30,
    },
    pool = {
      type = "fire",
      name = "acid-splash-fire-spitter-big",
      pictures = { { filename = "pool.png" } },
      damage_per_tick = { amount = 0, type = "acid" },
      on_damage_tick_effect = { type = "direct" },
      maximum_spread_count = 100,
      initial_lifetime = 1920,
      maximum_lifetime = 1920,
      lifetime_increase_by = 20,
    },
```

Append to `spec/core/prototypes/ordnance_spec.lua`:

```lua
describe("the look-alikes", function()
  local function build_with(opts)
    return Stubs.by_name((Ordnance.prototypes(opts)))
  end

  it("copy the vanilla cloud's looks, with no action, for the cloud's time", function()
    local c = build()["smoke-with-trigger/ao-poison-cloud"]
    assert.are.equal("cloud.png", c.animation.filename)
    assert.is_nil(c.action)
    assert.are.equal(0, c.action_cooldown)
    assert.are.equal(1200, c.duration)
  end)

  it("copy the vanilla pool's looks, with no damage, no spread and the pool's time", function()
    local p = build()["fire/ao-acid-pool"]
    assert.are.equal("pool.png", p.pictures[1].filename)
    assert.is_nil(p.on_damage_tick_effect)
    assert.are.equal(0, p.damage_per_tick.amount)
    assert.are.equal(0, p.maximum_spread_count)
    assert.are.equal(900, p.initial_lifetime)
    assert.are.equal(900, p.maximum_lifetime)
    assert.are.equal(0, p.lifetime_increase_by)
  end)

  it("leave the vanilla prototypes unchanged", function()
    local opts = Stubs.ordnance_opts()
    build_with(opts)
    assert.are.same({ type = "direct" }, opts.cloud.action)
    assert.are.same({ type = "direct" }, opts.pool.on_damage_tick_effect)
  end)

  it("skip a look-alike whose vanilla prototype is missing", function()
    local opts = Stubs.ordnance_opts()
    opts.cloud = nil
    local all = build_with(opts)
    assert.is_nil(all["smoke-with-trigger/ao-poison-cloud"])
    assert.truthy(all["fire/ao-acid-pool"])
  end)
end)
```

In `spec/core/payloads_spec.lua`, in `describe("the death plans", ...)`,
replace the tests "leave a vanilla poison cloud for a poison payload"
and "spread five vanilla acid puddles for an acid payload" with:

```lua
  it("leave a cloud look-alike and a hazard for a poison payload", function()
    assert.are.same({
      {
        payload = "poison",
        entities = { { name = "ao-poison-cloud", position = p } },
        hazard = { ticks = 1200 },
      },
    }, Payloads.on_death({ "poison" }, p, all))
  end)

  it("spread five pool look-alikes with one hazard for an acid payload", function()
    local d = Balance.acid_spread
    local plan = Payloads.on_death({ "acid" }, p, all)[1]
    assert.are.equal("acid", plan.payload)
    assert.is_nil(plan.hit)
    assert.are.same({ ticks = 900 }, plan.hazard)
    local spots = {}
    for _, e in ipairs(plan.entities) do
      assert.are.equal("ao-acid-pool", e.name)
      spots[#spots + 1] = (e.position.x - 10) / d .. "," .. (e.position.y - 20) / d
    end
    table.sort(spots)
    assert.are.same({ "-1,0", "0,-1", "0,0", "0,1", "1,0" }, spots)
  end)

  it("keep the hazard when the look-alike's prototype is missing", function()
    local function none()
      return false
    end
    local plan = Payloads.on_death({ "poison" }, p, none)[1]
    assert.are.same({}, plan.entities)
    assert.are.same({ ticks = 1200 }, plan.hazard)
  end)
```

- [ ] **Step 2: Run the tests to watch them fail**

Run: `BUSTED spec/core/payloads_spec.lua spec/core/prototypes/ordnance_spec.lua`

Expected: FAIL. The plans still name the vanilla cloud and puddles and
have no hazard, and the look-alike prototypes do not exist.

- [ ] **Step 3: Write the code**

In `core/names.lua`, add after `FERAL = "ao-feral",`:

```lua
  CLOUD = "ao-poison-cloud",
  POOL = "ao-acid-pool",
```

In `core/payloads.lua`, add `local Names = require("core.names")` to
the requires, in alphabetical order. In `Payloads.ALL`, change the
acid death to:

```lua
    -- One pool hurts only what stands in it, so the death spreads five
    -- look-alikes. One hazard covers them.
    death = { entity = Names.POOL, spread = true, hazard = true },
```

and the poison death to:

```lua
    death = { entity = Names.CLOUD, hazard = true },
```

In `Payloads.on_death`, after the `if payload.death.hit then ... end`
block, add:

```lua
      if payload.death.hazard then
        plan.hazard = { ticks = Balance.payload_damage[name].ticks }
      end
```

Change the comment above `Payloads.on_death` to say: "carries the
script hit (hit) or the hazard (hazard) when the payload has one".

In `core/prototypes/ordnance.lua`, add before `Ordnance.prototypes`:

```lua
-- A look-alike copies a vanilla effect. It shows the same picture and
-- deals no damage of its own: shell/damage.lua deals the damage. Each
-- returns nil when another mod removed the vanilla prototype.

-- The poison cloud, for as long as its hazard lasts.
local function cloud(vanilla)
  if not vanilla then
    return nil
  end
  local p = Common.copy(vanilla)
  p.name = Names.CLOUD
  p.hidden = true
  p.action = nil
  p.action_cooldown = 0
  p.duration = Balance.payload_damage.poison.ticks
  return p
end

-- An acid puddle that never spreads. With a lifetime, it lasts exactly
-- that long. Without one, it keeps the vanilla lifetime.
local function puddle(vanilla, name, lifetime)
  if not vanilla then
    return nil
  end
  local p = Common.copy(vanilla)
  p.name = name
  p.hidden = true
  p.damage_per_tick = { amount = 0, type = "acid" }
  p.on_damage_tick_effect = nil
  p.maximum_spread_count = 0
  if lifetime then
    p.initial_lifetime = lifetime
    p.maximum_lifetime = lifetime
    p.lifetime_increase_by = 0
  end
  return p
end

-- The look-alikes whose vanilla prototype exists.
local function lookalikes(opts)
  local out = {}
  for _, p in pairs({
    cloud(opts.cloud),
    puddle(opts.pool, Names.POOL, Balance.payload_damage.acid.ticks),
  }) do
    out[#out + 1] = p
  end
  table.sort(out, function(a, b)
    return a.name < b.name
  end)
  return out
end
```

`pairs` skips the nil holes of a missing look-alike, and the sort
keeps the order the same on every machine. In `Ordnance.prototypes`,
add `lookalikes(opts)` to the list of lists it appends, after
`loading_recipes`. Extend the comment above `Ordnance.prototypes`:
"They also hold the vanilla poison cloud and big acid puddle, which
the look-alikes copy. Either can be nil."

In `data.lua`, add after the function `vanilla`:

```lua
-- The look-alikes copy these vanilla effects. Another mod can remove
-- them. Then the effect shows nothing, and the damage still applies.
local function optional(kind, name)
  return (data.raw[kind] or {})[name]
end
```

and pass two more fields to `Ordnance.prototypes`:

```lua
  cloud = optional("smoke-with-trigger", "poison-cloud"),
  pool = optional("fire", "acid-splash-fire-spitter-big"),
```

The in-game tests that look for the vanilla cloud now look for the
look-alike. Add `local Names = require("core.names")` to each file
that lacks it, then:

- In `tests/ingame/launcher_test.lua`, in the test "a larva rocket
  that lands in water sets off its payload through the queue", change
  `name = "poison-cloud"` to `name = Names.CLOUD`.
- In `tests/ingame/feral_test.lua`, in the test "a feral monster's
  payload belongs to the feral force", change `name = "poison-cloud"`
  to `name = Names.CLOUD`.
- In `tests/ingame/ordnance_test.lua`, in the test "a native biter that
  dies sets off nothing", change the name list to
  `{ "big-explosion", Names.CLOUD, Names.POOL }`.

- [ ] **Step 4: Run the tests to watch them pass**

Run: `make fast`

Expected: every gate passes.

Run: `make ingame`

Expected: every in-game test passes in both modes. Poison and acid
deaths now show the look-alikes and deal no damage until Task 8. No
test before Task 8 checks that damage.

- [ ] **Step 5: Commit**

Run `/ste80-humanizer` on the changed comments and `/simplify` (2
reviewers), then each as its own command:

```bash
make format
git add core/names.lua core/payloads.lua core/prototypes/ordnance.lua data.lua spec/support/stubs.lua spec/core/payloads_spec.lua spec/core/prototypes/ordnance_spec.lua tests/ingame/ordnance_test.lua tests/ingame/launcher_test.lua tests/ingame/feral_test.lua
make stamp
git commit -m "feat: add the cloud and pool look-alikes"
```

### Task 8: The hazard pass (shell)

**Files:**

- Modify: `shell/damage.lua`
- Modify: `shell/setup.lua`
- Modify: `control.lua` (the `on_tick` handler)
- Modify: `tests/ingame/damage_test.lua`

**Interfaces:**

- Consumes: `Hazards.new`, `Hazards.plan` (Task 6), the hazard plans
  (Task 7), `Damage.hit`, `Trail.forget`.
- Produces: `Damage.run_hazards(tick)`, `storage.hazards`,
  `storage.hazard_counter`, `storage.hazard_cursor`.

- [ ] **Step 1: Write the failing in-game tests**

In `tests/ingame/damage_test.lua`, add
`local Hazards = require("core.hazards")` to the requires, in
alphabetical order. Append:

```lua
-- The ids of the stored hazards of a payload within 1 tile of a spot.
local function hazards_at(p, payload)
  local ids = {}
  for id, h in pairs(storage.hazards) do
    if h.payload == payload and distance(h.position, p) <= 1 then
      ids[#ids + 1] = id
    end
  end
  return ids
end

-- Adds a hazard to storage as a detonation would, and returns its id.
local function add_hazard(spot, payload, ticks)
  local d = Balance.payload_damage
  storage.hazard_counter = storage.hazard_counter + 1
  local id = storage.hazard_counter
  storage.hazards[id] =
    Hazards.new(surface().index, spot, payload, Names.TAMED, game.tick, ticks, d.hazard_interval)
  return id
end

local function destroy_all(entities)
  for _, entity in pairs(entities) do
    if entity.valid then
      entity.destroy()
    end
  end
end

test("a poison death leaves a cloud that hurts a native for its time, then stops", function()
  with_entry({ 4220, 4000 }, "ao-biter-larva-poison", function(entry)
    local p = entry.unit.position
    local native = surface().create_entity({
      name = "big-biter",
      position = { p.x + 3, p.y },
      force = "enemy",
    })
    native.disabled_by_script = true
    local max = native.max_health
    entry.unit.die()
    after_ticks(2, function()
      local ids = hazards_at(p, "poison")
      local clouds = surface().find_entities_filtered({ name = Names.CLOUD, position = p, radius = 2 })
      local first = native.health
      -- Shorten the cloud: its last hit falls within 60 ticks.
      if ids[1] then
        storage.hazards[ids[1]].end_tick = game.tick + 60
      end
      after_ticks(90, function()
        local second = native.health
        local gone = ids[1] ~= nil and storage.hazards[ids[1]] == nil
        after_ticks(60, function()
          local third = native.health
          destroy_all(clouds)
          native.destroy()
          assert(#ids == 1, #ids .. " poison hazards")
          assert(#clouds >= 1, "no cloud look-alike")
          assert(first < max, "the first hit did not land")
          assert(second < first, "the cloud stopped too early")
          assert(gone, "the hazard outlived its end tick")
          assert(third == second, "the cloud hurt after its end")
        end)
      end)
    end)
  end)
end)

test("an acid death leaves five pool look-alikes and one hazard that hurts a chest", function()
  with_entry({ 4260, 4000 }, "ao-biter-larva-acid", function(entry)
    local p = entry.unit.position
    local chest = Helpers.chest(surface(), { p.x + 2, p.y + 1 })
    entry.unit.die()
    after_ticks(2, function()
      local pools = surface().find_entities_filtered({ name = Names.POOL, position = p, radius = 3 })
      local ids = hazards_at(p, "acid")
      local chest_hurt = hurt(chest)
      destroy_all(pools)
      chest.destroy()
      for _, id in ipairs(ids) do
        storage.hazards[id] = nil
      end
      assert(#pools == 5, #pools .. " pool look-alikes")
      assert(#ids == 1, #ids .. " acid hazards")
      assert(chest_hurt, "the pool did not hurt the chest")
    end)
  end)
end)

test("with more hazards than hazard_hits, each hazard still deals its full damage", function()
  local position = { 4340, 4000 }
  Helpers.arena(surface(), position, 64)
  local d = Balance.payload_damage
  -- Three hits each: the first at once, then one per interval.
  local ticks = 2 * d.hazard_interval
  local reference = Helpers.chest(surface(), { position[1], position[2] + 12 })
  for _ = 1, 3 do
    reference.damage(d.acid.damage, Names.TAMED, "acid")
  end
  local full = reference.max_health - reference.health
  reference.destroy()
  local chests, ids = {}, {}
  for i = 1, d.hazard_hits + 2 do
    local spot = { x = position[1] - 56 + 8 * i, y = position[2] }
    chests[i] = Helpers.chest(surface(), spot)
    ids[i] = add_hazard(spot, "acid", ticks)
  end
  after_ticks(ticks + 30, function()
    local losses, left = {}, 0
    for i, chest in ipairs(chests) do
      losses[i] = chest.max_health - chest.health
      left = left + (storage.hazards[ids[i]] and 1 or 0)
    end
    destroy_all(chests)
    assert(left == 0, left .. " hazards outlived their end")
    for i, loss in ipairs(losses) do
      assert(loss >= full - 0.01, "chest " .. i .. " lost " .. loss .. ", expected " .. full)
    end
  end)
end)

test("a hazard whose payload the mod no longer knows leaves without damage", function()
  local position = { 4420, 4000 }
  Helpers.arena(surface(), position)
  local chest = Helpers.chest(surface(), { position[1] + 1, position[2] })
  local id = add_hazard({ x = position[1], y = position[2] }, "glitter", 600)
  after_ticks(3, function()
    local whole = chest.health == chest.max_health
    local gone = storage.hazards[id] == nil
    chest.destroy()
    assert(whole, "the unknown hazard hurt the chest")
    assert(gone, "the unknown hazard is still stored")
  end)
end)

test("a configuration change creates the hazard table", function()
  local hazards, counter = storage.hazards, storage.hazard_counter
  storage.hazards = nil
  storage.hazard_counter = nil
  Setup.on_configuration_changed()
  local created = storage.hazards ~= nil and storage.hazard_counter == 0
  storage.hazards, storage.hazard_counter = hazards, counter
  assert(created, "the hazard table is missing after a configuration change")
end)

tags("space-age")
test("poison hurts a Gleba plant and a demolisher", function()
  local position = { 4460, 4000 }
  Helpers.arena(surface(), position, 48)
  local plant = surface().create_entity({
    name = "yumako-tree",
    position = { position[1], position[2] },
  })
  local worm = surface().create_entity({
    name = "small-demolisher",
    position = { position[1] + 24, position[2] },
    force = "enemy",
  })
  local function poison(entity)
    Damage.hit({
      surface = surface(),
      position = entity.position,
      radius = 3,
      payload = "poison",
      damage = 100,
      force = Names.TAMED,
    })
  end
  poison(plant)
  local plant_hurt = hurt(plant)
  local worm_hurt = false
  if worm then
    poison(worm)
    worm_hurt = hurt(worm)
  end
  destroy_all({ plant, worm })
  assert(worm, "no demolisher on Nauvis: see decision 17")
  assert(plant_hurt, "poison spared the Gleba plant")
  assert(worm_hurt, "poison spared the demolisher")
end)
```

The demolisher test follows decision 17. If `create_entity` returns
nil on Nauvis, create the Vulcanus surface and place the demolisher
there, and record it in the ledger. A demolisher's segments pass their
damage to its head, so the test reads the head's health. If the head
takes no poison damage, record why in the ledger before you change the
test.

- [ ] **Step 2: Run the in-game tests to watch them fail**

Run: `tools/ingame.sh`

Expected: FAIL. The poison and acid tests find no hazard, and the
others fail on the `nil` `storage.hazards`. The Space Age test may
pass already, because `Damage.hit` exists since Task 2. It pins the
class sets in Space Age.

- [ ] **Step 3: Write the code**

In `shell/setup.lua`, add to `Setup.on_init`, after the two
`detonation` lines:

```lua
  storage.hazards = storage.hazards or {}
  storage.hazard_counter = storage.hazard_counter or 0
```

In `shell/damage.lua`, add `local Hazards = require("core.hazards")`
to the requires. In `Damage.detonate`, after the
`if plan.hit then ... end` block, add:

```lua
    if plan.hazard then
      start_hazard(d, plan)
    end
```

Add above `Damage.detonate`:

```lua
-- Stores the hazard of a plan. Its first hit is due at once, so the
-- hazard pass deals it within its budget.
local function start_hazard(d, plan)
  storage.hazard_counter = storage.hazard_counter + 1
  storage.hazards[storage.hazard_counter] = Hazards.new(
    d.surface,
    d.position,
    plan.payload,
    d.force,
    game.tick,
    plan.hazard.ticks,
    Balance.payload_damage.hazard_interval
  )
end
```

Add before `return Damage`:

```lua
-- Deals the summed hits of one hazard visit. Returns false when the
-- hazard's surface, force or payload is gone, so the hazard must leave.
local function hazard_hit(hazard, count)
  local surface = game.get_surface(hazard.surface)
  local n = Payloads.numbers(hazard.payload)
  if not (surface and game.forces[hazard.force] and n) then
    return false
  end
  Damage.hit({
    surface = surface,
    position = hazard.position,
    radius = n.radius,
    payload = hazard.payload,
    damage = n.damage * count,
    force = hazard.force,
  })
  return true
end

local function remove_hazard(id)
  if storage.hazards[id] then
    storage.hazard_cursor = Trail.forget(storage.hazards, storage.hazard_cursor, id)
    storage.hazards[id] = nil
  end
end

-- One tick of the hazard pass. core/hazards.lua picks the visits and
-- the hits within the budget. This function deals the hits and removes
-- the hazards that end.
function Damage.run_hazards(tick)
  local plan = Hazards.plan(storage.hazards, storage.hazard_cursor, tick, Balance.payload_damage)
  storage.hazard_cursor = plan.cursor
  for _, h in ipairs(plan.hits) do
    local hazard = storage.hazards[h.id]
    hazard.last_hit = h.last_hit
    if not hazard_hit(hazard, h.count) then
      remove_hazard(h.id)
    end
  end
  for _, id in ipairs(plan.done) do
    remove_hazard(id)
  end
end
```

A hit can kill a loaded monster. Its death only adds to
`storage.detonations`, so `storage.hazards` gains no key while the
pass walks it.

In `control.lua`, in the `on_tick` handler, add
`Damage.run_hazards(event.tick)` right after
`Damage.run_detonations()`. A detonation in this tick then gets its
first hit in the same tick.

- [ ] **Step 4: Run the tests to watch them pass**

Run: `make fast`

Expected: every gate passes.

Run: `make ingame`

Expected: every in-game test passes in both modes.

- [ ] **Step 5: Commit**

Run `/ste80-humanizer` on the changed comments and `/simplify` (4
reviewers), then each as its own command:

```bash
make format
git add shell/damage.lua shell/setup.lua control.lua tests/ingame/damage_test.lua
make stamp
git commit -m "feat: let poison clouds and acid pools hurt as hazards"
```

### Task 9: Changelog and PR 2

**Files:**

- Modify: `CHANGELOG.md`

**Interfaces:**

- Consumes: Tasks 6 to 8.
- Produces: PR 2.

- [ ] **Step 1: Write the changelog**

Under `## [Unreleased]`, `### Changed`, add:

```markdown
- A poison death leaves a cloud for 20 s that hurts living things
  within 11 tiles: natives, your character, tamed monsters and trees.
  An acid death leaves pools for 15 s that hurt everything except
  rocks within 3 tiles, your buildings included. Each hits every
  0.5 s.
- At most 10 cloud and pool hits run per tick. Above that, a cloud
  hits less often but catches up, so its total damage stays the same.
```

- [ ] **Step 2: Run everything**

Run: `make check`

Expected: PASS in both modes.

- [ ] **Step 3: Commit**

Run `/ste80-humanizer` on the changed prose, then each as its own
command:

```bash
git add CHANGELOG.md
make stamp
git commit -m "docs: describe the clouds and pools"
```

- [ ] **Step 4: Review, push and open PR 2**

Run `/simplify` with 4 reviewers on the branch. Then run the code
review angles from `CLAUDE.md`. Check multiplayer safety
(`storage.hazards` and the cursor, the class cache), save compatibility (the new
`storage` fields, vanilla clouds and puddles from an old save), mod
compatibility (a removed vanilla cloud or puddle, Space Age plants and
demolishers), performance (the hazard pass in `on_tick`, a cloud over
a dense nest) and test quality (`spec/`, `tests/`). Fix every Critical
and Important finding with a test that fails first. Then review
again, for at most 3 rounds.

```bash
git push -u origin feat/payload-hazards
```

```bash
gh pr create --title "feat: let poison clouds and acid pools hurt by the payload's rule" --body-file <body file>
```

The body has `## What changes`, the checks from the PR template, and
`## Review angles` with one verdict per angle, as in Task 5. Security
is `n/a`. End the body with
`🤖 Generated with [Claude Code](https://claude.com/claude-code)`.

```bash
gh pr merge --auto --squash
```

Wait for `all-checks` to pass and the PR to merge before PR 3 starts
from `main`.

---

## PR 3: acid extras

Branch `feat/acid-extras` from `main` after PR 2 merges.

### Task 10: The puddle look-alike, the trail rule and the sticker

**Files:**

- Modify: `core/names.lua`
- Modify: `core/payloads.lua`
- Modify: `core/prototypes/ordnance.lua`
- Modify: `data.lua`
- Modify: `spec/support/stubs.lua`
- Modify: `spec/core/payloads_spec.lua`
- Modify: `spec/core/prototypes/ordnance_spec.lua`

**Interfaces:**

- Consumes: the `puddle` builder (Task 7).
- Produces: `Names.PUDDLE`, the prototype `fire/ao-acid-puddle`,
  `Payloads.trail(names) -> entity_name, payload_name` and
  `Payloads.sticker(name)`.

- [ ] **Step 1: Write the failing tests**

In `spec/support/stubs.lua`, add to the table of
`Stubs.ordnance_opts`, after `pool = { ... },`:

```lua
    puddle = {
      type = "fire",
      name = "acid-splash-fire-spitter-small",
      pictures = { { filename = "puddle.png" } },
      damage_per_tick = { amount = 0, type = "acid" },
      on_damage_tick_effect = { type = "direct" },
      maximum_spread_count = 100,
      initial_lifetime = 600,
      maximum_lifetime = 1800,
      lifetime_increase_by = 20,
    },
```

In `spec/core/prototypes/ordnance_spec.lua`, in
`describe("the look-alikes", ...)`, add:

```lua
  it("copy the vanilla trail puddle with no damage, no spread and its own lifetime", function()
    local p = build()["fire/ao-acid-puddle"]
    assert.are.equal("puddle.png", p.pictures[1].filename)
    assert.is_nil(p.on_damage_tick_effect)
    assert.are.equal(0, p.maximum_spread_count)
    assert.are.equal(600, p.initial_lifetime)
    assert.are.equal(1800, p.maximum_lifetime)
  end)
```

In `spec/core/payloads_spec.lua`, replace the test "give acid a trail
and no other payload one" with:

```lua
  it("give acid a trail look-alike and no other payload one", function()
    assert.are.same({ "ao-acid-puddle", "acid" }, { Payloads.trail({ "acid" }) })
    assert.are.same({ "ao-acid-puddle", "acid" }, { Payloads.trail({ "poison", "acid" }) })
    assert.is_nil(Payloads.trail({ "poison" }))
  end)

  it("give only acid a sticker", function()
    assert.are.equal("acid-sticker-big", Payloads.sticker("acid"))
    assert.is_nil(Payloads.sticker("poison"))
    assert.is_nil(Payloads.sticker("glitter"))
  end)
```

- [ ] **Step 2: Run the tests to watch them fail**

Run: `BUSTED spec/core/payloads_spec.lua spec/core/prototypes/ordnance_spec.lua`

Expected: FAIL. The trail is still the vanilla puddle, `Payloads.sticker`
is nil, and `fire/ao-acid-puddle` does not exist.

- [ ] **Step 3: Write the code**

In `core/names.lua`, add after `POOL = "ao-acid-pool",`:

```lua
  PUDDLE = "ao-acid-puddle",
```

In `core/payloads.lua`, in the acid entry of `Payloads.ALL`, replace
`trail = "acid-splash-fire-spitter-small",` with:

```lua
    trail = Names.PUDDLE,
    -- The pool slows the units and characters it hits.
    sticker = "acid-sticker-big",
```

Replace `Payloads.trail` with:

```lua
-- The trail look-alike of the first payload that has a trail, and that
-- payload's name. Nil when no payload leaves a trail.
function Payloads.trail(names)
  for _, name in ipairs(names) do
    local payload = BY_NAME[name]
    if payload and payload.trail then
      return payload.trail, name
    end
  end
  return nil
end

-- The sticker that a payload's hazard puts on mobile targets, or nil.
function Payloads.sticker(name)
  local payload = BY_NAME[name]
  return payload and payload.sticker or nil
end
```

In `core/prototypes/ordnance.lua`, in `lookalikes`, add
`puddle(opts.puddle, Names.PUDDLE),` to the list. The trail puddle
keeps the vanilla lifetime. Extend the comment above
`Ordnance.prototypes` with "and the small acid puddle".

In `data.lua`, add to the `Ordnance.prototypes` call:

```lua
  puddle = optional("fire", "acid-splash-fire-spitter-small"),
```

- [ ] **Step 4: Run the tests to watch them pass**

Run: `BUSTED spec/core/payloads_spec.lua spec/core/prototypes/ordnance_spec.lua`

Expected: PASS. `control.lua` still reads `entry.trail` until Task 11,
so the trail still drops what `load_monster` stored. New acid monsters
store the look-alike name, and old ones keep the vanilla puddle.

- [ ] **Step 5: Commit**

Run `/ste80-humanizer` on the changed comments and `/simplify` (1
reviewer), then each as its own command:

```bash
make format
git add core/names.lua core/payloads.lua core/prototypes/ordnance.lua data.lua spec/support/stubs.lua spec/core/payloads_spec.lua spec/core/prototypes/ordnance_spec.lua
make stamp
git commit -m "feat: add the acid puddle look-alike and the acid sticker"
```

### Task 11: The trail hit and the slowdown (shell)

**Files:**

- Modify: `shell/damage.lua`
- Modify: `shell/setup.lua`
- Modify: `control.lua` (`load_monster`, `trail_tick`)
- Modify: `tests/ingame/damage_test.lua`
- Modify: `tests/ingame/ordnance_test.lua`

**Interfaces:**

- Consumes: `Payloads.trail`, `Payloads.sticker` (Task 10),
  `Damage.hit`, `FeralShell.force_of`.
- Produces: `Damage.trail(entry, force)`, and the `sticker` field of a
  hit.

- [ ] **Step 1: Write the failing in-game tests**

Append to `tests/ingame/damage_test.lua`:

```lua
-- The acid stickers within half a tile of an entity.
local function stickers_on(entity)
  return surface().count_entities_filtered({
    name = "acid-sticker-big",
    position = entity.position,
    radius = 0.5,
  })
end

test("an acid pool slows a native unit and does not slow a chest", function()
  local position = { 4500, 4000 }
  Helpers.arena(surface(), position)
  local native = surface().create_entity({
    name = "big-biter",
    position = { position[1] + 1.5, position[2] },
    force = "enemy",
  })
  native.disabled_by_script = true
  local chest = Helpers.chest(surface(), { position[1] - 1.5, position[2] })
  local id = add_hazard({ x = position[1], y = position[2] }, "acid", 600)
  after_ticks(2, function()
    local slowed = native.valid and #(native.stickers or {}) > 0
    local chest_stickers = stickers_on(chest)
    storage.hazards[id] = nil
    destroy_all({ native, chest })
    assert(slowed, "the pool did not slow the native")
    assert(chest_stickers == 0, chest_stickers .. " stickers on the chest")
  end)
end)

test("an acid monster's trail hurts a chest and another monster, never itself", function()
  with_entry({ 4540, 4000 }, "ao-biter-larva-acid", function(entry)
    local p = entry.unit.position
    local chest = Helpers.chest(surface(), { p.x + 0.8, p.y })
    local other = surface().create_entity({
      name = "medium-biter",
      position = { p.x - 0.8, p.y },
      force = Names.TAMED,
    })
    other.disabled_by_script = true
    after_ticks(Balance.acid_trail_ticks + 2, function()
      local chest_hurt = hurt(chest)
      local other_hurt = hurt(other)
      local self_whole = entry.unit.health == entry.unit.max_health
      local puddles = surface().count_entities_filtered({ name = Names.PUDDLE, position = p, radius = 2 })
      destroy_all({ chest, other, entry.unit })
      assert(chest_hurt, "the trail spared the chest")
      assert(other_hurt, "the trail spared the other tamed monster")
      assert(self_whole, "the trail hurt its own monster")
      assert(puddles >= 1, "no puddle look-alike")
    end)
  end)
end)

test("an old-save entry with the vanilla trail name drops the look-alike", function()
  with_entry({ 4580, 4000 }, "ao-biter-larva-acid", function(entry)
    entry.trail = "acid-splash-fire-spitter-small"
    local p = entry.unit.position
    after_ticks(Balance.acid_trail_ticks + 2, function()
      local function count(name)
        return surface().count_entities_filtered({ name = name, position = p, radius = 2 })
      end
      local lookalikes, vanilla = count(Names.PUDDLE), count("acid-splash-fire-spitter-small")
      entry.unit.destroy()
      assert(lookalikes >= 1, "no puddle look-alike")
      assert(vanilla == 0, vanilla .. " vanilla puddles")
    end)
  end)
end)
```

In `tests/ingame/ordnance_test.lua`:

- In `puddles_near`, change the name to `Names.PUDDLE`.
- Delete the test "an acid trail whose entity is missing does
  nothing". The trail no longer reads a stored name, and the old-save
  test above covers a stored one.
- In the test "every payload effect entity exists", add:

```lua
    if payload.sticker then
      assert(prototypes.entity[payload.sticker], payload.sticker)
    end
```

- [ ] **Step 2: Run the in-game tests to watch them fail**

Run: `tools/ingame.sh base`

Expected: FAIL. The pool puts no sticker on the native, the trail
deals no hit, and the old-save entry still drops vanilla puddles.

- [ ] **Step 3: Write the code**

In `shell/damage.lua`, add above `Damage.hit`:

```lua
-- Only units and characters can carry a sticker.
local MOBILE = { unit = true, character = true }
```

In `Damage.hit`, extend the comment with "It may have sticker (a
sticker name for each mobile survivor)", and replace

```lua
      if target.valid then
        survivors[#survivors + 1] = target
      end
```

with

```lua
      if target.valid then
        survivors[#survivors + 1] = target
        if hit.sticker and MOBILE[target.type] then
          hit.surface.create_entity({
            name = hit.sticker,
            position = target.position,
            target = target,
            force = hit.force,
          })
        end
      end
```

Add above `hazard_hit`:

```lua
-- The payload's sticker, if its prototype exists.
local function sticker_of(payload)
  local name = Payloads.sticker(payload)
  return name and entity_exists(name) and name or nil
end
```

and add to the hit table in `hazard_hit`:

```lua
    sticker = sticker_of(hazard.payload),
```

Add before `return Damage`:

```lua
-- One trail step of a loaded monster: a puddle look-alike under it and
-- one hit around it that spares the monster itself. The hit applies
-- even when another mod removed the look-alike's vanilla puddle.
function Damage.trail(entry, force)
  local puddle, payload = Payloads.trail(entry.payloads)
  if not payload then
    return
  end
  local unit = entry.unit
  if entity_exists(puddle) then
    unit.surface.create_entity({ name = puddle, position = unit.position, force = force })
  end
  local n = Balance.payload_damage.trail
  Damage.hit({
    surface = unit.surface,
    position = unit.position,
    radius = n.radius,
    payload = payload,
    damage = n.damage,
    force = force,
    cause = unit,
    skip = unit,
  })
end
```

In `control.lua`, in `trail_tick`, replace the body of the
`for _, id in ipairs(ids) do` loop with:

```lua
    local entry = storage.loaded[id]
    if entry and entry.unit.valid then
      Damage.trail(entry, FeralShell.force_of(entry))
    end
```

In `load_monster`, replace the lines from `local trail = ...` to the
end of the `if entry.trail then ... end` block with:

```lua
  local entry = { unit = monster, payloads = payloads }
  storage.loaded[monster.unit_number] = entry
  if Payloads.trail(payloads) then
    storage.trails[monster.unit_number] = true
  end
```

In `shell/setup.lua`, add `local Payloads = require("core.payloads")`
to the requires. In `rebuild_trails`, change `if entry.trail then` to
`if Payloads.trail(entry.payloads) then`, and change its comment to:
"A save from slice 2 has acid monsters in storage.loaded but no trail
list. The rebuild adds every monster whose payloads leave a trail, and
a second run changes nothing. A stored entry.trail from an old save no
longer matters."

- [ ] **Step 4: Run the tests to watch them pass**

Run: `make fast`

Expected: every gate passes.

Run: `make ingame`

Expected: every in-game test passes in both modes.

- [ ] **Step 5: Commit**

Run `/ste80-humanizer` on the changed comments and `/simplify` (2
reviewers), then each as its own command:

```bash
make format
git add shell/damage.lua shell/setup.lua control.lua tests/ingame/damage_test.lua tests/ingame/ordnance_test.lua
make stamp
git commit -m "feat: let the acid trail hit and acid pools slow"
```

### Task 12: Changelog, roadmap and PR 3

**Files:**

- Modify: `CHANGELOG.md`
- Modify: `ROADMAP.md`

**Interfaces:**

- Consumes: Tasks 10 and 11.
- Produces: PR 3.

- [ ] **Step 1: Write the changelog and tick the roadmap**

Under `## [Unreleased]`, `### Changed`, add:

```markdown
- An acid monster's trail hits everything except rocks within 1 tile
  for 5 acid damage, your buildings and other tamed monsters included.
  It never hurts the monster that leaves it.
- Acid pools slow the natives, characters and monsters they hit.
- An acid monster from an old save now leaves the new puddles.
```

In `ROADMAP.md`, tick the line "Payload damage follows the payload".

- [ ] **Step 2: Run everything**

Run: `make check`

Expected: PASS in both modes.

- [ ] **Step 3: Commit**

Run `/ste80-humanizer` on the changed prose, then each as its own
command:

```bash
git add CHANGELOG.md ROADMAP.md
make stamp
git commit -m "docs: describe the acid trail and the slowdown"
```

- [ ] **Step 4: Review, push and open PR 3**

Run `/simplify` with 2 reviewers (simplification and altitude) on the
branch. Then run the code review angles from `CLAUDE.md`. Check
multiplayer safety (the trail pass, `storage.trails` from old saves), save
compatibility (old entries with `entry.trail`), mod compatibility (a
removed vanilla puddle or sticker), performance (one search per trail
puddle, at most `trail_batch` per tick) and test quality. Fix every
Critical and Important finding with a test that fails first. Then
review again, for at most 3 rounds.

```bash
git push -u origin feat/acid-extras
```

```bash
gh pr create --title "feat: let the acid trail hit and acid pools slow" --body-file <body file>
```

The body has `## What changes`, the checks from the PR template, and
`## Review angles` with one verdict per angle, as in Task 5. Security
is `n/a`. End the body with
`🤖 Generated with [Claude Code](https://claude.com/claude-code)`.

```bash
gh pr merge --auto --squash
```

After the merge, run `make package` and give the maintainer in-game
test commands for the three PRs.

## Spec coverage

| Spec item | Task |
| --- | --- |
| `Payloads.hits`, `damage_type`, `Balance.payload_damage` | 1 |
| Class sets from prototypes, `Damage.class_of` | 2 |
| Landing blast follows the payload | 3 |
| Detonation queue, water landing, explosive death, feral kills | 4 |
| `Forces.blast_hits` and its slice 3 test go | 1, 3 |
| Architecture example | 5 |
| Hazard catch-up and budget (busted) | 6 |
| Cloud and pool look-alikes, removed vanilla prototype | 7 |
| Hazard pass, poison and acid deaths, old saves | 8 |
| Space Age plant and demolisher | 8 |
| Trail look-alike, trail hit, old-save trail | 10, 11 |
| Acid slowdown on mobile targets only | 10, 11 |
| Probe table and fallbacks | 0 |
