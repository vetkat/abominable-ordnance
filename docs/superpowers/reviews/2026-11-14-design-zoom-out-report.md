# Design document: Stage 5 zoom out report

## Zoom out reviewer

Context sufficiency passes. "A core module picks the unit from the enemy
evolution" (L359) matches `core/hatching.lua`. No Blockers, four Majors,
five Nits.

## Zoom out reviewer: 🟡 Major

- **1.** **Stasis ward: assembler packing conflicts with script packing
  (L241-244, L385-388).** An assembler recipe gives the script no per-item
  hook to read or write freshness. "Resumes where it stopped" (L44, L98,
  L242) forces the complex path. Options: weaken the promise (never spoils,
  unpacks fresh, or recipe inherits spoilage), or a script-managed stasis
  container. V1 item (L323): decide before planning.
- **2.** **V1 depends on an unanswered open question (L246-248, L319,
  L420).** V1 commits to a vanilla launcher but L420 still asks building vs
  gun-turret ammo. Two delivery paths (rocket turret in Space Age, launcher
  in vanilla) double the test matrix. Simplest: one mod launcher in both
  modes.
- **3.** **Control branch versions out of order (L286-292 vs L335, L341).**
  Pheromones (V3) comes before Facehuggers and the pacifier (V2). Also L260
  "Four branches converge" vs L256, L301-302.
- **4.** **One item per payload combination stops working at V2 (L314-316,
  L350-356, L330, L137-145).** Multi-slot makes "hundreds" of items. 5 × 8
  also leaves out 7 hybrids and the Abomination (about 13 × 8 single-slot).
  State the V2 boundary now: a whitelist of combinations or `item-with-tags`
  with script crafting.

## Zoom out reviewer: 🟢 Nit

- **5.** Too many feral triggers for V1 (L210-216, L320-321). Proximity plus
  spoiling already delivers the pillar. Consider proximity only in V1, idle
  and unstable after test games.
- **6.** Slot caps contradict (L143-145, L161, L173): spitters and worms
  uncapped. Lavapod +1 gives 4 against a max of 3.
- **7.** Facehugger converts go feral, but carry no payload, and the radius
  grows with payload count (L193-194, L222).
- **8.** Terminology: "Artillery eggs" (L283), "loaded eggs" (L333). "one
  per vanilla enemy family" includes hatchlings (L103). Launchers turn
  larvae, not eggs, into ammo (L238).
- **9.** Low-level details ("every 30 ticks", info.json flag) are not fixed
  requirements. Resolved questions listed twice (L392-414). PvP:
  `core/forces.lua` hard-codes one tamed force, so pass the owner force
  through V1 interfaces.

## Inventive catalyst

- **1.** 🟡 Abomination from artillery: "fires only from artillery or a
  dedicated launcher" (L175-176) vs "every species except the Abomination"
  (L249-250).
- **2.** 🟡 Research order vs version plan: Pheromones (V3) before
  Facehuggers and the pacifier (V2) (L286-292, L335, L341).
- **3.** 🟡 Linear chains block vanilla content: Interbreeding sits behind
  Pentapod breeding (Agricultural science), Facehuggers need Agricultural
  science, so Nauvis-only hybrids and facehuggers are unreachable without
  Space Age (L271, L289, L326, L397). Resolution: split each branch into a
  core for any planet plus planet leaves.
- **4.** 🟡 Loaded-larva item count: 13 species × 8 payloads is about 100
  items at one slot, thousands with multiple slots. L124 "any ammo" vs the
  fixed table. Lavapod +1 slot implies a 4th slot. Resolution: payload
  classes, or a script-driven chamber with tagged items.
- **5.** 🟡 Stasis ward packing: recipe results take freshness from
  ingredients unless `always_fresh` is set, and no event fires when an
  assembler finishes a craft. Resolution: a warded item prototype per item
  with a very long `spoil_ticks`, packed and unpacked by plain recipes, no
  script.
- **6.** 🟢 Feral check scaling: search around each player instead of
  checking every unit against every player. Spread live effects round-robin.
- **7.** 🟢 A spoiling nuke larva gives no warning. State the force of a
  spoiled monster. Idea: an "agitated larva" stage with an alert.
- **8.** 🟢 Terminology: eggs vs larvae (L238, L283, L333). Slot caps missing
  for spitters, worms, hybrids. Converted units have no payload, so the
  unstable chance is zero. Hybrid larva costs 10 hybrid eggs (20 embryos).
