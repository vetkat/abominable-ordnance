# Design document: Stage 6 comprehension report

## What this proposes

A Factorio 2.1 mod, with Space Age optional, where the player captures
native monster eggs, breeds them in pods, incubates ten eggs into a larva,
loads the larva with 1 to 3 ordnance items and fires it from rocket turrets
or artillery. The larva becomes a live monster where it lands. While it
lives it applies a live effect, and when it dies it triggers its payload.
The side systems are crossbreeding (embryos go into jazz pods and make
hybrid
eggs, ending in a five-species Abomination), facehuggers that convert
enemies or players, stasis wards that pause spoiling, and a feral mechanic
that turns loaded monsters hostile to everyone. V1 covers biters and
spitters on Nauvis with three payloads, v2 adds multi-slot loading, worms,
pentapods and hybrids, and v3 adds hatchlings, the Abomination and PvP.

## How the existing system works, per this document

Factorio has enemy families: biters, spitters and worms on Nauvis, pentapods
on Gleba and demolishers on Vulcanus. The 2.1 spoilage system (spoil_ticks
plus spoil triggers that can run script effects) is available without Space
Age if info.json sets `spoiling_required`. Space Age already provides
pentapod eggs, a captive biter spawner and the rocket turret. Vanilla has no
rocket turret. Demolishers are chains of linked entities, items with tags
don't stack, and recipe results support a `probability`. The mod tracks
loaded units in `storage`, uses `on_nth_tick` and `on_entity_died`, and uses
separate allied and feral forces.

## Findings

- 🟡 Abomination and artillery contradict each other (L175-176 vs L250).
- 🟡 Research branches gating the Abomination contradict (L256, L260 vs
  L301-302).
- 🟡 Pacifier facehugger research and version conflict (L204, L288-289, L335,
  L341).
- 🟡 Payload set undefined: "any ammo or capsule" vs the fixed table. Acid
  barrels are neither. The grenade row is two items (L123-135, L352).
- 🟡 Item count ignores hybrids and the Abomination (L350-356).
- 🟡 Slot rules incomplete: no caps for spitters, worms, hybrids. Lavapod +1
  against a max of 3 breaks "one to three" (L38, L145, L161, L173).
- 🟡 Hybrid egg and Abomination inputs unclear: ten hybrid eggs per larva?
  Jazz pod takes two embryos, then three hybrid eggs. Does the Abomination
  egg go through incubator and chamber? (L40-41, L93, L168-170)
- 🟡 "Feed" never defined (L35, L59, L91, L230).
- 🟡 The danger pillar says loaded monsters go feral near you, but in the
  factory they are items. Do loaded larvae on belts have a feral radius?
  (L19-21)
- 🟡 Monster behaviour after landing is vague: target choice, how worms
  become turrets (L46-47, L109-110, L158).
- 🟡 Facehugger reversal: "healing or eating a fish" vs "timeout, death or
  cure". How a player gets the bonus version in PvE (L199-201, L381-382).
- 🟡 Stasis ward packing in an assembler vs script packing (L243-244,
  L385-388).
- 🟡 Vanilla limits unstated: crossbreeding and facehuggers need Agricultural
  science (L118, L268-269, L289).
- 🟢 "Hatch ratio of 10" undefined (L413).
- 🟢 Eggs and larvae mixed up (L238-239, L283, L333).
- 🟢 Converted units: "temporary" but "live until they die" (L193-194).
- 🟢 Vanilla launcher both decided and open (L246-248, L318-319, L420).
- 🟢 Stasis ward scope differs (L98, L241).
- 🟢 Undefined terms: adopt recipe, capture net, worm pit, core module, base
  game's barrels, catalyst.
- 🟢 Captive spawners not marked Space Age only. Hatchling capture method
  missing (L91, L108, L112).
- 🟢 Diagram layout claim (L87).
- 🟢 Open question answers not linked to their items (L392-402).
