# Slice 4 feral spec: EGM review

Target: `docs/superpowers/specs/2026-11-14-feral-design.md`. The agent
wrote the spec while the maintainer was away. Stages 5 to 8 ran on the
draft of 2026-11-14. Two more rounds checked the rewrites on
2026-11-15.

## Round 1 reviewers

| Stage | Reviewer | Verdict |
| --- | --- | --- |
| 5 | Zoom out | 1 Blocker, 4 Major, 5 Nit |
| 6 | Comprehension | 7 Major, 10 Nit |
| 7 | Design critic | 1 Blocker, 5 Major, 6 Nit |
| 7 | Style | 7 Major, 6 Nit |

## Round 1 findings and what changed

- **The tamed and feral forces could end at peace** (zoom out and design
  critic, Blocker). `Forces.cease_fire` gave peace to any unknown force,
  and `create_force` raises `on_force_created` at once. Fixed:
  `Forces.cease_fire` leaves the feral force alone, and one feral rule
  owns every feral relation.
- **The idle clock took over the monsters' AI** (zoom out, design
  critic). A 10 s wander command ran the checks. It skipped fighting
  monsters, could loop on failed commands and needed a restart in old
  saves. Fixed: a batched pass on its own cursor reuses `core/trail.lua`,
  as `docs/architecture.md` asks.
- **Feral payloads stayed on the tamed force** (zoom out, design critic).
  Natives killed by a feral blast would drop nest loot. Fixed: death
  effects and the acid trail take the entry's force.
- **Feral monsters went dormant** (zoom out, design critic,
  comprehension). Fixed in round 2 and round 3, see below.
- **The feral radius ignored monster size** (zoom out, comprehension).
  `docs/design.md` asks for it. Fixed: one tile per size step.
- **"Other-force players" was unclear** (comprehension, design critic,
  style). Fixed: a player counts when connected, with a character, on a
  force at cease-fire with the tamed force.
- **The unstable roll assumed a fixed interval** (comprehension, design
  critic). Fixed: it rolls for the time since the last check.
- **The replacement fallback clashed with the cleanup** (comprehension).
  Fixed in round 2, see below.
- **The 64-force limit** (design critic). Fixed: with a full limit the
  mod logs it and turns the feral triggers off.
- **Terms and style** (comprehension, style). Fixed: links to the slice
  1 to 3 specs, defined terms, one name per check, calibrated claims.

## Round 2

The design critic and the zoom out reviewer checked the rewrite. Neither
found a Blocker.

- **Feral targeting did not match the design** (design critic, Major).
  `docs/design.md` says feral monsters attack the nearest target,
  including the player. Fixed: a feral monster hunts the nearest enemy
  entity within 64 tiles.
- **Game-feel calls were missing from the maintainer table** (zoom out,
  Major). Fixed: five new rows.
- **The replacement fallback was set to be built anyway** (zoom out,
  Major). Fixed: it is built only if the probe shows that a force change
  fails. It now creates the new unit first.
- **Nits, fixed.** Any entity of the natives counts for idle, so the
  Space Age natives count. The force-limit switch tests the force each
  time. The size step comes from the species lists.

## Round 3

The design critic checked the round 2 changes. No Blocker. Two new Major
findings, both fixed in the text. This was the last round, so no
reviewer checked these fixes again. The build waits for the maintainer.

- **A wandering feral monster never hunted again.** An endless wander
  kept a command forever, so the batch check never searched again.
  Fixed: the wander ends after `rewander_ticks`, and the next check
  searches again.
- **An unreachable target could loop.** A target across water made the
  attack fail, and the next check picked the same target. Fixed: a
  failed attack ends in a wander, and `entry.last_target` stops a second
  try at the same target. An in-game test covers it.
- **Nits, fixed.** Risks lists the cost of the target search, and the
  probe times it. Acid streams and fires of the natives can reset the
  idle clock, which the design accepts.

## Rulings

- **One rule per force pair.** A second core function owns the feral
  relations. Cost if wrong: one more function.
- **Batch check on a cursor.** Five monsters per tick, a pass at most
  every 10 s. Cost if wrong: above 3000 monsters each one is checked less
  often.
- **The first check never rolls.** Cost if wrong: a tiny delay.
- **Feral monsters hunt within 64 tiles,** then wander for 10 s and
  search again. Cost if wrong: it may feel harsh.
- **Feral entries with a command skip the batch work.** Cost if wrong:
  slower idle checks at large counts.
- **Natives for idle are any entity of the natives.** Cost if wrong:
  passing acid and fire count too.
- **The size step comes from the species lists.** Units from other mods
  get step 0. Cost if wrong: those units get the base radius.
- **The force-limit guard covers the feral force only.** Cost if wrong:
  setup still fails if the limit is full before the tamed force exists.
- **The pheromone flare is out of scope.** Cost if wrong: the maintainer
  may want it sooner.

## Calls for the maintainer

The build uses these defaults until the maintainer decides:

- The unstable chance: 0.2% per minute per payload.
- Idle: no entity of the natives within 32 tiles, for 5 minutes.
- Only players with a character count. Drivers count at their vehicle.
- Feral blasts hurt players and their buildings.
- A "Feral!" text shows for 3 s.
- Feral monsters hunt the nearest enemy entity within 64 tiles.
- Feral kills drop no nest loot.
- A tamed monster near natives gets a fresh attack command when it has
  none.
- With a full force limit, the feral triggers turn off with a log line
  only.
- The feral radius grows by one tile per size step (8 for a behemoth).
