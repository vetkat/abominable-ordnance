# Slice 2 build ledger

The progress ledger of the slice 2 build (plan
`docs/superpowers/plans/2026-11-14-ordnance.md`), kept at the
maintainer's request. It is a record and is not edited.

```text
# SDD ledger — plan: docs/superpowers/plans/2026-11-14-ordnance.md
Task 1: complete (commits 4d462ba..b349150, tests: make fast -> 51 busted pass)
Task 2: complete (commits b349150..801fb37, tests: make fast -> 56 busted pass)
Task 3: Ruling: the plan expected the larva hatch test to fail before Task 3; Task 2's Species.by_effect_id already finds larva IDs, so the handler hatches larvae with no new shell code. Task 3 extracts spawn() as a refactor and adds the tests. Cost if wrong: none.
Task 3: complete (commits 801fb37..6a81a91, tests: make check -> busted 56 pass, in-game 15/16 pass both modes)
PR1 /simplify (2 reviewers): Ruling: larvae reuse the egg's hatch effect ID (no larva_effect_id) — the effect is the same, only items_per_trigger differs — cost if wrong: re-add one field. The spec's "larva effect IDs" sentence and the plan's Task 2 interface are now stale; fix the spec wording in PR 3's docs step.
PR1 /simplify: Ruling: technology(), placeable() and names() move to Common; Ordnance.prototypes returns (prototypes, husbandry recipe names); Lifecycle takes opts.pod like opts.incubator; spawn() takes a unit list as the plan says; Helpers.spill replaces 3 copies; shared spec stubs. Cost if wrong: none (refactor, tests green).
PR1 /simplify: skipped — memoise Hatching.available per species (hatches are rare, not a hot path); duplicated tint test in common_spec and lifecycle_spec (one is unit-level, one checks the pod).
Task 4: complete (commits 48e744c..cce359e, tests: make fast -> 59 busted pass)
Task 5: complete (commits cce359e..bdf4295, tests: make check -> busted 63, in-game 16/17 both modes; the in-game chamber test passed at first run because the unit tests gave the RED)
PR2 /simplify (2 reviewers): Ruling: loaded effect IDs are ao-hatch-<species>-<payload> (they name what hatches); recipes are ao-load-<species>-<payload> from Payloads.load_recipe; decode uses a table built once. Cost if wrong: renames only.
PR2 /simplify: Ruling: text_check checks each locale entry on its own (fix in tools/text_check.py with tests) instead of a whole-file allow entry. Cost if wrong: none.
PR2 /simplify: Ruling: Common.machine_kit builds item, recipe and machine for pod, incubator and chamber; spoiling() and fresh_recipe() helpers; Helpers.research(done, tech). Cost if wrong: none.
PR2 /simplify: skipped — localised names built from parts for loaded larvae (locale_spec already fails on a missing name); one dispatch table for the trigger handler (reviewer said no work now).
Task 6: complete (commits db2a476..3be90cf, tests: make fast -> 68 busted pass)
Task 7: Ruling: no remote test interface — factorio-test runs in the mod's Lua state, so tests read storage directly; the force setup lives in shell/tamed.lua so a test can call it twice. shell/ added to the packager and luacheck (build commit with a failing-first packager test). Cost if wrong: none.
Task 7: Ruling: core/forces.lua holds the peace rule (not enemy, neutral or ao-tamed). Cost if wrong: a mod's second enemy faction gets cease-fire with ao-tamed.
Task 7: Ruling: the spawner test disables the spawner (disabled_by_script); a working spawner's defenders killed the lone medium biter in under 5 s. Cost if wrong: none.
Task 7: complete (commits 3be90cf..HEAD, tests: busted 70, in-game 21/22 both modes)
Task 8: complete (commits ee6ba90..807d648, tests: in-game 26/27 both modes; 4 RED first)
Task 9: complete (commits 807d648..df34256, tests: in-game 27/28 both modes, RED first)
PR3 /simplify (4 reviewers): Ruling: death effects are plain data with one builder (Payloads.on_death); Forces.cease_fire (true/false/nil) and Forces.earns_loot (Q8) move the rules into the core; Tamed.relate is the one path for every force; storage setup moves to control.lua setup(); the trail name is stored in the entry at spawn; shell/ gets a paragraph in docs/architecture.md; Helpers.find_units replaces the copied area search. Cost if wrong: none (tests green).
PR3 /simplify: skipped — store one payload name instead of a list (the spec keeps a list for later slots); fail loudly on an unknown payload (functional-core wants a defined result); drop the explicit enemy hostility (spec states it); one table-driven death test; one hatch-plan lookup for the trigger handler (no new hatch kinds yet); packager exclude list instead of an allow list.
Final review (opus): 0 Critical, 3 Important, 4 Minor. Ready with fixes.
Final: fixed on_object_destroyed removed entries for other objects (a /simplify regression: the entity-type check was removed) — "another object's destruction leaves the loaded entries alone" RED→GREEN, suite in-game 32/32 both modes
Final: fixed acid trail crashed in on_nth_tick when its entity is missing — "an acid trail whose entity is missing does nothing" RED (non-recoverable error)→GREEN
Final: fixed old saves kept new Monster husbandry unlocks locked — setup moved to shell/setup.lua, on_configuration_changed calls reset_technology_effects on every force — "a configuration change unlocks new recipes of a finished research" RED→GREEN
Final: minor fixed — content test that every payload effect entity exists; stale species comment; CHANGELOG says acid burns units, not nests.
Final: minor (deferred): every native unit death now calls Lua (one table lookup); no engine filter by force exists.
```
