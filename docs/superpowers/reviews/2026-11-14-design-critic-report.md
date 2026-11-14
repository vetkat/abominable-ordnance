# Design document: Stage 7 critic report

## Design critic

Verdict: does not pass yet. 2 Blockers, 8 Majors, 4 Nits.

## Design critic: 🔴 Blocker

- **1.** No Alternatives Considered section. Core choices without
  alternatives: script-tracked vanilla units vs custom unit prototypes
  (L314-316), forces model (L369-372), script-driven stasis ward (L385-388),
  new launcher vs gun-turret ammo (L420).
- **2.** Stasis ward mechanism rests on a false assumption (L241-244,
  L385-388. V1 at L323). No per-craft event for assembling machines. The
  script would poll output inventories. Tagged wards do not stack.

## Design critic: 🟡 Major

- **3.** No technical risks: 30-tick feral check is O(units × players)
  (L373). `storage` leaks for units removed without `on_entity_died`.
  Multiplayer desync and migrations. The 64-force limit under PvP.
- **4.** Payload set contradicts itself (L124 vs L126-135, L351). 13 species
  × 8 = 104 items at one slot, thousands with three.
- **5.** Slot caps conflict (L143-145, L161, L173).
- **6.** Abomination delivery contradicts itself (L176 vs L250).
- **7.** Research dependencies inverted: Pheromones before Facehuggers, V3
  before V2. "four branches converge" vs side paths.
- **8.** Vanilla feature ceiling undefined: no crossbreeding, facehuggers or
  Abomination without Space Age. Biter × spitter has no hybrid (7 of 10
  pairs).
- **9.** V1 decision still open: vanilla launcher (L319 vs L420).
- **10.** Status drift: every V1 box unchecked though slices 1 and 2 shipped
  (L311-326).

## Design critic: 🟢 Nit

- **11.** Eggs vs larvae terms (L238, L283, L333).
- **12.** Converted units have no payload but "go feral like any loaded
  monster". One shared feral force allies rival PvP ferals.
- **13.** Egg source (own egg or Space Age `biter-egg`) and hybrid
  incubation cost unclear.
- **14.** Goals/Non-Goals missing. Open questions answered twice.

## Structural reviewer

## Structural reviewer: 🔴 Blocker

- **1.** **No Alternatives Considered section (whole document).** The
  standard fails a spec that proposes one path without rejected
  alternatives. Trade-offs sit in Technical notes: item-per-combination vs
  `item-with-tags` (350-356), `script` vs `create-entity` (365),
  linked-chain demolisher vs plain unit (377-379). They need their own H2
  with each rejected option and its reason.

## Structural reviewer: 🟡 Major

- **2.** **No engineering Risks & Mitigations (208-234, 345-388).** "Feral
  behaviour and risks" covers gameplay hazards only. Line 348 names the hard
  parts with no mitigation. Nothing covers `on_nth_tick` cost and the
  30-tick feral scan as tracked units grow, `storage` growth, multiplayer
  sync, or save/migration risk.
- **3.** **No Goals & Non-Goals section.** Non-goals are buried (202, 306).
- **4.** **Heading does not match content (304).** "Version 1 feature list"
  holds Version 2 and 3.
- **5.** **Research tree contradicts the version plan (288-292 vs 335,
  341).** Facehuggers and the pacifier depend on Pheromones, but they are V2
  and Pheromone dampener is V3.
- **6.** **Research intro duplicated and contradictory (256-261, 301).** Two
  branches meet / four branches converge / Delivery and Control do not gate
  it.
- **7.** **Open questions split in two (392-420).** Put each answer under
  its question.
- **8.** **Cross-references point to a missing heading (144, 177).** "(see
  Risks)" has no heading. Use anchor links.

## Structural reviewer: 🟢 Nit

- **9.** Diagram node labels inconsistent (266-294).
- **10.** Diagram captions placed differently (55, 299).
- **11.** Prose claims a left/right layout Mermaid does not guarantee
  (86-87). Captive spawners missing from the lifecycle diagram.
- **12.** Names drift: "Loaded eggs" (333), "Artillery eggs" (283),
  "launchers turn eggs into ammunition" (238) against "only larvae are
  loaded" (39, 123). "Warded eggs" (244). "Jazz pods" vs "Interbreeding
  pods" (40, 164, 376).
- **13.** Heading narrower than its table (49).
- **14.** Stasis ward described three times (42-43, 98-99, 241-244).
- **15.** Slot-cap rule incomplete (145): no caps for spitters, worms,
  hybrids. Lavapod "+1 slot" vs max 3.
- **16.** Odd line wrap (173-174).
- **17.** Checklist item is implementation detail (314-316).
- **18.** "Concept" (5) states no player problem.

## Style reviewer

No blockers. No dashes as punctuation, no American spellings in the body.

## Style reviewer: 🟡 Major

- **1.** Semicolons in table cells (91, 92, 93, 96, 108, 109, 110, 156, 158,
  160, 161). House style bans them.
- **2.** Crossbreeding benefits "still need tuning" and "(proposal)" (152,
  154), but Open questions marks them settled (394, 404).
- **3.** "No new turret" then "the mod adds a simple launcher" (245-248).
  Line 319 says vanilla gets a launcher, line 420 still asks if it is a new
  building.
- **4.** The Abomination "fires only from artillery or a dedicated launcher"
  (176), but artillery shells take "every species except the Abomination"
  (249-250). The Abomination is not one of the five species (103).
- **5.** "Breeding and Loading meet at the Abomination" vs "Four research
  branches converge" (256-262) vs Delivery and Control do not gate it
  (301-302).
- **6.** "The launchers turn eggs into ammunition" (238-239) is wrong: the
  incubator and chamber make ammo.
- **7.** "Artillery shells for loaded eggs" (333) and the tech "Artillery
  eggs" (283): eggs are never loaded.
- **8.** "Converted units are temporary. They live until they die" (193-194)
  says nothing. "like any other loaded monster" implies they are loaded.
- **9.** Stasis ward scope differs per mention (98, 241, 244). "happens in
  an assembler" (243-244) vs a script must do it (385).
- **10.** Turning back by "healing or eating a fish" (199) vs "timeout,
  death or cure" (382).

## Style reviewer: 🟢 Nit

- **11.** "(see Risks)" does not match the heading (144, 177).
- **12.** "(maybe into biomass)" hedge (92).
- **13.** Filler: "just dies" (63, 227), "a real risk" (226).
- **14.** Vague amounts: "within a few tiles" (165), "a few seconds" (188),
  "a few minutes" (213), "every 30 ticks or so" (373), "most of the mod"
  (347).
- **15.** "Every step is a machine" is false for Capture, Fire, Detonate and
  repeats a pillar (30-31).
- **16.** "5 × 8 = 40" counts grenade and cluster grenade as one (352). The
  table lists nine payloads.
- **17.** The risk ladder leaves out unloaded larva, hybrid egg and
  facehugger (52-53).
- **18.** "Branch off to the left" depends on Mermaid layout (87).
- **19.** Slot caps leave out spitters, worms and hybrids. Lavapod "+1 slot"
  has no ceiling (145, 161).
- **20.** Pheromones unlocks the V2 pacifier but is V3 (288 vs 335, 341).
- **21.** Settled questions stated twice (392-414).
- **22.** Repetition: "only larvae can be loaded" (38-39, 123). Stasis pause
  (42-43, 98-99, 241-243).
- **23.** "Nov 11, 2026" is US date order (3).
- **24.** Diagram labels: "arty" (71), "sci." vs "science", "Expand
  Orifices" vs "Expand Orifices I".
- **25.** "near a demolisher territory" (112).
- **26.** "the adopt recipe" undefined (108).
- **27.** "where recipes may name the base game's barrels" unclear (351).
- **28.** "turns spoilage on itself" awkward (360).
