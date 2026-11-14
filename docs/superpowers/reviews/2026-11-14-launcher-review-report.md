# Slice 3 launcher spec: EGM review

Target: `docs/superpowers/specs/2026-11-14-launcher-design.md`. Stages 5
to 8 ran on the draft of 2026-11-14. Later rounds checked the rewrites.

## Round 1 reviewers

| Stage | Reviewer | Verdict |
| --- | --- | --- |
| 5 | Zoom out | 3 Major, 2 Nit |
| 6 | Comprehension | 3 Major, 8 Nit |
| 7 | Design critic | 1 Blocker, 5 Major, 3 Nit |
| 7 | Style | 4 Major, 9 Nit |

## Round 1 findings and what changed

- **No alternatives section** (design critic, Blocker, and style). Fixed: a
  new "Alternatives considered" table gives each rejected design and why.
- **The swap lost state** (design critic). Quality, wires, ammo freshness
  and the targeting setting were missing. Fixed: the swap lists what it
  keeps.
- **Missing build and force events** (design critic). Fixed: revive,
  clone, forces merged and force reset now call the swap. The swap does
  nothing when the level already matches.
- **Ghosts of levels 1 to 3 had no item** (design critic). Fixed: each
  level is `placeable_by` the launcher item.
- **The vanilla flare draws every ammo category** (design critic, zoom
  out, comprehension, style). The API settles it. Round 1 accepted it as a
  proposal. The maintainer then asked for separate remotes (see round 2).
- **The acid trail must be batched by this slice** (zoom out, design
  critic). `docs/architecture.md` asks for it. Fixed: a batched trail in
  its own pull request.
- **Idle monsters pile up** (design critic). Fixed: a Risks entry, with
  slice 4's idle rule as the answer.
- **The stored level copied the research state** (zoom out). Fixed: the
  level comes from the researches each time, and `storage` holds no copy.
- **The probe facts had no fallback** (comprehension). Fixed: a table
  gives a fallback for each fact. The order of blast and spawn is now a
  probe fact too (style).
- **Remote range per level, force relations, terms** (comprehension).
  Fixed: the range table gives both ranges for each level, and a "Terms"
  section defines the tamed force, level and swap.
- **The design.md change list** (zoom out). Fixed: it adds the `ao-land-`
  decision and the open question about artillery shells.
- **Style.** Fixed: "plenty of health" became "full health", vague and
  passive phrases were rewritten, and sentences were split.

## Round 2

The design critic and the zoom out reviewer checked the rewrite. Neither
found a Blocker.

- **A fast replace spills a launcher item** (design critic). With no
  player, the engine drops the old item on the ground: a free launcher on
  every swap. It also raises no destroy event. Fixed: the swap destroys
  and creates, and moves the ammo through a script inventory. A failed
  create restores the old launcher.
- **`kills` and `damage_dealt` don't exist on artillery turrets** (design
  critic). Fixed: dropped from the swap and the tests, and listed in
  Risks.
- **The trail cursor breaks when entries change** (design critic, zoom
  out). Fixed: `on_object_destroyed` moves the cursor before it removes
  an entry. A separate `storage.trails` holds only monsters with a trail.
  The handler runs every tick with a batch of 5, so up to 300 monsters
  keep a puddle once a second.
- **The level as a count** (design critic, nit). Fixed: the level is the
  highest finished range research.
- **`on_entity_cloned`** gives the new entity in `destination` (design
  critic, nit). Fixed.
- **A shared fast-replace group causes churn** (design critic, nit).
  Fixed: the levels have no group.
- **Batching in its own pull request, pheromone note repeated** (zoom
  out, nits). Fixed.

At the maintainer's request, round 2 also added "Separate remotes": the
vanilla flare gets `shot_category = "artillery-shell"`, unless another
mod adds artillery ammo of its own category.

## Rulings

- **The swap stays as designed.** The zoom out reviewer called it the
  largest piece of complexity. The maintainer chose it, and it sits in
  its own pull request that the rest of the slice does not need.
- **Swap details stay in the spec.** The zoom out reviewer suggested
  moving them to the plan. The round 2 bugs were in exactly these
  details, so the spec keeps them.

## Round 3

The design critic checked the round 2 fixes and the separate remotes. No
Blocker. Two new Major findings, both fixed. This was the last round, so
no reviewer checked these two fixes again. The maintainer reviews them
with the spec.

- **The swap's failure path was incomplete.** `destroy` can return
  false, and another mod's destroy handler can change the spot before the
  new launcher exists. Fixed: a branch for each failure, and the ammo is
  spilled on the ground with a log line when no launcher can be created.
  A core function decides each branch, so busted tests them.
- **"Artillery-type gun" was not defined.** Fixed: the scan reads the
  `gun` of every artillery turret and wagon, and both category fields of
  each gun.
- **Nits, fixed.** A Risks entry for mods whose `data-final-fixes.lua`
  runs later. The trail accepts that a monster can miss one pass.
