# Design document: Stage 8 and review rounds 2 and 3

## Stage 8

Resolved: stasis ward via plain recipes. One launcher. Abomination
artillery. Research order and core vs planet branches. Slot caps. Payload
set. Technical risks. Non-goals. Status ticks. Eggs vs larvae. Open
questions merged. Feed defined. Converted units.

## Stage 8: 🔴 Blocker

- **1.** Still no Alternatives Considered section. Now cheap to write: one
  launcher vs gun-turret ammo or the rocket turret. `script` vs
  `create-entity`. Plain units vs linked-chain demolisher. Stasis recipes vs
  a script container. Item list vs `item-with-tags`.

## Stage 8: 🟡 Major

- **2.** The revision multiplies prototypes: each loaded larva also needs a
  warded, a rocket and a shell version, so about 117 × 4 items at one slot.
  Name it as a risk.
- **3.** Spoiled-larva danger contradicts the force rule: a spoiled loaded
  larva "starts on your side", so it would not destroy a production line.
  Either it starts feral or soften the claim.
- **4.** Missing research edge: facehuggers need embryos, embryos need the
  extractor (Interbreeding), but Facehuggers depends only on Stasis ward.

## Stage 8: 🟢 Nit

- **5.** Lavapod's extra slot "up to the cap of 3" means nothing when its
  parents already cap at 3.
- **6.** Bigger hosts has no roadmap version. Pheromones node has no science
  pack.
- **7.** Lifecycle diagram routes the facehugger into the loaded monster
  node.
- **8.** How a captured worm or hatchling becomes an egg is unclear.
- **9.** Non-goal "A new turret for Space Age" reads badly next to the larva
  launcher.
- **10.** Version 1 still ships all three feral triggers (kept by the
  maintainer's choice).

## Round 2: design critic re-audit

No Blockers, 4 Majors, 5 Nits. Round 1 findings 2 to 10 and Nits 11, 12 and
14 resolved. The missing Alternatives section was accepted as a scope
decision, then added as "Decisions and rejected alternatives".

## Round 2: design critic re-audit: 🟡 Major

- **1.** Hybrid larva cost backwards: at one hybrid egg per larva, hybrids
  are cheaper than plain larvae. Resolution: turned into an open question
  for the maintainer.
- **2.** Item count ignores warded, rocket and shell items. Resolution:
  added an "Ammo count" risk.
- **3.** "No entity prototypes" conflicts with hybrids, hatchlings, worms
  and pentapods. Resolution: limited to version 1, added a "Hybrid
  mechanics" risk.
- **4.** Facehuggers researchable before embryos exist. Resolution:
  Interbreeding is now a prerequisite.

## Round 2: design critic re-audit: 🟢 Nit

- **5.** Non-goal vs the Abomination launcher: reworded to the rocket
  turret.
- **6.** Field name: the reviewer named `result_is_always_fresh`. The 2.1
  API defines `always_fresh` on ItemProductPrototype and has no
  `result_is_always_fresh`, so the doc keeps `always_fresh`. Warded item
  expiry: open question.
- **7.** Embryo shipping has no recipe back to an egg: open question.
- **8.** Tesla tech added to More payloads. Converted unit radius depends on
  size only. Spitpod trait kept as designed.
- **9.** Captive spawner egg: open question. Shared PvP feral force: already
  open (PvP rules).

## Round 3: design critic, final

No new Blocker or Major findings. Every round 2 finding is fixed or is an
open question. Small notes applied: "one larva launcher" wording, a stray
blank line in the open questions. Not applied: Facehuggers does not require
Larva rockets (the hand-thrown capsule works without it).

## Stage 8 follow-up

- Blocker 1 (alternatives): added.
- Major 2 (prototype count): added as a risk.
- Major 3 (spoiled-larva force): the contradicting sentence removed. Open
  question.
- Major 4 (facehugger research edge): added.
- Nits 5 to 9: applied, or open questions (first egg for captured animals).
  Nit 10 (three feral triggers in version 1): kept by the maintainer's
  choice.
