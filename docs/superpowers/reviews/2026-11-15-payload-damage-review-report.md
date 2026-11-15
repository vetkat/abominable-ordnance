# EGM review: payload damage targets spec

Date: 2026-11-15. Spec:
[2026-11-15-payload-damage-design.md](../specs/2026-11-15-payload-damage-design.md).
Reviewers: zoom-out (simplicity and scope) and design critic, in three
rounds and a final check.

Verdict: approved. No Critical or Important finding is open.

## Round 1

The agent applied these rulings:

- The trail skips the monster that dropped it.
- The trail deals one acid hit in radius 1 per puddle, not a hazard.
- Organic means the `breaths-air` flag. Rock means the rock flag of the
  deconstruction filter.
- The trail comes from `entry.payloads` at each tick.
- Deaths go through a detonation queue in `storage.detonations`.
- Clouds and pools are hazards in a batched pass that catches up.
- Look-alike prototypes show the vanilla effects and deal no damage.
- The probe gets a fallback to the `enemy` force.
- PR 1 removes `Forces.blast_hits` and its slice 3 test.

## Round 2

| Finding | Severity | Fix |
| --- | --- | --- |
| PR 2 too big, "can move" undefined | Important | Three PRs. "Mobile target" means `unit` or `character` |
| A water landing calls `Payloads.on_death` directly | Important | It goes through the detonation queue with the tamed force, with a test |
| `shell/damage.lua` and the shell rule of `docs/architecture.md` | Important | The in-game tests call `Damage.class_of`. The PR updates the example in `docs/architecture.md` |
| The rock flag exists only on a `simple-entity` | Important | The shell reads it only there |
| No probe row for the launcher's force against a tamed monster | Important | A probe row with a fallback |
| Hazard work per tick has no limit | Important | `hazard_hits` per tick, a cursor that carries over, no search without a due interval |
| Missing calls: feral kills, trail targets, probe fallback | Minor | Rows in "Calls for the maintainer" |
| Goal 4 overstates, "at load" unclear, duplicate rows | Minor | Reworded. The class sets are a module-level cache |

## Round 3

| Finding | Severity | Fix |
| --- | --- | --- |
| PR 1 does not say what poison and acid deaths do | Important | They go through the queue with the vanilla entities until PR 2 |
| The hazard pass can walk the whole table in one tick | Important | `hazard_visits` per tick, no hazard twice per tick, with a unit test |
| A hazard's first hit can go over the budget | Important | The detonation deals no hit. The hazard pass deals the first hit |
| "Total damage stays the same" fails against flat resistances | Minor | Says "before resistances" and names the effect |
| No probe row for the `neutral` force | Minor | Added |
| How the sticker goes on, and on a dead target | Minor | `create_entity` after a `target.valid` check |
| Shared `Trail` helpers, sticker once per summed hit, water landing force | Minor | Worded in the spec |

## Final check

The design critic confirmed both round 3 Important findings resolved,
with no new Critical or Important finding. Its one minor (the hazard
cursor after a partial batch) is fixed in the Architecture table.
