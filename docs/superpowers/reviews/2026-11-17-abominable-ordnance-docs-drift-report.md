# Drift report: docs/ before release 1.0.0

Date: 2026-11-17. Main at `86f3f1a`. Made with `/egm:egm-drift-report docs/`.
Five read-only checkers compared `docs/design.md`, `docs/architecture.md`
and every spec in `docs/superpowers/specs/` with the code. The main
session checked the findings that point at behaviour. `make check` passes
on the same commit.

## Summary

No finding shows broken code. Most findings are specs that later specs
changed, or code details that no document names. Three findings need a
call from the maintainer before the release:

1. **Poison aura.** `docs/design.md` gives the poison payload a live
   "small poison aura". The code has none, and no spec defers it. Build
   it for 1.0.0, or move it to version 2 in the design table.
2. **Cryo icon tint.** The cryo spec gives a pale blue tint. The code uses
   a colder blue so that the two ward icons differ at a glance. Keep the
   code, or change it to the spec value.
3. **Research tree.** Larva rockets and Stasis ward need Ordnance loading
   in the code. The design tree shows four separate branches. Keep the
   prerequisites and fix the diagram, or remove the prerequisites.

The proposed fix for the rest: update `docs/design.md` and
`docs/architecture.md` in one docs PR. Mark the older specs as history
and leave their text, because later specs record the changes.

### docs/design.md

- "Ordnance loading" table: the poison capsule has the live effect "Small poison
  aura". The code has no poison live effect (`core/payloads.lua:40-47`). No spec
  defers it, and the roadmap line names only the acid trail. Maintainer call:
  build the aura, or move it to version 2 in the table.
- "Technical notes", live and death effects: the doc says live effects run from
  `on_nth_tick`. The acid trail and the feral pass run from `on_tick` with
  cursors and next-tick gates. Only the too-close scan uses `on_nth_tick`. The
  doc is stale.
- "Research tree": the doc says the four version 1 techs start four branches. In
  the code, Larva rockets needs Ordnance loading and `rocketry`
  (`core/prototypes/launcher.lua:188`). Stasis ward needs Ordnance loading
  (`core/prototypes/stasis.lua:74`). The diagram shows neither prerequisite.
- "Research tree": the tree does not list the three speed and three range techs
  of the launcher (`core/prototypes/launcher.lua:199-244`) or the Cryo ward tech
  on Space Age (`core/prototypes/stasis.lua:123`).
- "Core loop" and the species table: eggs drop from nests with no condition. The
  code drops them only for a force that has researched Monster husbandry, or for
  the tamed force (`core/loot.lua:8`, `core/forces.lua`).
- "Stasis ward": the doc reads as a one-off ward. The pack recipe uses one ward,
  and the unpack recipe gives it back (`core/prototypes/stasis.lua:269-295`).
  The ward is a reusable container.
- "Lifecycle" table: the loading recipe also takes a larva rocket casing
  (`core/prototypes/ordnance.lua:191-196`). "Logistics and delivery" names the
  casing, so only this table is short.
- The adopt recipe on Space Age turns the vanilla `biter-egg` into the mod's egg
  with monster chow (`core/prototypes/lifecycle.lua:81-86`). The doc does not
  describe it.
- The landing blast (`Balance.blast`, 35 damage, radius 3.5) and the explosive
  death blast (`Balance.payload_damage`, 150, radius 4) differ. The doc gives
  the target rule for both but no sizes. Minor.

### docs/architecture.md

- "Type annotations": the doc asks for `---@param event EventData.<name>` on
  named event handlers and `---@type <Prototype class>` on prototype tables. No
  handler in `control.lua`, `shell/` or the data stage carries one. The code
  lags the doc.
- "Old saves": the doc says a change to the shape of a `storage` field needs a
  file in `migrations/`. There is no `migrations/` folder.
  `shell/setup.lua:19-27` rebuilds the trail table from
  `on_configuration_changed` instead. The doc should name that pattern, or the
  rule should change.
- "Old saves": the exception for fields read as `storage.x or default` names
  only `storage.seed`. The fields `trail_cursor`, `trail_next_tick`,
  `feral_cursor` and `feral_next_tick` (`control.lua:231-297`) also use it. The
  doc's list is incomplete.
- "The shell": the doc names only `shell/tamed.lua` and `shell/damage.lua`. It
  does not describe `shell/feral.lua`, `shell/launcher.lua` or
  `shell/setup.lua`. Minor, since the doc says "for example".

### docs/superpowers/specs/2026-11-13-lifecycle-design.md

- "Data stage": `data.lua` passes one `pod = looks(...)` table with a fallback
  to `assembling-machine-2`, an `extra_unlocks` option, and a
  `Stasis.weighted(...)` wrapper (`data.lua:15-47`). The spec shows
  `graphics_set` and `working_sound`. The spec is stale.
- "Nest loot" step 5: eggs spill at the spawner's position. The code spills them
  beside the corpse (`Loot.beside`, `core/loot.lua:20`) and shows a floating "+N
  [item]" label (`Loot.label`). The spec is stale.
- "Nest loot" step 2: the code also gives loot to `ao-tamed` and refuses it to
  `ao-feral` (`core/forces.lua:38-43`). The ordnance spec covers the tamed
  force. No spec names the feral exclusion.
- "Hatching" step 4: the code first drops units that another mod removed
  (`Hatching.available`, `core/hatching.lua:41`) and searches 8 tiles
  (`Balance.hatch_search_radius`). The spec names neither.
- "Species table": `core/species.lua` also has `larva`, `tint` and `adopts`.
  They come from later specs.
- "Research": Monster husbandry also unlocks the incubator and its recipes
  (`extra_unlocks`). The ordnance spec says this. This spec still lacks it.
- "Purpose": the spec counts four slices. The code and later specs have five,
  with stasis as slice 5.

### docs/superpowers/specs/2026-11-14-ordnance-design.md

- Superseded, not updated: the death effects, the acid trail and the "Death"
  section describe vanilla entities on `ao-tamed`. The payload damage spec
  replaced them with a damage queue, hazards and look-alike prototypes
  (`shell/damage.lua`, `core/payloads.lua`).
- Loading: the recipe also needs one `ao-larva-rocket-casing`, and the loaded
  larva is an `ammo` item with a hidden artillery projectile. This comes from
  the launcher spec.
- "Loaded hatch" step 3: the code also sets `allow_try_return_to_spawner =
  false`. The spec names only the destroy-on-failed-command setting.
- "Death" step 3: the `on_object_destroyed` handler also moves the trail and
  feral cursors and clears `storage.trails` (later slices).
- "Tamed force": `shell/tamed.lua` also makes the feral force and handles the
  64-force limit. `on_force_reset` and `on_forces_merged` are not in this spec
  (feral spec).
- "Acid trail": the spec says a fixed interval, one puddle per monster. The code
  runs a batched cursor (`Balance.trail_batch` 5, `acid_trail_ticks` 60). The
  launcher spec covers the batch.
- "Machines": the incubator and chamber looks fall back to
  `assembling-machine-2` (`data.lua:15-20`). The spec states no fallback.

### docs/superpowers/specs/2026-11-15-stasis-design.md

- "Architecture": `data.lua` merges the lifecycle and ordnance lists into one
  `sources` list and calls `Stasis.prototypes(sources, kinds)`
  (`data.lua:59-83`). It wraps both lists in `Stasis.weighted(...)` first. The
  explicit item weights (`lift_weight / stack_size`) appear in no spec, though
  the cryo spec calls them "slice 5".
- "Terms" and "Architecture": one fixed ward with no kinds list. The code has
  `Stasis.BASE` and `Stasis.CRYO`. Superseded by the cryo refactor, not updated.
- Status line: the spec still says "draft for review". The ward is built and
  merged.

### docs/superpowers/specs/2026-11-15-cryo-ward-design.md

- "Calls for the maintainer": the cryo icon tint is `{ r = 0.6, g = 0.85, b = 1
  }`. The code uses a colder blue, `{ 0.3, 0.55, 1 }`
  (`core/prototypes/stasis.lua:21-24`). A code comment says the colder blue
  makes the two icons easy to tell apart, because the base ward tint is already
  `{ 0.55, 0.8, 1 }`. The maintainer accepted the spec value, so this needs a
  call.
- "In-game tests": the Nauvis half should run the recipe in a plant and check
  `products_finished` is 0 after 600 ticks. `tests/ingame/cryo_test.lua:309-327`
  checks only the surface conditions, because the game does not check them when
  a script sets a recipe. This matches the known gap that a script or blueprint
  can craft the ward off Aquilo.
- "Proposals": the signature is `Stasis.kinds({ space_age, has })`. The code
  also takes `pressure`, as "Architecture" says. The two sections disagree.
- "Architecture": `Stasis.CRYO.needs` checks nine `data.raw` entries. The spec
  lists five and only half describes the rest. Minor.

### docs/superpowers/specs/2026-11-14-launcher-design.md

- "Architecture", "Testing" and "Risks" still name `core/flare.lua` and a flare
  `shot_category` job in `data-final-fixes.lua`. Neither exists. The spec itself
  records that the maintainer dropped the change on 2026-11-14. The spec text is
  stale.
- "Acid trail batching": the code also gates each pass with `Trail.start` once
  per 60 ticks and keeps `storage.trail_next_tick` (`core/trail.lua:46-52`). The
  spec names two storage fields, not three.
- "Machines": `min_range = 8`, `max_health = 1000`, `heating_energy = "200kW"`
  and `mining_time = 0.5` are in no table.
- Superseded, not updated: "Landing" gives a 35 damage blast against forces at
  war, never the tamed force. The payload damage rules replaced this.
- `core/launcher.lua` has `leftovers`, `after`, `gun`, `levels` and
  `is_range_tech`, which the spec does not name. Minor.

### docs/superpowers/specs/2026-11-14-feral-design.md

- "Failed commands": `FeralShell.completed` (`shell/feral.lua`) ignores every
  distracted event, success included. The spec covers only a distracted fail.
- The stored field `entry.hunting` tells a failed hunt from a failed wander. The
  spec lists the other entry fields but not this one.
- "Architecture" says that `Forces.earns_loot` does not change. It now has an
  explicit feral guard (`core/forces.lua:38`).
- `core/feral.lua` has `player_counts` and `marked`, and caps the unstable
  chance at 1. Minor.

### docs/superpowers/specs/2026-11-15-payload-damage-design.md

- "Architecture": `data.lua` should pick the looks for the look-alikes. The code
  builds them in `data-final-fixes.lua:25-36`, so it copies after other mods.
  The code looks intentional, and the spec is stale.
- "Hazards": the target budget counts each damaged target. `Damage.hit` also
  counts a sticker as a target, so acid hazards spend the budget faster. A test
  pins this ("a sticker counts as one more target of its hit"), so the spec is
  the stale side.
- "Old saves": the spec says that `on_init` and `on_configuration_changed`
  create the hazard and detonation cursors. `Damage.ensure_storage` leaves them
  nil, which works as the start, and it also runs lazily. Same behaviour.
- `Forces.attacker` (natives deal a same-force hit when friendly fire is off) is
  in the spec only as a probe fallback. It is the built rule after the probe.
- The trail hit passes the monster as its `cause`. The spec says only that it
  skips the monster.
- Guards against other mods removing a damage type or sticker, the fresh-table
  reset of drained queues, and the force on look-alikes are in no section.
  Minor.

### docs/superpowers/specs/2026-11-12-repo-and-ci-design.md

- "Layout" and "The pinned Factorio version": the spec puts the factorio-test
  zip in `tests/ingame/vendor/` and has `make ingame` download it. The code
  vendors it in `tools/vendor/` and copies it (`tools/ingame.sh:9,37`). CI
  caches only the server. The spec is stale.
- "Make targets": `make ingame` takes a `MODE=` argument that the spec does not
  name.
- "Layout": `tools/` holds `api.py`, `coverage_floor.py`, `factorio_version.py`
  and `ingame.sh`, with their tests. The spec does not list them.
  `coverage_floor.py` and `factorio_version.py` appear in no spec.
- "CI", job `pr`: the spec names two checks. `tools/pr_checks.py:62-115` also
  limits the title to 72 characters and checks the "Review angles" verdicts,
  with `no-review` and Dependabot bypasses. CLAUDE.md and the PR template
  describe this. No spec does.
- "The changelog rule": the spec counts every shipped file except
  `changelog.txt` as mod code. `tools/package.py:56-58` also exempts `LICENSE`
  and `tests/`. The spec text is imprecise.
- "Version rules": `tools/check_version.py` also checks `info.json` keys,
  `factorio_version`, the dependencies and the version format (lines 20-43). In
  tag mode it fails while Unreleased has entries (lines 62-64). The spec names
  none of this.
- "Local gates": the spec says the Claude hook matches Bash commands that
  contain `git commit`. The hook runs on every Bash call and
  `tools/review_stamp.py` filters. Same effect, different mechanism.
- "CLAUDE.md": the real file adds reviewer counts, review angles and rounds,
  `make api`, Serena and release rules. The spec is stale.
- "Testing this project": the `math.random` rule also covers `shell/` in
  `spec/architecture_spec.lua`. The code is stricter.
- `.ste-allow`: many entries use whole-folder globs. The spec implies one rule,
  one file, one reason. Looser use, not a violation.

### docs/superpowers/specs/2026-11-13-lua-tooling-design.md

- "Out of scope" and "The agent": the spec says there is no API search tool.
  `tools/api.py` and `make api NAME=<name>` now exist, and CLAUDE.md uses them.
  A later change superseded the spec, and nobody updated it.
- "Make targets": the `lua` recipe adds a log path, a `luacov` run and a Lua
  path setup with a busted fallback. The spec names none of them. Harmless.
- "Testing": the spec plans two marker tests in `test_gates.py`. The code has
  five, including `test_styluaignore_lists_every_luacheck_exclusion`. The code
  is ahead.
- "False positives": checked by hand. One inline exception exists
  (`duplicate-set-field`), well under the limit of five per code.
