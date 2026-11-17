# Poison aura Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task-by-task. Steps
> use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A loaded poison monster deals 3 poison damage in radius 3 once a
second, spares its own force, and shows a small green puff.

**Architecture:** The acid-only `trail` field becomes a `live` table on
each payload. The existing trail pass in `control.lua` runs every live
effect through `Damage.live`. `Damage.hit` gains `spare_force` and
`limit`. The puff is a third look-alike from the existing `cloud` builder.

**Tech Stack:** Lua 5.2 (Factorio 2.1), busted for `spec/`,
factorio-test for `tests/ingame/`, `make fast` and `make ingame`.

**Spec:** `docs/superpowers/specs/2026-11-17-poison-aura-design.md`.
Read it first. This plan names the steps and the code, and the spec holds
the reasons.

## Global Constraints

- Target Factorio 2.1, with and without Space Age. `make ingame` runs
  both modes.
- Load the `functional-core` skill before the first edit. The core stays
  pure: `core/` reads no game globals.
- Work test-first. Each test fails first, for the reason it names.
- Look up every Factorio API name with `make api NAME=<name>` first.
- Run `make format` before you stage Lua files. `make fast` must pass
  before each commit.
- Commit order from `CLAUDE.md`: humanizer on changed prose and
  comments, `/simplify`, `git add`, `make stamp`, `git commit`. Run each
  as its own Bash call. Do not use `git commit -a`.
- British English in comments and docs.
- Numbers: `Balance.payload_damage.aura = { damage = 3, radius = 3,
  max_targets = 20 }`. Puff: `particle_count = 4`, `particle_spread = {
  1.5, 0.9 }`, `duration = 60`, `fade_away_duration = 30`,
  `spread_duration = 20`.

## Review Focus

- A pack of tamed poison monsters standing together: none of them takes
  aura damage. Task 3 tests a second tamed monster next to the aura.
- A poison monster that turns feral: its aura now hurts tamed monsters
  and spares feral ones. Task 3 tests it.
- A forest: each hit stops at 20 targets. Task 3 tests `limit` with
  trees.
- Another mod removes `poison-cloud`: no puff, and the aura still hits.
  Tasks 2 and 3 test it.
- Old acid monsters: the acid trail keeps its behaviour under the new
  names. Task 3 keeps the existing acid trail tests green.

## File map

| File | Responsibility in this change |
| --- | --- |
| `core/names.lua` | The puff's name |
| `core/balance.lua` | The aura's numbers |
| `core/payloads.lua` | The `live` table per payload and `Payloads.live` |
| `core/prototypes/ordnance.lua` | The `cloud` builder makes the cloud and the puff |
| `shell/damage.lua` | `Damage.targets` and `Damage.hit` take the new fields. `Damage.live` runs one live effect |
| `control.lua` | Hatch and trail pass call the new names |
| `shell/setup.lua` | The rebuild calls `Payloads.live` |
| `spec/core/payloads_spec.lua`, `spec/core/prototypes/ordnance_spec.lua` | Unit tests |
| `tests/ingame/damage_test.lua`, `tests/ingame/ordnance_test.lua` | In-game tests |

---

### Task 0: Branch

- [ ] **Step 1: Make the worktree.**

```bash
git worktree add ../ao-aura-build -b feat/poison-aura main
cp -a node_modules ../ao-aura-build/
cd ../ao-aura-build && make setup
```

Do not symlink `node_modules`: luacov crashes on links.

### Task 1: The `live` field and `Payloads.live`

**Files:**

- Modify: `core/names.lua`, `core/balance.lua`, `core/payloads.lua`
- Test: `spec/core/payloads_spec.lua`

**Interfaces:**

- Produces: `Names.PUFF = "ao-poison-puff"`.
- Produces: `Payloads.live(names) -> live, payload_name`, or nothing.
  `live` is `{ lookalike = <entity name>, balance_key = <key>, spare =
  "self" | "force" }`.
- Produces: `Balance.payload_damage.aura = { damage = 3, radius = 3,
  max_targets = 20 }`.

- [ ] **Step 1: Write the failing tests.** Replace the test "give acid a
  trail look-alike and no other payload one" at
  `spec/core/payloads_spec.lua:175` with these. Add `Balance` to the
  file's requires if it is missing.

```lua
  it("give acid a live trail that spares only itself", function()
    local live, name = Payloads.live({ "acid" })
    assert.are.same(
      { lookalike = "ao-acid-puddle", balance_key = "trail", spare = "self" },
      live
    )
    assert.are.equal("acid", name)
  end)

  it("give poison a live aura that spares its force", function()
    local live, name = Payloads.live({ "poison" })
    assert.are.same(
      { lookalike = "ao-poison-puff", balance_key = "aura", spare = "force" },
      live
    )
    assert.are.equal("poison", name)
  end)

  it("take the live effect of the first payload that has one", function()
    assert.are.equal("poison", select(2, Payloads.live({ "explosive", "poison", "acid" })))
  end)

  it("give no live effect to explosive or an unknown payload", function()
    assert.are.same({}, { Payloads.live({ "explosive" }) })
    assert.are.same({}, { Payloads.live({ "glitter" }) })
  end)

  it("give the aura 3 damage in radius 3, at most 20 targets", function()
    assert.are.same({ damage = 3, radius = 3, max_targets = 20 }, Balance.payload_damage.aura)
  end)
```

- [ ] **Step 2: Run them and see them fail.**

Run: `busted spec/core/payloads_spec.lua`
Expected: FAIL, "attempt to call a nil value (field 'live')" and the
`aura` test comparing against nil.

- [ ] **Step 3: Implement.** In `core/names.lua`, beside `PUDDLE`:

```lua
  PUFF = "ao-poison-puff",
```

In `core/balance.lua`, inside `payload_damage`, after `trail`:

```lua
    -- The poison aura: one hit a second around a live poison monster.
    -- max_targets caps the entities that one hit finds.
    aura = { damage = 3, radius = 3, max_targets = 20 },
```

Above `acid_trail_ticks`, add the comment:

```lua
  -- The trail pass runs every live effect (acid trail, poison aura), not
  -- only acid. The name stays for old saves.
```

In `core/payloads.lua`, replace acid's `trail = Names.PUDDLE` and its
comment with:

```lua
    -- Under a live acid monster: a puddle look-alike and a small hit
    -- that spares only the monster.
    live = { lookalike = Names.PUDDLE, balance_key = "trail", spare = "self" },
```

Add to poison, after `death`:

```lua
    -- Around a live poison monster: a puff look-alike and a hit that
    -- spares the monster's whole force, so a pack does not poison
    -- itself.
    live = { lookalike = Names.PUFF, balance_key = "aura", spare = "force" },
```

Replace `Payloads.trail` with:

```lua
-- The live effect of the first payload that has one, and that
-- payload's name. Nil when no payload acts while its monster lives.
function Payloads.live(names)
  for _, name in ipairs(names) do
    local payload = BY_NAME[name]
    if payload and payload.live then
      return payload.live, name
    end
  end
  return nil
end
```

- [ ] **Step 4: Run them and see them pass.**

Run: `busted spec/core/payloads_spec.lua`
Expected: PASS. `make fast` still fails, because `control.lua` and
`shell/` call `Payloads.trail`. Task 3 fixes that. Do not commit yet.

### Task 2: The puff prototype

**Files:**

- Modify: `core/prototypes/ordnance.lua` (the `cloud` builder at about
  line 296, and `Ordnance.lookalikes` at about line 341)
- Test: `spec/core/prototypes/ordnance_spec.lua` (the "look-alikes"
  block)

**Interfaces:**

- Consumes: `Names.PUFF` from Task 1.
- Produces: `Ordnance.lookalikes(opts)` returns, in name order,
  `ao-acid-pool`, `ao-acid-puddle`, `ao-poison-cloud`, `ao-poison-puff`.

- [ ] **Step 1: Write the failing tests.** In the "look-alikes" block:

```lua
  it("make a small puff from the vanilla cloud, with no effects", function()
    local p = lookalikes()["smoke-with-trigger/ao-poison-puff"]
    assert.are.equal("cloud.png", p.animation.filename)
    assert.is_true(p.hidden)
    assert.is_nil(p.action)
    assert.is_nil(p.created_effect)
    assert.are.equal(4, p.particle_count)
    assert.are.same({ 1.5, 0.9 }, p.particle_spread)
    assert.are.equal(60, p.duration)
    assert.are.equal(30, p.fade_away_duration)
    assert.are.equal(20, p.spread_duration)
    assert.is_true(p.fade_away_duration <= p.duration)
  end)

  it("make no puff when the vanilla cloud is missing", function()
    local opts = Stubs.lookalike_opts()
    opts.cloud = nil
    assert.is_nil(build_with(opts)["smoke-with-trigger/ao-poison-puff"])
  end)

  it("leave the vanilla cloud unchanged", function()
    local opts = Stubs.lookalike_opts()
    Ordnance.lookalikes(opts)
    assert.are.equal(1200, opts.cloud.duration)
    assert.is_not_nil(opts.cloud.created_effect)
  end)
```

Change "come in name order" to expect:

```lua
    assert.are.same(
      { "ao-acid-pool", "ao-acid-puddle", "ao-poison-cloud", "ao-poison-puff" },
      names
    )
```

In "are not part of the data stage prototypes", add:

```lua
    assert.is_nil(all["smoke-with-trigger/ao-poison-puff"])
```

- [ ] **Step 2: Run them and see them fail.**

Run: `busted spec/core/prototypes/ordnance_spec.lua`
Expected: FAIL on the puff tests (no `ao-poison-puff`) and on the name
order.

- [ ] **Step 3: Implement.** Replace `cloud` with a builder that takes a
  shape, and add the two shapes above it:

```lua
-- The two look-alikes made from the vanilla poison cloud. The cloud
-- keeps the vanilla smoke and sound for as long as its hazard lasts. The
-- puff shows the aura for one second: a few particles, no extra smokes
-- and no sound.
local CLOUD_SHAPE = {
  name = Names.CLOUD,
  duration = Balance.payload_damage.poison.ticks,
  keep_looks = true,
}
local PUFF_SHAPE = {
  name = Names.PUFF,
  duration = 60,
  fields = {
    particle_count = 4,
    particle_spread = { 1.5, 0.9 },
    fade_away_duration = 30,
    spread_duration = 20,
  },
}

-- A look-alike of the vanilla cloud in a shape. It deals no damage. With
-- keep_looks, its created_effect keeps only the vanilla smoke and sound.
-- Without it, it has no created_effect.
local function cloud(vanilla, entity_exists, shape)
  if not vanilla then
    return nil
  end
  local p = Common.copy(vanilla)
  p.name = shape.name
  p.hidden = true
  p.action = nil
  p.action_cooldown = 0
  p.duration = shape.duration
  p.created_effect = shape.keep_looks and cloud_looks(vanilla.created_effect, entity_exists)
    or nil
  for key, value in pairs(shape.fields or {}) do
    p[key] = Common.copy(value)
  end
  return p
end
```

If `Common.copy` does not accept a number, copy only tables:
`p[key] = type(value) == "table" and Common.copy(value) or value`.

In `Ordnance.lookalikes`, change the cloud line and add the puff after
it:

```lua
  out[#out + 1] = cloud(opts.cloud, opts.entity_exists, CLOUD_SHAPE)
  out[#out + 1] = cloud(opts.cloud, opts.entity_exists, PUFF_SHAPE)
```

- [ ] **Step 4: Run them and see them pass.**

Run: `busted spec/core/prototypes/ordnance_spec.lua`
Expected: PASS, the old cloud tests included.

### Task 3: The shell

**Files:**

- Modify: `shell/damage.lua` (`Damage.targets` at about line 95,
  `Damage.hit` at about line 150, `Damage.trail` at about line 353)
- Modify: `control.lua` (`load_monster` at about line 109, `trail_tick`
  at about line 259)
- Modify: `shell/setup.lua` (`rebuild_trails` at about line 22)
- Test: `tests/ingame/damage_test.lua`, `tests/ingame/ordnance_test.lua`

**Interfaces:**

- Consumes: `Payloads.live` and `Names.PUFF` from Task 1, the puff
  prototype from Task 2.
- Produces: `Damage.live(entry, force)`. `Damage.hit(hit)` reads
  `hit.spare_force` (a force name) and `hit.limit` (a count).
  `Damage.targets(surface, position, radius, payload, limit)`.

- [ ] **Step 1: Look up the API.**

```bash
make api NAME=LuaSurface.find_entities_filtered
make api NAME=EntitySearchFilters
```

`EntitySearchFilters` has `limit?: uint32`.

- [ ] **Step 2: Update the existing tests.** Four changes.

`tests/ingame/damage_test.lua:927`: `Damage.trail(entry, Names.TAMED)`
becomes `Damage.live(entry, Names.TAMED)`. The two acid trail tests
and the old-save test at line 968 keep their checks.

`tests/ingame/ordnance_test.lua:262`: the check reads the live
look-alike.

```lua
    if payload.live then
      assert(prototypes.entity[payload.live.lookalike], payload.live.lookalike)
    end
```

`tests/ingame/ordnance_test.lua:195`: invert the test.

```lua
test("a poison monster is in the trail list", function()
  with_loaded_monster({ 1060, 700 }, "ao-biter-larva-poison", function(unit)
    local listed = storage.trails[unit.unit_number] ~= nil
    unit.destroy()
    assert(listed, "the poison monster has no trail entry")
  end)
end)
```

`tests/ingame/ordnance_test.lua:68` ("a loaded monster attacks a nearby
spawner"): after its check, destroy the tamed units around `position`
with the file's `tamed_units(position)` helper, so the poison monster
does not stay in `storage.trails`.

- [ ] **Step 3: Write the new failing tests** in
  `tests/ingame/damage_test.lua`, after the acid trail tests. Use the
  file's `with_entry`, `hurt`, `destroy_all` and `few_trails` helpers.
  Each test destroys everything it makes. Use x positions from 5200 on,
  80 tiles apart, so the tests do not meet each other's entities.

```lua
-- A biter of a force that stands still, for the aura tests.
local function still_biter(position, force)
  local biter = surface().create_entity({
    name = "medium-biter",
    position = position,
    force = force,
  })
  biter.disabled_by_script = true
  return biter
end

test("a poison aura hurts natives, trees and players, and spares its pack", function()
  few_trails()
  with_entry({ 5200, 4000 }, "ao-biter-larva-poison", function(entry)
    local p = entry.unit.position
    local native = still_biter({ p.x + 2, p.y }, "enemy")
    local tree = surface().create_entity({ name = "tree-01", position = { p.x, p.y + 2 } })
    local player = Helpers.character(surface(), { p.x, p.y - 2 })
    local packmate = still_biter({ p.x - 2, p.y }, Names.TAMED)
    local chest = Helpers.chest(surface(), { p.x + 1.5, p.y + 1.5 })
    after_ticks(2 * Balance.acid_trail_ticks, function()
      local result = {
        native = hurt(native),
        tree = hurt(tree),
        player = hurt(player),
        packmate = hurt(packmate),
        chest = hurt(chest),
        self = hurt(entry.unit),
      }
      destroy_all({ native, tree, player, packmate, chest, entry.unit })
      assert(result.native, "the aura spared the native")
      assert(result.tree, "the aura spared the tree")
      assert(result.player, "the aura spared the player's character")
      assert(not result.packmate, "the aura hurt a tamed packmate")
      assert(not result.chest, "the aura hurt a chest")
      assert(not result.self, "the aura hurt its own monster")
    end)
  end)
end)

test("a poison aura does not reach 5 tiles", function()
  few_trails()
  with_entry({ 5280, 4000 }, "ao-biter-larva-poison", function(entry)
    local p = entry.unit.position
    local native = still_biter({ p.x + 5, p.y }, "enemy")
    after_ticks(2 * Balance.acid_trail_ticks, function()
      local native_hurt = hurt(native)
      destroy_all({ native, entry.unit })
      assert(not native_hurt, "the aura reached 5 tiles")
    end)
  end)
end)

test("a feral poison aura hurts tamed monsters and spares feral ones", function()
  few_trails()
  with_entry({ 5360, 4000 }, "ao-biter-larva-poison", function(entry)
    FeralShell.go_feral(entry, game.tick)
    entry.unit.disabled_by_script = true
    local p = entry.unit.position
    local tamed = still_biter({ p.x + 2, p.y }, Names.TAMED)
    local feral = still_biter({ p.x - 2, p.y }, Names.FERAL)
    after_ticks(2 * Balance.acid_trail_ticks, function()
      local tamed_hurt, feral_hurt = hurt(tamed), hurt(feral)
      destroy_all({ tamed, feral, entry.unit })
      assert(tamed_hurt, "the feral aura spared a tamed monster")
      assert(not feral_hurt, "the feral aura hurt a feral monster")
    end)
  end)
end)

test("a hit with spare_force spares that force and hurts the others", function()
  local p = { x = 5440, y = 4000 }
  Helpers.arena(surface(), { p.x, p.y })
  local native = still_biter({ p.x + 1, p.y }, "enemy")
  local tamed = still_biter({ p.x - 1, p.y }, Names.TAMED)
  Damage.hit({
    surface = surface(),
    position = p,
    radius = 3,
    payload = "poison",
    damage = 3,
    force = Names.TAMED,
    spare_force = Names.TAMED,
  })
  local native_hurt, tamed_hurt = hurt(native), hurt(tamed)
  destroy_all({ native, tamed })
  assert(native_hurt, "spare_force spared the native")
  assert(not tamed_hurt, "spare_force hurt its own force")
end)

test("a hit with a limit damages at most that many targets", function()
  local p = { x = 5520, y = 4000 }
  Helpers.arena(surface(), { p.x, p.y })
  local trees = {}
  for i = -2, 2 do
    trees[#trees + 1] = surface().create_entity({ name = "tree-01", position = { p.x + i, p.y } })
  end
  local _, dealt = Damage.hit({
    surface = surface(),
    position = p,
    radius = 3,
    payload = "poison",
    damage = 1,
    force = Names.TAMED,
    limit = 2,
  })
  destroy_all(trees)
  assert(dealt == 2, dealt .. " targets hit, not 2")
end)

test("a poison aura still hits when another mod removed its puff", function()
  with_entry({ 5600, 4000 }, "ao-biter-larva-poison", function(entry)
    local p = entry.unit.position
    local native = still_biter({ p.x + 2, p.y }, "enemy")
    local ok, err = pcall(wrapped, Damage, "entity_exists", function(original)
      return function(name)
        return name ~= Names.PUFF and original(name)
      end
    end, function()
      Damage.live(entry, Names.TAMED)
    end)
    local puffs = surface().count_entities_filtered({ name = Names.PUFF, position = p, radius = 3 })
    local native_hurt = hurt(native)
    destroy_all({ native, entry.unit })
    assert(ok, err)
    assert(puffs == 0, puffs .. " puffs")
    assert(native_hurt, "the aura spared the native")
  end)
end)

test("a poison monster missing from the trail list returns on a configuration change", function()
  with_entry({ 5680, 4000 }, "ao-biter-larva-poison", function(entry)
    local id = entry.unit.unit_number
    storage.trails[id] = nil
    Setup.on_configuration_changed()
    local listed = storage.trails[id] ~= nil
    destroy_all({ entry.unit })
    assert(listed, "the rebuild did not list the poison monster")
  end)
end)
```

  Require `FeralShell` (`shell.feral`) and `Setup` (`shell.setup`) at the
  top of the file if it lacks them. `wrapped` is the file's existing
  helper from the acid puddle test.

- [ ] **Step 4: Run them and see them fail.**

Run: `make ingame`
Expected: FAIL. `Damage.live` is nil, poison monsters are not in
`storage.trails`, `spare_force` and `limit` have no effect, and the
inverted list test fails.

- [ ] **Step 5: Implement `limit` in `Damage.targets`.** Add the
  parameter and pass it to the search. Update the comment.

```lua
-- The entities with health within radius of a position that the
-- payload hurts. With a limit, the search finds at most that many
-- entities, before the payload's rule filters them.
function Damage.targets(surface, position, radius, payload, limit)
  ...
  local found = surface.find_entities_filtered({
    position = position,
    radius = radius,
    type = types,
    limit = limit,
  })
```

- [ ] **Step 6: Implement `spare_force` and `limit` in `Damage.hit`.**
  Add both to the comment's list of fields. Pass `hit.limit` to
  `Damage.targets`, and skip a target of the spared force before any
  damage:

```lua
  for _, target in
    ipairs(Damage.targets(hit.surface, hit.position, hit.radius, hit.payload, hit.limit))
  do
    if target.valid and target ~= hit.skip then
      local force = target.force
      if force.name ~= hit.spare_force then
        -- the existing body: attacker, cause, damage, sticker
      end
    end
  end
```

- [ ] **Step 7: Replace `Damage.trail` with `Damage.live`.**

```lua
-- One step of a monster's live effect: its look-alike at the monster
-- and one hit around it. The hit always spares the monster. With spare
-- "force", it spares the monster's whole force too, read from the unit.
-- The hit applies even when another mod removed the look-alike's
-- vanilla source.
function Damage.live(entry, force)
  local live, payload = Payloads.live(entry.payloads)
  if not live then
    return
  end
  local unit = entry.unit
  local surface, position = unit.surface, unit.position
  if Damage.entity_exists(live.lookalike) then
    surface.create_entity({ name = live.lookalike, position = position, force = force })
  end
  local n = Balance.payload_damage[live.balance_key]
  Damage.hit({
    surface = surface,
    position = position,
    radius = n.radius,
    payload = payload,
    damage = n.damage,
    force = force,
    cause = unit,
    skip = unit,
    limit = n.max_targets,
    spare_force = live.spare == "force" and unit.force.name or nil,
  })
end
```

- [ ] **Step 8: Switch the callers.** In `control.lua`, `load_monster`
  calls `Payloads.live(payloads)` in place of `Payloads.trail`, and
  `trail_tick` calls `Damage.live(entry, FeralShell.force_of(entry))`.
  Extend the comment above `trail_tick`:

```lua
-- The trail pass runs every live effect: the acid trail and the poison
-- aura. storage.trails keeps its old name for saves.
```

In `shell/setup.lua`, `rebuild_trails` calls `Payloads.live`, and its
comment says: "The rebuild adds every monster whose payload has a live
effect."

- [ ] **Step 9: Run every gate.**

```bash
make format
make fast
make ingame
```

Expected: all pass, in base and Space Age modes. If a test fails, add a
line to the failure log in your reply (what failed, why) before the next
attempt. After 3 failed attempts on one test, stop and hand back.

- [ ] **Step 10: Commit Tasks 1 to 3.** Run the humanizer on the changed
  comments, then `/simplify`, then:

```bash
git add core/names.lua core/balance.lua core/payloads.lua core/prototypes/ordnance.lua shell/damage.lua shell/setup.lua control.lua spec/core/payloads_spec.lua spec/core/prototypes/ordnance_spec.lua tests/ingame/damage_test.lua tests/ingame/ordnance_test.lua
make stamp
git commit -m "feat: add the poison aura"
```

### Task 4: Docs and changelog

**Files:** `docs/design.md`, `docs/architecture.md`, `README.md`,
`ROADMAP.md`, `CHANGELOG.md`.

- [ ] **Step 1: `docs/design.md`.** In the "Ordnance loading" table, the
  poison row's live effect becomes "Small poison aura: hurts living
  things nearby, spares its own side". Line 60 says "a live effect (such
  as an acid trail or a poison aura)".
- [ ] **Step 2: `docs/architecture.md`.** Where it names
  `storage.trails` and the trail pass, say that the pass runs every live
  effect, and that `storage.trails` keeps its name for saves.
- [ ] **Step 3: `README.md`.** The status says: "It has every version 1
  feature." Remove "except the poison aura". Keep the line about release
  1.0.0 and the test in the game.
- [ ] **Step 4: `ROADMAP.md`.** Tick "Poison aura".
- [ ] **Step 5: `CHANGELOG.md`.** Under Unreleased, Added:

```markdown
- A monster loaded with a poison capsule hurts living things within 3
  tiles once a second, with a small green puff. It spares its own side.
```

- [ ] **Step 6: Check and commit.** Run the humanizer on the changed
  prose, then:

```bash
make text
git add docs/design.md docs/architecture.md README.md ROADMAP.md CHANGELOG.md
make stamp
git commit -m "docs: describe the poison aura"
```

### Task 5: Review

- [ ] **Step 1: Simplify.** Run `/simplify` on the branch diff with 4
  reviewers.
- [ ] **Step 2: Review in rounds.** 4 reviewers, because the change
  touches shared core modules. One reviewer takes each angle from
  `CLAUDE.md`: multiplayer safety and save compatibility (`control.lua`,
  `shell/`, `storage`), compatibility with other mods and Space Age
  (`core/prototypes/`), performance (the `on_tick` trail pass), and test
  quality (`spec/`, `tests/`).
- [ ] **Step 3: Fix and repeat.** Fix every Critical and Important
  finding with a test that fails first. Re-run the same reviewers on the
  fix. Stop after a round with no new Critical or Important, or after 5
  rounds.
- [ ] **Step 4: Push and open the PR** `feat: add the poison aura`, with
  one verdict per angle. Do not enable auto-merge yet: Task 6 comes
  first.

### Task 6: Probe in the game

The spec puts the probe before the build. The puff's look and the speed
need the game's window, which the headless tests cannot show. So the
maintainer checks both on the built branch, before the PR merges. The
numbers live in `core/balance.lua` and in `PUFF_SHAPE`, so a change is
small.

- [ ] **Step 1: Install the build.** On the branch, run `make package`
  and copy the zip into `~/.factorio/mods`, in place of the old one.
- [ ] **Step 2: Add two checks to the test checklist page.** The puff next to
  a small biter. And 300 poison monsters in a forest, with this mod's
  line in the time usage display (F4, `show-time-usage`) below 1 ms a
  tick. Give a console command that spawns the 300 monsters.
- [ ] **Step 3: Act on the result.** The maintainer may ask for another
  puff, or the time may be above 1 ms. Then change the numbers with a
  failing test first, and re-run the reviewers on that change. When the
  maintainer is happy, run `gh pr merge --auto --squash`.
