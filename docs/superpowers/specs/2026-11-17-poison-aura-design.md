# Abominable Ordnance: the poison aura

> The section "Changes after the play test" at the end replaces
> the `spare` field, the target limit of 20 and the puff size below.

Date: 2026-11-17. Status: approved by EGM after three rounds. The agent
(Claude) wrote this spec from the maintainer's decisions of 2026-11-17
and from the payload damage spec
(`docs/superpowers/specs/2026-11-15-payload-damage-design.md`). EGM is
the project's spec review by reviewers that see only the spec and the
code.

"Answers" lists what the maintainer already decided. "Proposals" lists
the agent's own calls. "Calls for the maintainer" lists the one call the
maintainer should confirm, with the default the build uses.

## Purpose

`docs/design.md` gives the poison payload a live effect, "Small poison
aura", in the "Ordnance loading" table. The mod has no such effect: only
the acid payload acts while its monster lives. The drift report
(`docs/superpowers/reviews/2026-11-17-abominable-ordnance-docs-drift-report.md`)
found the gap, and the maintainer put the aura in release 1.0.0.

This spec adds the aura. A loaded poison monster hurts living things near
it once a second (with up to 300 such monsters, see "Trail pass"), and a
small green puff shows where it is.

Success has two parts. A poison monster's aura hurts a native biter and a
tree within 3 tiles, and it spares its own side and buildings. With 300
poison monsters in a forest, this mod's line in the game's time usage
display stays below 1 ms a tick.

## Terms

- **Loaded monster.** A unit that hatched from a loaded larva. The shell
  tracks it in `storage.loaded`, with its payloads.
- **Tamed force.** `ao-tamed` holds loaded monsters on the player's
  side. It has a cease-fire with every player force and is at war with
  the natives (`enemy`) (`core/forces.lua`).
- **Feral force.** `ao-feral` holds loaded monsters that turned on the
  player. It is at war with every force except `neutral` and itself.
- **Feral radius.** A player who comes this close to a tamed loaded
  monster turns it feral. It is 5 tiles for a one-payload small monster
  and grows with monster size (`Feral.radius` in `core/feral.lua`,
  `Balance.feral.radius = 5`).
- **Live effect.** What a payload does while its monster lives. Today
  only acid has one: the acid trail.
- **Acid trail.** Once a second, an acid monster drops a puddle
  look-alike (`Names.PUDDLE`, `"ao-acid-puddle"`, a copy of the vanilla
  small acid splash that deals no damage) and deals one acid hit of 5
  damage in radius 1. The hit spares the monster itself.
- **Trail pass.** The batched pass in `control.lua` that runs the acid
  trail. It visits `Balance.trail_batch` (5) monsters a tick from
  `storage.trails`. A new pass starts at most once per
  `Balance.acid_trail_ticks` (60 ticks). So each monster gets one visit a
  second while the list holds 300 monsters or fewer. With more, a pass
  takes longer than a second, and each monster's visits slow down.
- **Aura.** The live effect of the poison payload that this spec adds.
- **Puff.** `ao-poison-puff`, the look-alike that shows the aura. It
  deals no damage.
- **Hit.** One call of `Damage.hit` (`shell/damage.lua`): damage of one
  payload type in one radius. `Damage.targets` picks the targets that the
  payload's rule allows, with one `find_entities_filtered` search. `skip`
  spares one entity. This spec adds `spare_force` and `limit` (see
  "Proposals").
- **Poison rule.** Poison hurts organic targets only: units, characters,
  trees, and in Space Age also plants and demolishers, of any force. It
  never hurts buildings or rocks (payload damage spec).
- **Test build.** The unreleased build that the maintainer plays before
  1.0.0. It keeps version 0.1.0 in `info.json`. The version moves to
  1.0.0 only at the release.
- **Old-save entry.** A `storage.loaded` entry from a save before the
  payload damage work can still hold a field `entry.trail` with the
  vanilla puddle name. The rebuild clears it, and `Damage.live` ignores
  it.

## Answers

The maintainer decided these on 2026-11-17.

| Question | Answer |
| --- | --- |
| Release | The aura ships in 1.0.0 |
| Role | A real weapon, not only a visual |
| Damage | 3 poison damage once a second |
| Radius | 3 tiles, less than the smallest feral radius of 5 tiles |
| Targets | The poison rule, except that the aura spares its own side |
| Own side | The aura spares every entity of the monster's own force, the monster included. A tamed monster spares tamed monsters and hurts feral ones. A feral monster spares feral monsters and hurts tamed ones |
| Look | A small green puff around the monster once a second |
| Build | Extend the trail pass. Do not add a second pass |

Why spare the own side: an aura acts every second for the whole life of
the monster, unlike a death effect. Loaded monsters travel in packs. A
small biter has 15 health, so a neighbour's aura would kill it within
seconds. The death cloud keeps the strict poison rule: it still hurts
the monster's own pack.

## Facts found during design

- `Damage.hit` already takes `skip`, one entity that the hit spares. It
  has no way to spare a whole force.
- `Damage.targets` already filters by the payload's target classes. A
  poison hit never finds a chest or a rock.
- `Damage.hit` already picks the attacker for each target through
  `Forces.attacker`. That decides who deals the damage when friendly fire
  is off. It does not decide who takes damage, so sparing a force needs
  `spare_force`.
- `Payloads.trail(names)` returns the trail look-alike and the payload
  name of the first payload with a `trail` field. `control.lua` uses it
  when a loaded monster hatches. `shell/setup.lua` uses it in the rebuild
  of `storage.trails` on a configuration change.
- `Damage.trail(entry, force)` creates the puddle look-alike and deals
  the trail hit with `cause = unit` and `skip = unit`. The trail pass
  calls it with the force from `FeralShell.force_of(entry)`.
- `Balance.payload_damage` holds one table per effect, for example
  `trail = { damage = 5, radius = 1 }` and `poison = { damage = 8, radius
  = 11, ticks = 1200 }`.
- The vanilla `poison-cloud` (`smoke-with-trigger`) draws its own smoke
  with `particle_count = 16` and `particle_spread = { 3.78, 2.27 }`. Its
  `created_effect` adds 21 `poison-cloud-visual-dummy` smokes, 4 to about
  11 tiles away, and plays the capsule sound. The smoke sprite is 152 by
  120 pixels, about 4.7 by 3.7 tiles. `duration` is 1200 and
  `fade_away_duration` is 120 (Factorio 2.1.24 `entities.lua`).
- The game runs `on_configuration_changed` when a mod's version changes,
  not when a build of the same version changes. The test build keeps
  0.1.0, so the rebuild of `storage.trails` runs for old saves only at
  the move to 1.0.0.

## Alternatives considered

| Alternative | Why not |
| --- | --- |
| A separate aura pass with its own list, cursor and timer | It doubles the batch code and the stored fields, for the same cost per tick |
| An `aura` field beside acid's `trail` field, with its own lookup | Two lookups at hatch and in the rebuild, and two near-identical shell functions. The version 2 payloads also have live effects (fire trail, slowdown, tesla arcs), and each would add another field |
| A hazard (the timed area damage of clouds and pools) with a moving anchor | A hazard has a fixed position and a lifetime. A moving anchor needs a visit to the monster anyway, which is the trail pass |
| A vanilla cloud entity that follows the monster | No prototype follows a unit. The script would create one every second anyway, and vanilla damage ignores the payload rules |
| Strict poison rule, the aura hurts every monster | Packs of small monsters would kill each other (see "Answers") |
| Visual only | `docs/design.md` makes the aura part of the poison payload's attack. A visual has no effect on play |

## Proposals

- **One live effect field per payload.** A payload in `core/payloads.lua`
  gets an optional `live` table in place of the acid-only `trail` field.
  The table below gives its fields. Acid keeps the same behaviour as
  today.

| Field | Meaning | Acid | Poison |
| --- | --- | --- | --- |
| `lookalike` | The entity to create at the monster's position | `Names.PUDDLE` | `Names.PUFF` |
| `balance_key` | The key of its damage and radius in `Balance.payload_damage` | `"trail"` | `"aura"` |
| `spare` | `"self"` spares the monster only. `"force"` spares every entity of the monster's force | `"self"` | `"force"` |

- **`Payloads.live(names)`** replaces `Payloads.trail(names)`. It returns
  two values: the `live` table and the payload name, of the first payload
  in `names` that has a `live` table, or nil. `control.lua` and the
  rebuild only test the result for nil. `Damage.live` uses both values.
  Version 1 monsters carry one payload. Expand Orifices, the version 2
  research for more payload slots, can change it to return a list.
- **`Damage.hit` gets `spare_force`.** It is a force name. The hit skips
  every target of that force. `skip` stays for the single entity.
- **`Damage.hit` gets `limit`.** It passes `limit` to the
  `find_entities_filtered` search in `Damage.targets`, so one hit finds at
  most that many entities. The aura uses `max_targets = 20`. The trail
  pass makes at most 5 hits a tick, so the aura deals at most 100 damage
  calls a tick, in a forest or in a crowd.
- **The search leaves out the spared force.** `Damage.targets` passes
  every force except `spare_force` to the search, so the monster's own
  pack never uses up the limit. The search order is the game's own and
  the same for every player, so the limit is multiplayer-safe. (The
  first draft counted the spared force inside the limit. The code review
  found that a dense pack could then fill all 20 slots.)
- **`Damage.live(entry, force)`** replaces `Damage.trail(entry, force)`.
  It creates the look-alike on `force` when the prototype exists. Then it
  deals the hit with `cause = unit`, `skip = unit` and the `limit` from
  the balance table, if any. When `spare` is `"force"`, it also passes
  `spare_force = unit.force.name`. The hit force (from
  `FeralShell.force_of(entry)`) and the unit's force match, because a
  monster that turns feral gets both at once. The spared side comes from
  the unit, so it stays right even if they ever differ.
- **`storage.trails` keeps its name.** It now lists every monster with a
  live effect. A rename would need a migration and gains nothing.
  Comments at `storage.trails` in `shell/setup.lua`, at the trail pass in
  `control.lua` and at `Balance.acid_trail_ticks` say that the pass runs
  every live effect.
- **The puff.** `Names.PUFF = "ao-poison-puff"`. The existing `cloud`
  builder in `core/prototypes/ordnance.lua` gets parameters for the name
  and the shape. It builds both the cloud look-alike and the puff from
  the vanilla `poison-cloud`. When the vanilla cloud is missing, there is
  no puff and the aura still hits. The table below gives the puff's
  fields.

| Field | Puff | Why |
| --- | --- | --- |
| `action`, `created_effect` | None | No damage, no extra smokes and no sound |
| `particle_count`, `particle_spread` | 4, `{ 1.5, 0.9 }` | Aims to keep the smoke near the 3-tile aura. Each sprite is larger than the spread, so the probe confirms the look |
| `duration`, `fade_away_duration`, `spread_duration` | 60, 30, 20 | One second. The game requires the fade to fit in the duration |

- **Old test-build saves.** A test-build save with poison monsters gives
  them no aura until 1.0.0 changes the version. The maintainer starts new
  maps for the test in the game, so the build adds no lazy repair.

## Calls for the maintainer

| Call | Default the build uses |
| --- | --- |
| The puff's look | 4 smoke particles within 1.5 tiles, for 1 s. The probe shows it, and the maintainer can ask for a larger or smaller puff |

## Game content

| Name | Type | Notes |
| --- | --- | --- |
| `ao-poison-puff` | `smoke-with-trigger` | A copy of the vanilla `poison-cloud`, shaped as in "Proposals". Hidden |

`Balance.payload_damage.aura = { damage = 3, radius = 3, max_targets = 20 }`.

No new item, recipe or research.

## Runtime behaviour

1. A loaded poison monster hatches. `control.lua` adds its unit number
   to `storage.trails`, because `Payloads.live` returns a live effect.
2. The trail pass visits the monster once a second (see "Trail pass" for
   more than 300 monsters).
3. `Damage.live` creates `ao-poison-puff` at the monster's position, on
   the force from `FeralShell.force_of(entry)`.
4. It deals one poison hit of 3 damage in radius 3. The hit skips the
   monster and every entity of the monster's force. `Damage.targets`
   already leaves out buildings and rocks. Characters of every player
   force take damage, as from the death cloud.
5. A monster that turns feral moves to `ao-feral`. The next aura hit
   spares feral monsters and hurts tamed ones.
6. When the monster dies or leaves, `on_object_destroyed` removes it
   from `storage.trails`, as for acid monsters today.

The acid trail behaves as before.

## Architecture

| File | Change |
| --- | --- |
| `core/names.lua` | Add `PUFF` |
| `core/balance.lua` | Add `payload_damage.aura`. Comment at `acid_trail_ticks` |
| `core/payloads.lua` | Replace `trail` with `live` on acid, add `live` on poison, replace `Payloads.trail` with `Payloads.live` |
| `core/prototypes/ordnance.lua` | The `cloud` builder takes a name and a shape. `Ordnance.lookalikes` also returns the puff |
| `shell/damage.lua` | `Damage.hit` takes `spare_force` and `limit`, and `Damage.targets` takes `limit`. Their comments say so. `Damage.live` replaces `Damage.trail` |
| `control.lua` | Call `Payloads.live` and `Damage.live`. Comment at the trail pass |
| `shell/setup.lua` | The rebuild uses `Payloads.live`. Comment at `storage.trails` |
| `locale/en/*.cfg` | An entity name for `ao-poison-puff`. `spec/locale_spec.lua` checks that every new prototype has one |
| `spec/core/payloads_spec.lua`, `spec/core/prototypes/ordnance_spec.lua` | Rename the `Payloads.trail` tests. Add the puff to the `Ordnance.lookalikes` tests |
| `tests/ingame/damage_test.lua` | Rename the `Damage.trail` tests to `Damage.live`, with the same behaviour. Keep the old-save `entry.trail` test |
| `tests/ingame/ordnance_test.lua` | Read `payload.live` in place of `payload.trail`. Invert "a poison monster is not in the trail list": a poison monster is now in it. "A loaded monster attacks a nearby spawner" destroys its poison monster at the end |

The core stays pure. `core/payloads.lua` returns data, and the shell acts
on it.

## Testing

### Unit tests (busted)

- `Payloads.live` returns the poison live effect with `spare = "force"`
  and `balance_key = "aura"`.
- `Payloads.live` returns the acid live effect with `spare = "self"` and
  the same look-alike as the old trail.
- `Payloads.live` returns nil for the explosive payload and for an
  unknown name.
- `Ordnance.lookalikes` returns `ao-poison-puff` with no `action`, no
  `created_effect`, `hidden = true`, `particle_count = 4`, `duration =
  60` and `fade_away_duration` at most `duration`.
- `Ordnance.lookalikes` returns no puff when the vanilla cloud is
  missing. The existing tests of the list's names and count include the
  puff.
- `Balance.payload_damage.aura` is 3 damage in radius 3, with at most 20
  targets.

### In-game tests (factorio-test)

Each new test destroys its monsters, so `storage.trails` stays small for
the trail tests that wait for a pass.

- A tamed poison monster's aura hurts a native biter and a tree within 3
  tiles. A target counts as hurt when it lost health or no longer
  exists, as the `hurt` helper in `damage_test.lua` checks.
- The aura hurts a player-force character within 3 tiles.
- The aura spares a chest, the monster itself and another tamed monster
  within 3 tiles.
- `Damage.hit` with `spare_force` skips every target of that force and
  hits the others.
- `Damage.hit` with `limit = 2` among 5 trees damages at most 2.
- A feral poison monster's aura hurts a tamed monster and spares a feral
  one.
- The aura does not reach a native biter 5 tiles away.
- The aura still hits when the puff prototype is missing.
- The acid trail tests keep their behaviour, under the new names.
- A save whose `storage.trails` lacks a poison monster gets it from the
  rebuild in `on_configuration_changed`.

## Delivery

The plan holds the steps. Two parts matter for the design:

- **Probe.** Before the build, a throwaway copy of the mod checks the
  puff. It must load, look right next to a small biter and make no
  sound. It also checks the 1 ms target with 300 poison monsters in a
  forest. Above it, the maintainer decides between a lower
  `max_targets` and a larger interval. The probe is not committed.
- **Review.** One pull request. It changes shared core modules, and the
  reviewer table in the project's `CLAUDE.md` asks for 4 reviewers for
  those. The review angles for
  `control.lua` and `shell/` (multiplayer safety, save compatibility,
  compatibility with other mods), for `core/prototypes/` (compatibility
  with other mods and Space Age), for event handlers (performance) and
  for tests (test quality) apply.

## Risks

| Risk | Answer |
| --- | --- |
| Many poison monsters cost UPS. A radius of 3 finds about 9 times the targets of the acid trail's radius of 1, and forests have many trees | The pass visits 5 monsters a tick, and `max_targets` caps each hit at 20. The probe measures 300 monsters in a forest against 1 ms a tick |
| More than 300 monsters with live effects | Each monster's visits slow down, so the aura deals less damage a second. Accepted, as for the acid trail |
| A poison monster near a player's character hurts it | Wanted by the poison rule. The 3-tile radius is inside the feral radius, so a player that close also turns the monster feral. In multiplayer, this applies to the characters of every player force |
| Another mod removes the vanilla poison cloud | No puff. The hit still applies |
| Another mod removes the poison damage type | `Damage.hit` already deals no damage then |
| A test-build save with poison monsters | No aura until 1.0.0. Accepted (see "Proposals") |

## Changes to other documents

- `docs/design.md`, "Ordnance loading": the aura spares the monster's own
  side. Line 60 ("such as an acid trail") also names the poison aura.
- `docs/architecture.md`: the passages on `storage.trails` and the trail
  pass say that the pass runs every live effect.
- `README.md`: remove "except the poison aura" from the status.
- `ROADMAP.md`: tick "Poison aura".
- `CHANGELOG.md`: an entry under Unreleased, Added.

## Out of scope

- More than one payload per monster (Expand Orifices, version 2).
- Live effects of the version 2 payloads.
- A mod setting for the aura.
- A lazy repair of `storage.trails` for test-build saves.

## Changes after the play test

The maintainer's play test on 2026-11-18 changed three things:

- The puff showed about 1 tile wide. It now has `particle_count = 8`
  and `particle_spread = { 3, 1.8 }`.
- With 300 monsters in a forest, the time usage reached about 1.2 ms
  while trees took damage. The aura's `max_targets` is now 8, not 20.
- The code drops the `spare` field. The acid trail now spares its own
  side too, so every live effect spares the monster's force.
- A death effect now spares the loaded monsters of its own force that
  carry the same payload, through `spare_kin` on `Damage.hit`. The
  launcher's landing blast does not set it, so it spares nobody.
